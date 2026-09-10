import 'dart:async';
import 'package:wowcare/app/di/private_mode_toggle_cubit_factory.dart';

import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/domain/features/communication/policies/role_aware_ownership.dart';
import 'package:wowcare/domain/features/communication/policies/message_delete_permission.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/parent_participant_chips.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/html_aware_text_controller.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/composer_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/composer_state.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_state.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_scroll_behavior.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/loading_older_indicator.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/reaction_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/new_messages_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/thread_message_tile.dart';
import 'package:wowcare/presentation/features/communication/view_model/private_mode_toggle_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/private_mode_toggle_state.dart';
import 'package:wowcare/domain/features/communication/policies/room_chat_privacy_helper.dart';
import 'package:wowcare/data/features/communication/mappers/participant_mapper.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';

class ParentMessagingThread extends StatefulWidget {
  const ParentMessagingThread({
    super.key,
    required this.parentInfo,
    this.showOwnScaffold = true,
    this.isGuardian = true,
    this.conversationType = ConversationType.roomChat,
    this.onRefreshConversationList,
  });
  final ParentThreadInfo parentInfo;

  /// When false the widget renders only its body content (no [GlobalScaffold]).
  /// Use this when embedding the thread inside another scaffold.
  final bool showOwnScaffold;

  /// Called alongside the thread's own pull-to-refresh, for embedders
  /// (e.g. [ParentDirectMessagingScreen]) that keep a separate conversation
  /// list cubit above this widget — so the list (and its cache) also
  /// refreshes on the same pull gesture, instead of only this thread's
  /// messages. Left null for standalone usage (this widget owns the only
  /// RefreshIndicator in the tree), where there's no outer list to refresh.
  final Future<void> Function()? onRefreshConversationList;

  /// Whether to show guardian-specific UI (hides back arrow, shows private toggle).
  final bool isGuardian;

  /// Room Chat vs Admin Chat — this screen renders both (a guardian's own
  /// view can be either, via [ParentDirectMessagingScreen]; a staff/admin
  /// viewer only ever reaches this screen for Room Chat, via
  /// staff_messaging_tab.dart) but previously showed no visual distinction
  /// at all between the two, making them look identical in the UI.
  final ConversationType conversationType;

  @override
  State<ParentMessagingThread> createState() => _ParentMessagingThreadState();
}

class _ParentMessagingThreadState extends State<ParentMessagingThread>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final HtmlAwareTextController _controller = HtmlAwareTextController();

  final AutoScrollController _groupController = AutoScrollController();
  final AutoScrollController _parent1Controller = AutoScrollController();
  final AutoScrollController _parent2Controller = AutoScrollController();
  // These lists are built with `reverse: true` (index 0 = newest, resting at
  // pixels == 0) — must tell ChatScrollBehavior, or "scroll to bottom" would
  // land on the oldest message instead.
  late final ChatScrollBehavior _groupScrollBehavior = ChatScrollBehavior(
    _groupController,
    reverse: true,
  );
  late final ChatScrollBehavior _parent1ScrollBehavior = ChatScrollBehavior(
    _parent1Controller,
    reverse: true,
  );
  late final ChatScrollBehavior _parent2ScrollBehavior = ChatScrollBehavior(
    _parent2Controller,
    reverse: true,
  );
  double _lastKeyboardInset = 0;
  // Tracks the latest message's id rather than a raw count — a raw count
  // can desync across edits/deletes/optimistic-rollbacks (e.g. a reaction
  // mutation that fails and reverts touches `threads` without changing the
  // message count, but a delete does change it without anything being
  // "new" to scroll to), silently breaking the "did a new message arrive"
  // check this drives. Identity comparison is correct regardless of why
  // the list changed.
  String? _lastMessageId;
  bool _initialLoadInFlight = true;
  bool _ownSendPending = false;

  /// True once the thread has successfully loaded at least once — see the
  /// matching field in StaffMessagingThread for why this is needed: a
  /// mid-thread action failure's `CommunicationError` is immediately
  /// superseded by a follow-up `CommunicationLoaded` emit in the same
  /// cubit call, so it never survives to a painted frame and `build()`
  /// alone silently skips it. Only the `listener` callback (synchronous
  /// per-emission, not frame-batched) reliably catches it.
  bool _hasLoadedThreadOnce = false;
  TabController? _tabController;

  /// False until the very first scroll-to-bottom has actually landed on the
  /// true latest message. The real message list stays hidden behind the
  /// shimmer until this flips, so opening a thread shows the conversation
  /// already sitting at the latest message instead of visibly scrolling
  /// down to it from the top.
  // Screen view-flags (Mandate 2): scroll-position gate, delete permission,
  // refreshed participants, plus an identity-load revision (the set-once
  // _currentUserCode/_currentSender stay plain fields; this notifier triggers
  // the rebuild when they load). ValueNotifiers so the body rebuilds off one
  // merged listenable rather than setState.
  final ValueNotifier<bool> _isPositionedAtBottom = ValueNotifier<bool>(false);
  final ValueNotifier<int> _identityRev = ValueNotifier<int>(0);

  late final ReactionsController _reactionsController;

  /// Composer state — reply target / edit target / staged attachments (Mandate
  /// 2, Bucket A). The `_controller` stays a plain field: it is a Flutter
  /// controller, not screen state.
  final ComposerCubit<Message> _composer = ComposerCubit<Message>();
  String? _currentUserCode;
  String? _currentSender;
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoadingOlder = false;
  static const double _loadOlderScrollThreshold = 200.0;

  /// `communication-settings`-driven Delete visibility — see
  /// [MessageBubble.isAdminCanDeleteAny] / [MessageBubble.deleteTimeLimitMinutes].
  /// This screen only ever shows the GUARDIAN's own view of the thread, so
  /// the admin-delete-any override never applies here — only the sender's
  /// own delete window matters, fetched once on open.
  final ValueNotifier<MessageDeletePermission> _deletePermission =
      ValueNotifier<MessageDeletePermission>(MessageDeletePermission.none);

  Future<void> _loadDeletePermission() async {
    // Read identity through the ambient cubit (Mandate 5: no StorageService in
    // views) — same underlying storage read.
    final schoolCode =
        (await context.read<CommunicationCubit>().readActiveSchoolCode() ?? '');
    final permission = await context.read<CommunicationCubit>().resolveDeletePermission(
      schoolCode: schoolCode,
      isAdminViewer: false,
    );
    if (!mounted) return;
    _deletePermission.value = permission;
  }

  /// Overrides `widget.parentInfo.participants` once a fresh fetch
  /// completes — the participant list passed in via `parentInfo` is
  /// whatever was last loaded into the inbox (potentially stale: classroom
  /// reassignments, new guardians/admins, or removals that happened after
  /// that list was fetched). Null until the refresh below finishes, at
  /// which point [_participants] prefers this over the widget input.
  final ValueNotifier<List<ConversationParticipant>?> _refreshedParticipants =
      ValueNotifier<List<ConversationParticipant>?>(null);

  /// Created once [_currentUserCode] resolves, scoped to this thread's
  /// lifetime — manages this guardian's own Private Mode toggle (PATCH to
  /// the same backend resource the v2 Admin Chat toggle already uses).
  PrivateModeToggleCubit? _privateModeToggleCubit;

  bool get _privateModeActive =>
      widget.parentInfo.privateModeActive;

  String? get _privateModeActivatedBy =>
      widget.parentInfo.privateModeActivatedBy;

  Map<String, String> get _guardianMap =>
      widget.parentInfo.guardianMap;

  List<MapEntry<String, String>> get _guardianEntries =>
      _guardianMap.entries.toList();

  String get parent1Name =>
      _guardianEntries.isNotEmpty ? _guardianEntries[0].value : 'Guardian 1';

  String get parent2Name =>
      _guardianEntries.length > 1 ? _guardianEntries[1].value : 'Guardian 2';

  bool get _privateModeEnabled => !widget.isGuardian && _privateModeActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reactionsController = ReactionsController(currentUserId: '');
    _tabController = TabController(length: _tabCount, vsync: this);
    unawaited(_loadDeletePermission());

    _tabController?.addListener(() {
      // Mandate 2 (Bucket C): TabController tick — the active tab drives which
      // filtered thread/composer shows; a controller-driven rebuild, so
      // setState is correct.
      if (mounted) setState(() {});
    });

    // All three lists render the same underlying thread, just filtered
    // differently per tab — one scroll-near-top check per controller is
    // enough, since only the currently-visible one ever receives user-driven
    // scroll events.
    _groupController.addListener(_onScroll);
    _parent1Controller.addListener(_onScroll);
    _parent2Controller.addListener(_onScroll);

    // Deliberately NOT subscribing to the ambient ConversationListCubit for
    // private-mode sync anymore. That cubit's stream mixes in Isar-cached
    // data (emitted immediately, before any network call) and Firestore
    // deltas of uncertain freshness for this specific field — a stale
    // cached emission arriving after our own correct direct fetch below
    // would silently overwrite it, which is exactly the "wrong on first
    // open, only correct after a manual refresh" symptom: refresh forces a
    // fresh network write that happens to overwrite the stale cache, so it
    // looks fixed until the next cold open reads stale cache again first.
    // [_refreshPrivateModeFromApi] (called on mount and on every new
    // incoming message) is now the ONLY source that ever touches
    // [_privateModeToggleCubit]'s isEnabled/activatedBy, besides the user's
    // own [PrivateModeToggleCubit.toggle] action.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthLoaded) {
        _currentSender = authState.loginResponse.displayName.isNotEmpty
            ? authState.loginResponse.displayName
            : authState.loginResponse.userCode;
        _identityRev.value++;
      }
      // senderUserCode from the backend is the USR-/STF-... userCode, not the
      // JWT sub UUID. Always compare against userCode. Read through the ambient
      // cubit (Mandate 5) — same underlying storage read.
      final storedUserCode =
          (await context.read<CommunicationCubit>().readCurrentUserCode() ?? '')
              .trim();
      final authUserCode = authState is AuthLoaded
          ? authState.loginResponse.userCode
          : null;
      final currentUserId = (authUserCode?.isNotEmpty ?? false)
          ? authUserCode
          : (storedUserCode.isNotEmpty ? storedUserCode : null);
      if (!mounted) return;
      _currentUserCode = currentUserId;
      if (widget.isGuardian) {
        // No local/cached seed for isEnabled or activatedBy — starts
        // unset (off, unknown activator) and is populated exclusively
        // from the API fetch right below, never from
        // `widget.parentInfo`/participant data computed elsewhere. That
        // local data is exactly what was causing the toggle to show a
        // stale value until some later realtime event happened to
        // correct it.
        _privateModeToggleCubit = buildPrivateModeToggleCubit(
          conversationCode: widget.parentInfo.code,
          viewerRole: () => widget.isGuardian
              ? RoomChatViewerRole.guardian
              : RoomChatViewerRole.staffOrAdmin,
          currentUserCode: () => _currentUserCode ?? '',
        );
        // Fetch this conversation directly via REST — the same
        // GET .../conversations/type/{TYPE} shape, just for one code —
        // which reliably carries privateModeActive/privateModeActivatedBy,
        // and sync the toggle from that. This is the ONLY source that
        // feeds the toggle now (see the comment above [initState]'s old
        // ConversationListCubit subscription for why that was removed).
        unawaited(_refreshPrivateModeFromApi());
      }
      _identityRev.value++;
      final convCode = widget.parentInfo.code;
      final communicationCubit = context.read<CommunicationCubit>();
      // Fire an immediate, unawaited mark-read on open — matches Room Chat's
      // sibling screens (staff_messaging_thread.dart,
      // conversation_thread_screen.dart), which call this unconditionally
      // as soon as the thread opens, before anything else. Previously this
      // was sequenced AFTER `await loadMessages(...)` below: any failure,
      // stall, or thrown exception in that await (network hiccup, a bad
      // response for this specific conversation, …) silently aborted this
      // whole callback before ever reaching the mark-read call, so the
      // read receipt was never recorded — the conversation looked read in
      // the UI but stayed unread server-side/in Firestore forever. Firing
      // it first, independent of loadMessages, means the read receipt no
      // longer depends on that call succeeding — and, as before, it's
      // deliberately NOT gated on `mounted` either: a quick open-then-back
      // tap must still record the read receipt even with no UI left to
      // update.
      unawaited(communicationCubit.markConversationRead(convCode));
      await communicationCubit.loadMessages(
        convCode,
        currentUserId: currentUserId,
      );
      if (!mounted) return;
      // Realtime listener starts only after the API/Isar history has
      // loaded — Firestore only ever applies deltas on top of it.
      communicationCubit.startWatchingThread(
        convCode,
        organizationCode: widget.parentInfo.organizationCode,
        schoolCode: widget.parentInfo.schoolCode,
      );
      unawaited(_refreshParticipants(convCode));
      final initialMessages = _activeMessages;
      _lastMessageId = initialMessages.isNotEmpty
          ? initialMessages.last.id
          : null;
      _initialLoadInFlight = false;
      _getActiveScrollBehavior().scrollToBottom(
        animate: false,
        onSettled: () {
          if (!mounted) return;
          _isPositionedAtBottom.value = true;
        },
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reactionsController.dispose();
    _groupController.removeListener(_onScroll);
    _parent1Controller.removeListener(_onScroll);
    _parent2Controller.removeListener(_onScroll);
    _groupScrollBehavior.dispose();
    _parent1ScrollBehavior.dispose();
    _parent2ScrollBehavior.dispose();
    _controller.dispose();
    _groupController.dispose();
    _parent1Controller.dispose();
    _parent2Controller.dispose();
    _tabController?.dispose();
    _inputFocusNode.dispose();
    _privateModeToggleCubit?.close();
    unawaited(_composer.close());
    _isPositionedAtBottom.dispose();
    _identityRev.dispose();
    _deletePermission.dispose();
    _refreshedParticipants.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = _getActiveScrollController();
    if (!controller.hasClients) return;
    // Lists here are `reverse: true` (index 0 = newest, resting at
    // pixels == 0) — the oldest message is at the *far* end of the scroll
    // range, so "near the top of history" means near `maxScrollExtent`,
    // the opposite of the non-reversed case.
    final position = controller.position;
    if (position.maxScrollExtent - position.pixels >
        _loadOlderScrollThreshold) {
      return;
    }
    _loadOlderMessages();
  }

  /// Fetches the next older page. Unlike a non-reversed list, no scroll-
  /// position-preservation step is needed: because each `itemBuilder` maps
  /// `index -> _messages[length - 1 - index]`, prepending older messages to
  /// the front of `_messages` only adds new, higher indices at the far end
  /// — every currently-visible item keeps the exact index (and therefore
  /// position) it already had.
  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    final cubit = context.read<CommunicationCubit>();
    final state = cubit.state;
    if (state is! CommunicationLoaded) return;
    if (state.isLoadingOlderMessages || !state.hasMoreOlderMessages) return;

    _isLoadingOlder = true;
    final threadId = widget.parentInfo.code;
    await cubit.loadOlderMessages(threadId, currentUserId: _currentUserCode);
    _isLoadingOlder = false;
  }

  /// WhatsApp/Telegram-style keyboard handling: when the keyboard opens,
  /// scroll to the latest message — but only if the user was already near
  /// the bottom, never while they're reading older history.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final keyboardOpened = bottomInset > _lastKeyboardInset + 20;
      _lastKeyboardInset = bottomInset;
      if (keyboardOpened) {
        _getActiveScrollBehavior().onKeyboardOpened();
      }
    });
  }

  /// Reacts to the latest message changing identity from any source (API
  /// refresh, realtime delta, or our own optimistic send): scrolls to
  /// bottom when the user is already there, otherwise surfaces the "new
  /// messages" indicator rather than forcing a jump while they're reading
  /// older history. Skipped while the initial load is still in flight (that
  /// case is handled explicitly).
  void _onMessagesChanged(List<Message> messages) {
    if (_initialLoadInFlight) {
      _lastMessageId = messages.isNotEmpty ? messages.last.id : null;
      return;
    }
    final wasOwnSend = _ownSendPending;
    _ownSendPending = false;
    final latestId = messages.isNotEmpty ? messages.last.id : null;
    final hasNewLatest = latestId != null && latestId != _lastMessageId;
    _lastMessageId = latestId;
    if (!hasNewLatest) return;
    // New messages arrived while the conversation is open — clear the unread count.
    unawaited(
      context.read<CommunicationCubit>().markConversationRead(
        widget.parentInfo.code,
      ),
    );
    // Someone else's activity just changed this conversation — re-check the
    // true private-mode state directly via REST rather than waiting on
    // whichever (possibly absent, possibly stale) realtime source gets
    // there first. Skipped for our own send: we already know what we just
    // did.
    if (!wasOwnSend && widget.isGuardian) {
      unawaited(_refreshPrivateModeFromApi());
    }
    // Sending always scrolls to bottom, regardless of scroll position.
    // Other growth (realtime/API) only scrolls when already near bottom.
    if (wasOwnSend) {
      _getActiveScrollBehavior().scrollToBottom();
    } else {
      _getActiveScrollBehavior().onIncomingMessage();
    }
  }

  /// Fetches this conversation directly (`GET .../conversations/{code}`,
  /// same underlying data as the type-scoped list endpoint —
  /// `privateModeActive`/`privateModeActivatedBy` are reliable there) and
  /// syncs the toggle from it. This is the ONLY source that ever updates
  /// [_privateModeToggleCubit]'s isEnabled/activatedBy besides the user's
  /// own toggle action — an earlier version also listened to the ambient
  /// `ConversationListCubit` for "realtime" updates, but that stream's
  /// first emission is straight from Isar cache (no network round trip),
  /// so a stale cached value could — and did — arrive after this call and
  /// silently overwrite the correct one, which looked like "wrong on first
  /// open, fixed only by a manual refresh" (refresh happens to force a
  /// fresh write that overwrites the stale cache).
  Future<void> _refreshPrivateModeFromApi() async {
    if (!widget.isGuardian || _privateModeToggleCubit == null) return;
    final code = widget.parentInfo.code;
    if (code.isEmpty) return;
    final result = await context.read<CommunicationCubit>()
        .getConversationEntity(code);
    if (!mounted) return;
    result.fold((_) {}, (conversation) {
      _privateModeToggleCubit?.syncFromRemote(
        active: conversation.privateModeActive,
        activatedBy: conversation.privateModeActivatedBy,
      );
    });
  }

  int get _tabCount {
    if (widget.isGuardian) return 1;
    final guardianCount = _guardianEntries.length.clamp(0, 2);
    return _privateModeActive ? 1 + guardianCount : 1;
  }

  AutoScrollController _getActiveScrollController() {
    if (widget.isGuardian || !_privateModeActive) return _groupController;
    final index = _tabController?.index ?? 0;
    if (index == 1) return _parent1Controller;
    if (index == 2) return _parent2Controller;
    return _groupController;
  }

  bool _isParentInPrivateMode(String name) {
    for (final entry in _guardianEntries) {
      if (entry.value == name) {
        return _privateModeActivatedBy == entry.key;
      }
    }
    return false;
  }

  List<Message> _messagesForGuardianUserCode(
    List<Message> messages,
    String guardianUserCode,
  ) {
    // A guardian's private tab shows ONLY that guardian's private messages.
    // Non-private (group) messages live in the dedicated "Group Chat" tab, so
    // every message appears in exactly one staff tab.
    return messages
        .where(
          (m) => m.isPrivate && m.privateParentUserCode == guardianUserCode,
        )
        .toList();
  }

  List<Message> _messagesForParentTab(
    List<Message> messages,
    String guardianUserCode,
  ) {
    return _messagesForGuardianUserCode(messages, guardianUserCode);
  }

  ChatScrollBehavior _getActiveScrollBehavior() {
    if (widget.isGuardian || !_privateModeActive) return _groupScrollBehavior;
    final index = _tabController?.index ?? 0;
    if (index == 1) return _parent1ScrollBehavior;
    if (index == 2) return _parent2ScrollBehavior;
    return _groupScrollBehavior;
  }

  List<Message> get _activeMessages {
    final state = context.read<CommunicationCubit>().state;
    if (state is CommunicationLoaded) {
      final threadId = widget.parentInfo.code;
      final messages =
          state.threads[threadId]
              ?.map(
                (m) => withRoleAwareOwnership(
                  m,
                  viewingAsGuardian: widget.isGuardian,
                ),
              )
              .toList() ??
          [];
      if (widget.isGuardian) {
        return messages.where((m) {
          if (!m.isPrivate) return true;
          // Always show the guardian's own private messages (both confirmed
          // messages scoped to their user code and optimistic sends whose
          // isSentByMe is true before the server confirms the user code).
          if (m.isSentByMe) return true;
          return m.privateParentUserCode == _currentUserCode;
        }).toList();
      }
      return messages;
    }
    return [];
  }

  void _sendMessage() {
    // Defense in depth — the backend is the actual authority on whether a
    // Past Participant (classroom unassigned, guardian/admin/director
    // removed) can still send, but block it here too so removal is visible
    // immediately rather than waiting on a round-trip failure.
    if (!_amIActiveParticipant) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'You are no longer an active participant in this conversation.',
        isError: true,
      );
      return;
    }
    if (_currentUserInactive) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Your staff account is inactive. You can no longer send messages.',
        isError: true,
      );
      return;
    }
    final text = _controller.text.trim();
    final editingMessage = _composer.state.editingMessage;
    if (editingMessage != null) {
      if (text.isNotEmpty && text != editingMessage.text) {
        context.read<CommunicationCubit>().editMessage(
          widget.parentInfo.code,
          editingMessage.code,
          text,
        );
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Message updated successfully',
          isSuccess: true,
        );
      }
      _composer.cancelEdit();
      _controller.clear();
      return;
    }

    final hasText = text.isNotEmpty;
    final hasAttachments = _composer.state.hasAttachments;

    if (!hasText && !hasAttachments) return;

    // This guardian's own toggle — not `_privateModeEnabled` (which reflects
    // whether *any* guardian on this conversation is private, driving the
    // tab split). A private message is visible only to staff/admin + this
    // guardian (PRD section C), never other guardians.
    final myPrivateModeEnabled =
        widget.isGuardian &&
        (_privateModeToggleCubit?.state.isEnabled ?? false);

    List<String> receivers = [];
    receivers.addAll(
      widget.parentInfo.staffList,
    );

    if (!myPrivateModeEnabled) {
      receivers.addAll(
        widget.parentInfo.parents,
      );
    }

    final authState = context.read<AuthCubit>().state;
    final senderName = authState is AuthLoaded
        ? authState.loginResponse.displayName
        : _currentSender;

    final selectedGuardianUserCode =
        (!widget.isGuardian &&
            _privateModeActive &&
            (_tabController?.index ?? 0) > 0 &&
            (_tabController!.index - 1) < _guardianEntries.length)
        ? _guardianEntries[_tabController!.index - 1].key
        : null;
    final privateParentUserCode = widget.isGuardian
        ? (myPrivateModeEnabled ? _currentUserCode : null)
        : ((!widget.isGuardian &&
                  _privateModeActive &&
                  selectedGuardianUserCode != null)
              ? selectedGuardianUserCode
              : null);

    _ownSendPending = true;
    context.read<CommunicationCubit>().sendMessage(
      widget.parentInfo.code,
      text,
      attachments: List.from(_composer.state.pendingAttachments),
      // Preserved from the old `_quotedMessageId`, which held message.id.
      quotedMessageId: _composer.state.quotedMessage?.id,
      senderName: senderName,
      senderUserCode: _currentUserCode,
      // The role THIS screen instance is sending as — stamped onto the
      // optimistic bubble so it never briefly renders on the wrong side
      // for a dual-role account (see CommunicationCubit.sendMessage's own
      // doc). Only "parent or not" matters for alignment, so any
      // non-parent role string is fine for the staff/admin case.
      senderRole: widget.isGuardian ? 'GUARDIAN' : 'STAFF',
      receivers: receivers,
      isPrivate: privateParentUserCode != null,
      privateParentUserCode: privateParentUserCode,
    );

    _controller.clear();
    _composer.reset();
  }

  int? _getReversedIndex(String messageId) {
    final index = _activeMessages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    return _activeMessages.length - 1 - index;
  }

  void _scrollToMessage(String messageId) {
    final index = _getReversedIndex(messageId);
    if (index == null) {
      AppLogger.d("Message $messageId not found");
      return;
    }
    final scrollController = _getActiveScrollController();
    scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 600),
    );
  }

  /// Returns true when [current] is a continuation of [prev]:
  /// same sender and sent within 5 minutes (don't group across date separators).
  bool _isSameSender(Message? prev, Message current) {
    if (prev == null) return false;
    final prevCode = prev.senderUserCode ?? '';
    final currCode = current.senderUserCode ?? '';
    if (prevCode.isNotEmpty && currCode.isNotEmpty) {
      return prevCode == currCode &&
          current.time.difference(prev.time).inMinutes <= 5;
    }
    return prev.isSentByMe == current.isSentByMe &&
        current.time.difference(prev.time).inMinutes <= 5;
  }

  void _showEmojiPicker(BuildContext context, Message message) {
    // Capture cubit before entering the bottom sheet route so it's reachable
    // even though the sheet's BuildContext has no CommunicationCubit ancestor.
    final cubit = context.read<CommunicationCubit>();
    final convCode = widget.parentInfo.code;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparentColor,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetHeight =
            (MediaQuery.of(sheetContext).size.height * 0.55).clamp(
              240.0,
              400.0,
            ) +
            MediaQuery.of(sheetContext).padding.bottom;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(sheetContext); // close picker
              if (message.userHasReaction(
                _currentUserCode ?? '',
                emoji.emoji,
              )) {
                cubit.removeReaction(
                  convCode,
                  message.code,
                  emoji.emoji,
                  currentUserCode: _currentUserCode,
                );
              } else {
                cubit.addReaction(
                  convCode,
                  message.code,
                  emoji.emoji,
                  currentUserCode: _currentUserCode,
                );
              }
            },
            config: const Config(
              //height: 380,
              checkPlatformCompatibility: true,
              emojiSet: null,
              locale: Locale('en'),
              emojiTextStyle: null,
              customBackspaceIcon: null,
              customSearchIcon: null,
              viewOrderConfig: ViewOrderConfig(),
              emojiViewConfig: EmojiViewConfig(),
              skinToneConfig: SkinToneConfig(enabled: true),
              categoryViewConfig: CategoryViewConfig(
                recentTabBehavior: RecentTabBehavior.RECENT,
              ),
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
              searchViewConfig: SearchViewConfig(),
            ),
          ),
        );
      },
    );
  }

  /// Delete a message and acknowledge the real outcome: a success toast, or the
  /// server's reason (e.g. the delete window has passed) instead of a premature
  /// "deleted" message that would be wrong when the server rejects it.
  Future<void> _deleteMessageWithFeedback(String messageCode) async {
    final failure = await context.read<CommunicationCubit>().deleteMessage(
      widget.parentInfo.code,
      messageCode,
    );
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: failure == null
          ? 'Message deleted successfully'
          : (failure.message ?? 'Failed to delete message.'),
      isSuccess: failure == null,
      isError: failure != null,
    );
  }

  void _startEditing(Message message) {
    _composer.startEdit(message);
    _controller.text = MessageContentProcessor.stripHtmlTags(message.text);
    _inputFocusNode.requestFocus();
  }

  /// Pull-to-refresh entry point — re-runs the same API/Isar fetch used on
  /// initial load, for whichever tab (Group/Private) is currently visible,
  /// resyncs the private-mode toggle (this thread's toggle otherwise only
  /// refreshes on mount or on a new incoming message — a pull here is
  /// exactly the case where a web-side private-mode change wouldn't
  /// otherwise reach it), and (when embedded — see
  /// [ParentMessagingThread.onRefreshConversationList]) refreshes the outer
  /// conversation list too, so one pull gesture updates all three instead
  /// of just this thread's messages.
  Future<void> _refreshThread() async {
    final convCode = widget.parentInfo.code;
    await Future.wait([
      context.read<CommunicationCubit>().loadMessages(
        convCode,
        currentUserId: _currentUserCode,
      ),
      _refreshPrivateModeFromApi(),
      if (widget.onRefreshConversationList != null)
        widget.onRefreshConversationList!(),
    ]);
  }

  /// Renders one message pane (the message list + new-message / loading-older
  /// overlays) for a single tab. Extracted so the Group Chat tab and each
  /// per-parent private tab share identical rendering — they differ only in
  /// the [messages] shown, the scroll [controller], and the [scrollBehavior].
  Widget _buildThreadPane({
    required List<Message> messages,
    required AutoScrollController controller,
    required ChatScrollBehavior scrollBehavior,
    required CommunicationState state,
    bool isLoading = false,
  }) {
    if (isLoading) return const ChatThreadShimmer();
    return Stack(
      children: [
        // Visibility (not Opacity) excludes the hidden list from semantics
        // while off-screen — a reverse:true ListView whose hidden subtree
        // still participates in semantics while this Stack's visible child
        // flips is what triggers Flutter's `!semantics.parentDataDirty`
        // assertion crash on open.
        Visibility(
          visible: _isPositionedAtBottom.value,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: ListView.builder(
            controller: controller,
            // A handful of messages don't fill the viewport, and without
            // this the list isn't scrollable at all — so pull-to-refresh
            // never triggers regardless of message count.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: AppSizes.sm),
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[messages.length - 1 - index];
              final messageId = message.id;
              bool showDateHeader = false;
              final prevListIndex = messages.length - 2 - index;
              if (prevListIndex >= 0) {
                final prevMessage = messages[prevListIndex];
                final _schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
                final _currDate =
                    SchoolZoneDateTime.dateTimeFromInstantInSchool(
                      message.time,
                      _schoolTz,
                    );
                final _prevDate =
                    SchoolZoneDateTime.dateTimeFromInstantInSchool(
                      prevMessage.time,
                      _schoolTz,
                    );
                showDateHeader =
                    _currDate.year != _prevDate.year ||
                    _currDate.month != _prevDate.month ||
                    _currDate.day != _prevDate.day;
              } else {
                showDateHeader = true;
              }
              final prevMessage = prevListIndex >= 0
                  ? messages[prevListIndex]
                  : null;
              final isGrouped =
                  !showDateHeader && _isSameSender(prevMessage, message);

              return AutoScrollTag(
                key: ValueKey(messageId),
                controller: controller,
                index: index,
                highlightColor: AppColors.messagingScrollHighlight.withValues(alpha: 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDateHeader)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSizes.xs),
                          child: _buildDateChip(message.time),
                        ),
                      ),
                    if (showDateHeader) const SizedBox(height: AppSizes.xsPlus),
                    SizedBox(height: isGrouped ? 2.0 : 8.0),
                    ThreadMessageTile(
                      isGuardian: widget.isGuardian,
                      threadId: widget.parentInfo.code,
                      messageCode: message.code,
                      quotedMessageId: message.quotedMessageId,
                      onDeleteAttachment: (attachment) {
                        if (attachment.attachmentId != null) {
                          context.read<CommunicationCubit>().deleteAttachment(
                            widget.parentInfo.code,
                            attachment.attachmentId!,
                          );
                        }
                      },
                      onRetry: (msg) =>
                          context.read<CommunicationCubit>().retrySendMessage(
                            widget.parentInfo.code,
                            msg,
                          ),
                      currentUserCode: _currentUserCode,
                      reactionsController: _reactionsController,
                      isParentMessaging: true,
                      participants: _participants,
                      senderIsOrgSide: _isOrgSideSender(message),
                      viewerIsOrgSide: !widget.isGuardian,
                      isAdminCanDeleteAny:
                          _deletePermission.value.isAdminCanDeleteAny,
                      deleteTimeLimitMinutes:
                          _deletePermission.value.deleteTimeLimitMinutes,
                      onReply: message.isDeleted
                          ? null
                          : () {
                              _composer.quote(message);
                            },
                      onReplyFromMenu: message.isDeleted
                          ? null
                          : () {
                              _composer.quote(message);
                            },
                      onCopy: message.isDeleted
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: MessageContentProcessor.stripHtmlTags(
                                    message.text,
                                  ),
                                ),
                              );
                              CoreUtils.showTopSnackBar(
                                context: context,
                                message: 'Message copied successfully',
                                isSuccess: true,
                              );
                            },
                      onEdit: message.isDeleted
                          ? null
                          : () => _startEditing(message),
                      onDelete: message.isDeleted
                          ? null
                          : () => _deleteMessageWithFeedback(message.code),
                      onInfo: message.isDeleted
                          ? null
                          : () => _showMessageStatusDialog(context, message),
                      onScrollToQuoted: (quoteId) {
                        _scrollToMessage(quoteId);
                      },
                      onReactionAdded: (emoji) {
                        if (message.userHasReaction(
                          _currentUserCode ?? '',
                          emoji,
                        )) {
                          context.read<CommunicationCubit>().removeReaction(
                            widget.parentInfo.code,
                            message.code,
                            emoji,
                            currentUserCode: _currentUserCode,
                          );
                        } else {
                          context.read<CommunicationCubit>().addReaction(
                            widget.parentInfo.code,
                            message.code,
                            emoji,
                            currentUserCode: _currentUserCode,
                          );
                        }
                      },
                      onRemoveReaction: (emoji) {
                        context.read<CommunicationCubit>().removeReaction(
                          widget.parentInfo.code,
                          message.code,
                          emoji,
                          currentUserCode: _currentUserCode,
                        );
                      },
                      onReactionTap: () => _showEmojiPicker(context, message),
                      onReactionsInfoTap: () =>
                          _showReactionInfoDialog(context, message),
                      isGrouped: isGrouped,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: ValueListenableBuilder<bool>(
            valueListenable: scrollBehavior.showNewMessageIndicator,
            builder: (_, visible, __) => NewMessagesIndicator(
              visible: visible,
              onTap: () => scrollBehavior.scrollToBottom(),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: LoadingOlderIndicator(
            visible:
                state is CommunicationLoaded && state.isLoadingOlderMessages,
          ),
        ),
        if (!_isPositionedAtBottom.value)
          const Positioned.fill(child: ChatThreadShimmer()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return BlocConsumer<CommunicationCubit, CommunicationState>(
      listener: (context, state) {
        if (state is CommunicationLoaded) {
          _hasLoadedThreadOnce = true;
          _onMessagesChanged(_activeMessages);
        } else if (state is CommunicationError && _hasLoadedThreadOnce) {
          // Mid-thread failure (the thread was already showing) — surface
          // it as a snackbar. A true initial-load failure instead falls
          // through to the full-page error branch in `build()` below.
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message,
            isError: true,
          );
        }
      },
      builder: (context, state) {
        // Rebuild on the screen view-flags alongside the cubit state.
        return ListenableBuilder(
          listenable: Listenable.merge([
            _isPositionedAtBottom,
            _identityRev,
            _deletePermission,
            _refreshedParticipants,
          ]),
          builder: (context, _) {
            final _messages = _activeMessages;
            // Computed once per build, used by both layout branches' Parent1/
            // Parent2 tab panes below — avoids recomputing per list item.
            final _parent1Messages = _guardianEntries.isNotEmpty
                ? _messagesForParentTab(_messages, _guardianEntries[0].key)
                : const <Message>[];
            final _parent2Messages = _guardianEntries.length > 1
                ? _messagesForParentTab(_messages, _guardianEntries[1].key)
                : const <Message>[];
            // Group Chat tab (staff/admin, private mode on): non-private messages
            // only — the per-parent private messages live in their own tabs.
            final _groupMessages = _messages
                .where((m) => !m.isPrivate)
                .toList();
            // Derived flags used by the full layout to decide what to show in the
            // message area — the header and composer are ALWAYS rendered so the
            // screen doesn't re-layout when messages arrive.
            final isLoadingMessages =
                state is CommunicationLoading && _messages.isEmpty;
            final hasError = state is CommunicationError && _messages.isEmpty;
            final isEmpty = state is CommunicationLoaded && _messages.isEmpty;
            // Resolved once here so the inline conditionals below can reference it
            // without a cast (Dart doesn't narrow through a boolean variable).
            final errorMessage = state is CommunicationError
                ? state.message
                : '';
            final threadBody = GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xsPlus),
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.messagingMessageBoxBg,
                              ),
                              child: NestedScrollView(
                                // headerSliverBuilder intentionally empty — tabs
                                // moved to guardian chips in the header above.
                                headerSliverBuilder:
                                    (context, innerBoxIsScrolled) => const [],
                                body: CustomRefreshIndicator(
                                  onRefresh: _refreshThread,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: _privateModeEnabled
                                        ? [
                                            // Tab 0: Group Chat (non-private).
                                            Column(
                                              children: [
                                                Expanded(
                                                  child: _buildThreadPane(
                                                    messages: _groupMessages,
                                                    controller:
                                                        _groupController,
                                                    scrollBehavior:
                                                        _groupScrollBehavior,
                                                    state: state,
                                                    isLoading:
                                                        isLoadingMessages,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Tab 1: first guardian's private thread.
                                            if (_guardianEntries.isNotEmpty)
                                              Stack(
                                                children: [
                                                  ListView.builder(
                                                    controller:
                                                        _parent1Controller,
                                                    physics:
                                                        const AlwaysScrollableScrollPhysics(),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: AppSizes.xs,
                                                          vertical: AppSizes.sm,
                                                        ),
                                                    reverse: true,
                                                    itemCount:
                                                        _parent1Messages.length,
                                                    itemBuilder: (context, index) {
                                                      final message =
                                                          _parent1Messages[_parent1Messages
                                                                  .length -
                                                              1 -
                                                              index];
                                                      final messageId =
                                                          message.id;
                                                      bool showDateHeader =
                                                          false;
                                                      final prevListIndex =
                                                          _parent1Messages
                                                              .length -
                                                          2 -
                                                          index;

                                                      if (prevListIndex >= 0) {
                                                        final prevMessage =
                                                            _parent1Messages[prevListIndex];

                                                        final _schoolTz =
                                                            SchoolTimezoneResolver
                                                                .lastKnownTimeZone;
                                                        final _currDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              message.time,
                                                              _schoolTz,
                                                            );
                                                        final _prevDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              prevMessage.time,
                                                              _schoolTz,
                                                            );
                                                        showDateHeader =
                                                            _currDate.year !=
                                                                _prevDate
                                                                    .year ||
                                                            _currDate.month !=
                                                                _prevDate
                                                                    .month ||
                                                            _currDate.day !=
                                                                _prevDate.day;
                                                      } else {
                                                        showDateHeader = true;
                                                      }
                                                      final prevMessage =
                                                          prevListIndex >= 0
                                                          ? _parent1Messages[prevListIndex]
                                                          : null;
                                                      final isGrouped =
                                                          !showDateHeader &&
                                                          _isSameSender(
                                                            prevMessage,
                                                            message,
                                                          );

                                                      return AutoScrollTag(
                                                        key: ValueKey(
                                                          messageId,
                                                        ),
                                                        controller:
                                                            _parent1Controller,
                                                        index: index,
                                                        highlightColor: Colors
                                                            .green
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (showDateHeader)
                                                              Center(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top:
                                                                            8.0,
                                                                      ),
                                                                  child:
                                                                      _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                ),
                                                              ),
                                                            if (showDateHeader)
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                            // Spacing: compact for grouped, normal for new group
                                                            SizedBox(
                                                              height: isGrouped
                                                                  ? 2.0
                                                                  : 8.0,
                                                            ),
                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo.code,
                                                              messageCode:
                                                                  message.code,
                                                              quotedMessageId:
                                                                  message
                                                                      .quotedMessageId,
                                                              onDeleteAttachment: (attachment) {
                                                                if (attachment
                                                                        .attachmentId !=
                                                                    null) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .deleteAttachment(
                                                                        widget.parentInfo.code,
                                                                        attachment
                                                                            .attachmentId!,
                                                                      );
                                                                }
                                                              },
                                                              onRetry: (msg) => context
                                                                  .read<
                                                                    CommunicationCubit
                                                                  >()
                                                                  .retrySendMessage(
                                                                    widget.parentInfo.code,
                                                                    msg,
                                                                  ),
                                                              currentUserCode:
                                                                  _currentUserCode,
                                                              reactionsController:
                                                                  _reactionsController,
                                                              isParentMessaging:
                                                                  true,
                                                              participants:
                                                                  _participants,
                                                              senderIsOrgSide:
                                                                  _isOrgSideSender(
                                                                    message,
                                                                  ),
                                                              viewerIsOrgSide:
                                                                  !widget
                                                                      .isGuardian,
                                                              isAdminCanDeleteAny:
                                                                  _deletePermission
                                                                      .value
                                                                      .isAdminCanDeleteAny,
                                                              deleteTimeLimitMinutes:
                                                                  _deletePermission
                                                                      .value
                                                                      .deleteTimeLimitMinutes,
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onReplyFromMenu:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onCopy:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      Clipboard.setData(
                                                                        ClipboardData(
                                                                          text: MessageContentProcessor.stripHtmlTags(
                                                                            message.text,
                                                                          ),
                                                                        ),
                                                                      );
                                                                      CoreUtils.showTopSnackBar(
                                                                        context:
                                                                            context,
                                                                        message:
                                                                            'Message copied successfully',
                                                                        isSuccess:
                                                                            true,
                                                                      );
                                                                    },
                                                              onEdit:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _startEditing(
                                                                      message,
                                                                    ),
                                                              onDelete:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                              onInfo:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _showMessageStatusDialog(
                                                                      context,
                                                                      message,
                                                                    ),
                                                              onScrollToQuoted:
                                                                  (quoteId) {
                                                                    _scrollToMessage(
                                                                      quoteId,
                                                                    );
                                                                  },
                                                              onReactionAdded: (emoji) {
                                                                if (message
                                                                    .userHasReaction(
                                                                      _currentUserCode ??
                                                                          '',
                                                                      emoji,
                                                                    )) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .removeReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                } else {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .addReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                }
                                                              },
                                                              onRemoveReaction: (emoji) {
                                                                context
                                                                    .read<
                                                                      CommunicationCubit
                                                                    >()
                                                                    .removeReaction(
                                                                      widget.parentInfo.code,
                                                                      message
                                                                          .code,
                                                                      emoji,
                                                                      currentUserCode:
                                                                          _currentUserCode,
                                                                    );
                                                              },
                                                              onReactionTap: () =>
                                                                  _showEmojiPicker(
                                                                    context,
                                                                    message,
                                                                  ),
                                                              onReactionsInfoTap:
                                                                  () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                              isGrouped:
                                                                  isGrouped,
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 8,
                                                    child: ValueListenableBuilder<bool>(
                                                      valueListenable:
                                                          _parent1ScrollBehavior
                                                              .showNewMessageIndicator,
                                                      builder: (_, visible, __) =>
                                                          NewMessagesIndicator(
                                                            visible: visible,
                                                            onTap: () =>
                                                                _parent1ScrollBehavior
                                                                    .scrollToBottom(),
                                                          ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: 0,
                                                    child: LoadingOlderIndicator(
                                                      visible:
                                                          state
                                                              is CommunicationLoaded &&
                                                          state
                                                              .isLoadingOlderMessages,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            // Tab 2: second guardian's private thread.
                                            if (_guardianEntries.length > 1)
                                              Stack(
                                                children: [
                                                  ListView.builder(
                                                    controller:
                                                        _parent2Controller,
                                                    physics:
                                                        const AlwaysScrollableScrollPhysics(),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: AppSizes.xs,
                                                          vertical: AppSizes.sm,
                                                        ),
                                                    reverse: true,
                                                    itemCount:
                                                        _parent2Messages.length,
                                                    itemBuilder: (context, index) {
                                                      final message =
                                                          _parent2Messages[_parent2Messages
                                                                  .length -
                                                              1 -
                                                              index];
                                                      final messageId =
                                                          message.id;

                                                      bool showDateHeader =
                                                          false;
                                                      final prevListIndex =
                                                          _parent2Messages
                                                              .length -
                                                          2 -
                                                          index;

                                                      if (prevListIndex >= 0) {
                                                        final prevMessage =
                                                            _parent2Messages[prevListIndex];

                                                        final _schoolTz =
                                                            SchoolTimezoneResolver
                                                                .lastKnownTimeZone;
                                                        final _currDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              message.time,
                                                              _schoolTz,
                                                            );
                                                        final _prevDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              prevMessage.time,
                                                              _schoolTz,
                                                            );
                                                        showDateHeader =
                                                            _currDate.year !=
                                                                _prevDate
                                                                    .year ||
                                                            _currDate.month !=
                                                                _prevDate
                                                                    .month ||
                                                            _currDate.day !=
                                                                _prevDate.day;
                                                      } else {
                                                        showDateHeader = true;
                                                      }
                                                      final prevMessage =
                                                          prevListIndex >= 0
                                                          ? _parent2Messages[prevListIndex]
                                                          : null;
                                                      final isGrouped =
                                                          !showDateHeader &&
                                                          _isSameSender(
                                                            prevMessage,
                                                            message,
                                                          );

                                                      return AutoScrollTag(
                                                        key: ValueKey(
                                                          messageId,
                                                        ),
                                                        controller:
                                                            _parent2Controller,
                                                        index: index,
                                                        highlightColor: Colors
                                                            .green
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (showDateHeader)
                                                              Center(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top:
                                                                            8.0,
                                                                      ),
                                                                  child:
                                                                      _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                ),
                                                              ),
                                                            if (showDateHeader)
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                            // Spacing: compact for grouped, normal for new group
                                                            SizedBox(
                                                              height: isGrouped
                                                                  ? 2.0
                                                                  : 8.0,
                                                            ),
                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo.code,
                                                              messageCode:
                                                                  message.code,
                                                              quotedMessageId:
                                                                  message
                                                                      .quotedMessageId,
                                                              onDeleteAttachment: (attachment) {
                                                                if (attachment
                                                                        .attachmentId !=
                                                                    null) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .deleteAttachment(
                                                                        widget.parentInfo.code,
                                                                        attachment
                                                                            .attachmentId!,
                                                                      );
                                                                }
                                                              },
                                                              onRetry: (msg) => context
                                                                  .read<
                                                                    CommunicationCubit
                                                                  >()
                                                                  .retrySendMessage(
                                                                    widget.parentInfo.code,
                                                                    msg,
                                                                  ),
                                                              currentUserCode:
                                                                  _currentUserCode,
                                                              reactionsController:
                                                                  _reactionsController,
                                                              isParentMessaging:
                                                                  true,
                                                              participants:
                                                                  _participants,
                                                              senderIsOrgSide:
                                                                  _isOrgSideSender(
                                                                    message,
                                                                  ),
                                                              viewerIsOrgSide:
                                                                  !widget
                                                                      .isGuardian,
                                                              isAdminCanDeleteAny:
                                                                  _deletePermission
                                                                      .value
                                                                      .isAdminCanDeleteAny,
                                                              deleteTimeLimitMinutes:
                                                                  _deletePermission
                                                                      .value
                                                                      .deleteTimeLimitMinutes,
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onReplyFromMenu:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onCopy:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      Clipboard.setData(
                                                                        ClipboardData(
                                                                          text: MessageContentProcessor.stripHtmlTags(
                                                                            message.text,
                                                                          ),
                                                                        ),
                                                                      );
                                                                      CoreUtils.showTopSnackBar(
                                                                        context:
                                                                            context,
                                                                        message:
                                                                            'Message copied successfully',
                                                                        isSuccess:
                                                                            true,
                                                                      );
                                                                    },
                                                              onEdit:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _startEditing(
                                                                      message,
                                                                    ),
                                                              onDelete:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                              onInfo:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _showMessageStatusDialog(
                                                                      context,
                                                                      message,
                                                                    ),
                                                              onScrollToQuoted:
                                                                  (quoteId) {
                                                                    _scrollToMessage(
                                                                      quoteId,
                                                                    );
                                                                  },
                                                              onReactionAdded: (emoji) {
                                                                if (message
                                                                    .userHasReaction(
                                                                      _currentUserCode ??
                                                                          '',
                                                                      emoji,
                                                                    )) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .removeReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                } else {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .addReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                }
                                                              },
                                                              onRemoveReaction: (emoji) {
                                                                context
                                                                    .read<
                                                                      CommunicationCubit
                                                                    >()
                                                                    .removeReaction(
                                                                      widget.parentInfo.code,
                                                                      message
                                                                          .code,
                                                                      emoji,
                                                                      currentUserCode:
                                                                          _currentUserCode,
                                                                    );
                                                              },
                                                              onReactionTap: () =>
                                                                  _showEmojiPicker(
                                                                    context,
                                                                    message,
                                                                  ),
                                                              onReactionsInfoTap:
                                                                  () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                              isGrouped:
                                                                  isGrouped,
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 8,
                                                    child: ValueListenableBuilder<bool>(
                                                      valueListenable:
                                                          _parent2ScrollBehavior
                                                              .showNewMessageIndicator,
                                                      builder: (_, visible, __) =>
                                                          NewMessagesIndicator(
                                                            visible: visible,
                                                            onTap: () =>
                                                                _parent2ScrollBehavior
                                                                    .scrollToBottom(),
                                                          ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: 0,
                                                    child: LoadingOlderIndicator(
                                                      visible:
                                                          state
                                                              is CommunicationLoaded &&
                                                          state
                                                              .isLoadingOlderMessages,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ]
                                        : [
                                            if (isLoadingMessages)
                                              const ChatThreadShimmer()
                                            else if (hasError)
                                              _buildErrorState(
                                                context,
                                                errorMessage,
                                              )
                                            else if (isEmpty)
                                              _buildEmptyConversationState(
                                                context,
                                              )
                                            else
                                              Stack(
                                                children: [
                                                  ListView.builder(
                                                    controller:
                                                        _getActiveScrollController(),
                                                    physics:
                                                        const AlwaysScrollableScrollPhysics(),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: AppSizes.xs,
                                                          vertical: AppSizes.sm,
                                                        ),
                                                    reverse: true,
                                                    itemCount: _messages.length,
                                                    itemBuilder: (context, index) {
                                                      final message =
                                                          _messages[_messages
                                                                  .length -
                                                              1 -
                                                              index];
                                                      final messageId =
                                                          message.id;
                                                      bool showDateHeader =
                                                          false;
                                                      final prevListIndex =
                                                          _messages.length -
                                                          2 -
                                                          index;

                                                      if (prevListIndex >= 0) {
                                                        final prevMessage =
                                                            _messages[prevListIndex];

                                                        final _schoolTz =
                                                            SchoolTimezoneResolver
                                                                .lastKnownTimeZone;
                                                        final _currDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              message.time,
                                                              _schoolTz,
                                                            );
                                                        final _prevDate =
                                                            SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                              prevMessage.time,
                                                              _schoolTz,
                                                            );
                                                        showDateHeader =
                                                            _currDate.year !=
                                                                _prevDate
                                                                    .year ||
                                                            _currDate.month !=
                                                                _prevDate
                                                                    .month ||
                                                            _currDate.day !=
                                                                _prevDate.day;
                                                      } else {
                                                        showDateHeader = true;
                                                      }
                                                      final prevMessage =
                                                          prevListIndex >= 0
                                                          ? _messages[prevListIndex]
                                                          : null;
                                                      final isGrouped =
                                                          !showDateHeader &&
                                                          _isSameSender(
                                                            prevMessage,
                                                            message,
                                                          );

                                                      return AutoScrollTag(
                                                        key: ValueKey(
                                                          messageId,
                                                        ),
                                                        controller:
                                                            _getActiveScrollController(),
                                                        index: index,
                                                        highlightColor: Colors
                                                            .green
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (showDateHeader)
                                                              Center(
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top:
                                                                            8.0,
                                                                      ),
                                                                  child:
                                                                      _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                ),
                                                              ),
                                                            if (showDateHeader)
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                            // Spacing: compact for grouped, normal for new group
                                                            SizedBox(
                                                              height: isGrouped
                                                                  ? 2.0
                                                                  : 8.0,
                                                            ),
                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo.code,
                                                              messageCode:
                                                                  message.code,
                                                              quotedMessageId:
                                                                  message
                                                                      .quotedMessageId,
                                                              onDeleteAttachment: (attachment) {
                                                                if (attachment
                                                                        .attachmentId !=
                                                                    null) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .deleteAttachment(
                                                                        widget.parentInfo.code,
                                                                        attachment
                                                                            .attachmentId!,
                                                                      );
                                                                }
                                                              },
                                                              onRetry: (msg) => context
                                                                  .read<
                                                                    CommunicationCubit
                                                                  >()
                                                                  .retrySendMessage(
                                                                    widget.parentInfo.code,
                                                                    msg,
                                                                  ),
                                                              currentUserCode:
                                                                  _currentUserCode,
                                                              reactionsController:
                                                                  _reactionsController,
                                                              isParentMessaging:
                                                                  true,
                                                              participants:
                                                                  _participants,
                                                              senderIsOrgSide:
                                                                  _isOrgSideSender(
                                                                    message,
                                                                  ),
                                                              viewerIsOrgSide:
                                                                  !widget
                                                                      .isGuardian,
                                                              isAdminCanDeleteAny:
                                                                  _deletePermission
                                                                      .value
                                                                      .isAdminCanDeleteAny,
                                                              deleteTimeLimitMinutes:
                                                                  _deletePermission
                                                                      .value
                                                                      .deleteTimeLimitMinutes,
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onReplyFromMenu:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      _composer
                                                                          .quote(
                                                                            message,
                                                                          );
                                                                    },
                                                              onCopy:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      Clipboard.setData(
                                                                        ClipboardData(
                                                                          text: MessageContentProcessor.stripHtmlTags(
                                                                            message.text,
                                                                          ),
                                                                        ),
                                                                      );
                                                                      CoreUtils.showTopSnackBar(
                                                                        context:
                                                                            context,
                                                                        message:
                                                                            'Message copied successfully',
                                                                        isSuccess:
                                                                            true,
                                                                      );
                                                                    },
                                                              onEdit:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _startEditing(
                                                                      message,
                                                                    ),
                                                              onDelete:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                              onInfo:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () => _showMessageStatusDialog(
                                                                      context,
                                                                      message,
                                                                    ),
                                                              onScrollToQuoted:
                                                                  (quoteId) {
                                                                    _scrollToMessage(
                                                                      quoteId,
                                                                    );
                                                                  },
                                                              onReactionAdded: (emoji) {
                                                                if (message
                                                                    .userHasReaction(
                                                                      _currentUserCode ??
                                                                          '',
                                                                      emoji,
                                                                    )) {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .removeReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                } else {
                                                                  context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .addReaction(
                                                                        widget.parentInfo.code,
                                                                        message
                                                                            .code,
                                                                        emoji,
                                                                        currentUserCode:
                                                                            _currentUserCode,
                                                                      );
                                                                }
                                                              },
                                                              onRemoveReaction: (emoji) {
                                                                context
                                                                    .read<
                                                                      CommunicationCubit
                                                                    >()
                                                                    .removeReaction(
                                                                      widget.parentInfo.code,
                                                                      message
                                                                          .code,
                                                                      emoji,
                                                                      currentUserCode:
                                                                          _currentUserCode,
                                                                    );
                                                              },
                                                              onReactionTap: () =>
                                                                  _showEmojiPicker(
                                                                    context,
                                                                    message,
                                                                  ),
                                                              onReactionsInfoTap:
                                                                  () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                              isGrouped:
                                                                  isGrouped,
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    bottom: 8,
                                                    child: ValueListenableBuilder<bool>(
                                                      valueListenable:
                                                          _getActiveScrollBehavior()
                                                              .showNewMessageIndicator,
                                                      builder: (_, visible, __) =>
                                                          NewMessagesIndicator(
                                                            visible: visible,
                                                            onTap: () =>
                                                                _getActiveScrollBehavior()
                                                                    .scrollToBottom(),
                                                          ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: 0,
                                                    child: LoadingOlderIndicator(
                                                      visible:
                                                          state
                                                              is CommunicationLoaded &&
                                                          state
                                                              .isLoadingOlderMessages,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.xsPlus),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.35,
                            child: SingleChildScrollView(
                              reverse: true, // new messages appear at bottom
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.blackColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                // Only the composer rebuilds on quote/edit/
                                // attachment changes — the list above is untouched.
                                child: BlocBuilder<ComposerCubit<Message>, ComposerState<Message>>(
                                  bloc: _composer,
                                  builder: (context, composer) => ChatInputBar(
                                    controller: _controller,
                                    focusNode: _inputFocusNode,
                                    onSend: _sendMessage,
                                    onAttachmentTap: _showAttachmentSheet,
                                    isSending: state is CommunicationSending,
                                    enabled:
                                        !_studentInactive &&
                                        !_noActiveGuardian &&
                                        !_currentUserInactive,
                                    disabledMessage: _currentUserInactive
                                        ? 'Your staff account is inactive. You '
                                              'can no longer send messages.'
                                        : _studentInactive
                                        ? 'This student is inactive. You can no '
                                              'longer send messages.'
                                        : 'No active parent or guardian is '
                                              'available in this conversation. '
                                              'You can no longer send messages.',
                                    showCharCounter: true,
                                    pendingAttachments:
                                        composer.pendingAttachments,
                                    quotedMessage: composer.quotedMessage,
                                    onCancelQuote: _composer.clearQuote,
                                    onRemoveAttachment:
                                        _composer.removeAttachment,
                                    editingMessage: composer.editingMessage,
                                    onCancelEdit: () {
                                      _composer.cancelEdit();
                                      _controller.clear();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.messagingMessageBoxBg,
                              ),
                              child: Column(
                                children: [
                                  _buildParticipantHeader(),
                                  // TabBar removed — guardian chips in the header
                                  // now act as tab selectors (see _buildParticipantHeader).
                                  Expanded(
                                    child: CustomRefreshIndicator(
                                      onRefresh: _refreshThread,
                                      child: TabBarView(
                                        controller: _tabController,
                                        children: _privateModeEnabled
                                            ? [
                                                // Tab 0: Group Chat (non-private).
                                                Column(
                                                  children: [
                                                    Expanded(
                                                      child: _buildThreadPane(
                                                        messages:
                                                            _groupMessages,
                                                        controller:
                                                            _groupController,
                                                        scrollBehavior:
                                                            _groupScrollBehavior,
                                                        state: state,
                                                        isLoading:
                                                            isLoadingMessages,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Tab 1: first guardian's private thread.
                                                if (_guardianEntries.isNotEmpty)
                                                  Stack(
                                                    children: [
                                                      ListView.builder(
                                                        controller:
                                                            _parent1Controller,
                                                        physics:
                                                            const AlwaysScrollableScrollPhysics(),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: AppSizes.xs,
                                                              vertical: AppSizes.sm,
                                                            ),
                                                        reverse: true,
                                                        itemCount:
                                                            _parent1Messages
                                                                .length,
                                                        itemBuilder: (context, index) {
                                                          final message =
                                                              _parent1Messages[_parent1Messages
                                                                      .length -
                                                                  1 -
                                                                  index];
                                                          final messageId =
                                                              message.id;
                                                          bool showDateHeader =
                                                              false;
                                                          final prevListIndex =
                                                              _parent1Messages
                                                                  .length -
                                                              2 -
                                                              index;

                                                          if (prevListIndex >=
                                                              0) {
                                                            final prevMessage =
                                                                _parent1Messages[prevListIndex];

                                                            final _schoolTz =
                                                                SchoolTimezoneResolver
                                                                    .lastKnownTimeZone;
                                                            final _currDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  message.time,
                                                                  _schoolTz,
                                                                );
                                                            final _prevDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  prevMessage
                                                                      .time,
                                                                  _schoolTz,
                                                                );
                                                            showDateHeader =
                                                                _currDate
                                                                        .year !=
                                                                    _prevDate
                                                                        .year ||
                                                                _currDate
                                                                        .month !=
                                                                    _prevDate
                                                                        .month ||
                                                                _currDate.day !=
                                                                    _prevDate
                                                                        .day;
                                                          } else {
                                                            showDateHeader =
                                                                true;
                                                          }
                                                          final prevMessage =
                                                              prevListIndex >= 0
                                                              ? _parent1Messages[prevListIndex]
                                                              : null;
                                                          final isGrouped =
                                                              !showDateHeader &&
                                                              _isSameSender(
                                                                prevMessage,
                                                                message,
                                                              );

                                                          return AutoScrollTag(
                                                            key: ValueKey(
                                                              messageId,
                                                            ),
                                                            controller:
                                                                _parent1Controller,
                                                            index: index,
                                                            highlightColor:
                                                                AppColors.messagingScrollHighlight
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (showDateHeader)
                                                                  Center(
                                                                    child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                8.0,
                                                                          ),
                                                                      child: _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (showDateHeader)
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),

                                                                ThreadMessageTile(
                                                                  isGuardian: widget
                                                                      .isGuardian,
                                                                  threadId:
                                                                      widget.parentInfo.code,
                                                                  messageCode:
                                                                      message
                                                                          .code,
                                                                  quotedMessageId:
                                                                      message
                                                                          .quotedMessageId,
                                                                  onDeleteAttachment: (attachment) {
                                                                    if (attachment
                                                                            .attachmentId !=
                                                                        null) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .deleteAttachment(
                                                                            widget.parentInfo.code,
                                                                            attachment.attachmentId!,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRetry: (msg) => context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .retrySendMessage(
                                                                        widget.parentInfo.code,
                                                                        msg,
                                                                      ),
                                                                  currentUserCode:
                                                                      _currentUserCode,
                                                                  reactionsController:
                                                                      _reactionsController,
                                                                  isParentMessaging:
                                                                      true,
                                                                  participants:
                                                                      _participants,
                                                                  senderIsOrgSide:
                                                                      _isOrgSideSender(
                                                                        message,
                                                                      ),
                                                                  viewerIsOrgSide:
                                                                      !widget
                                                                          .isGuardian,
                                                                  isAdminCanDeleteAny:
                                                                      _deletePermission
                                                                          .value
                                                                          .isAdminCanDeleteAny,
                                                                  deleteTimeLimitMinutes:
                                                                      _deletePermission
                                                                          .value
                                                                          .deleteTimeLimitMinutes,
                                                                  onReply:
                                                                      message
                                                                          .isDeleted
                                                                      ? null
                                                                      : () {
                                                                          _composer.quote(
                                                                            message,
                                                                          );
                                                                        },
                                                                  onReplyFromMenu: () {
                                                                    _composer
                                                                        .quote(
                                                                          message,
                                                                        );
                                                                  },
                                                                  onCopy: () {
                                                                    Clipboard.setData(
                                                                      ClipboardData(
                                                                        text: MessageContentProcessor.stripHtmlTags(
                                                                          message
                                                                              .text,
                                                                        ),
                                                                      ),
                                                                    );
                                                                    CoreUtils.showTopSnackBar(
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          'Message copied',
                                                                      isSuccess:
                                                                          true,
                                                                    );
                                                                  },
                                                                  onEdit: () {
                                                                    _startEditing(
                                                                      message,
                                                                    );
                                                                  },
                                                                  onDelete: () =>
                                                                      _deleteMessageWithFeedback(
                                                                        message
                                                                            .code,
                                                                      ),
                                                                  onInfo: () =>
                                                                      _showMessageStatusDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onScrollToQuoted:
                                                                      (
                                                                        quoteId,
                                                                      ) => _scrollToMessage(
                                                                        quoteId,
                                                                      ),
                                                                  onReactionAdded: (emoji) {
                                                                    if (message
                                                                        .userHasReaction(
                                                                          _currentUserCode ??
                                                                              '',
                                                                          emoji,
                                                                        )) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .removeReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    } else {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .addReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRemoveReaction: (emoji) {
                                                                    context
                                                                        .read<
                                                                          CommunicationCubit
                                                                        >()
                                                                        .removeReaction(
                                                                          widget.parentInfo.code,
                                                                          message
                                                                              .code,
                                                                          emoji,
                                                                          currentUserCode:
                                                                              _currentUserCode,
                                                                        );
                                                                  },
                                                                  onReactionTap: () =>
                                                                      _showEmojiPicker(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onReactionsInfoTap: () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  isGrouped:
                                                                      isGrouped,
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 8,
                                                        child: ValueListenableBuilder<bool>(
                                                          valueListenable:
                                                              _parent1ScrollBehavior
                                                                  .showNewMessageIndicator,
                                                          builder:
                                                              (
                                                                _,
                                                                visible,
                                                                __,
                                                              ) => NewMessagesIndicator(
                                                                visible:
                                                                    visible,
                                                                onTap: () =>
                                                                    _parent1ScrollBehavior
                                                                        .scrollToBottom(),
                                                              ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        top: 0,
                                                        child: LoadingOlderIndicator(
                                                          visible:
                                                              state
                                                                  is CommunicationLoaded &&
                                                              state
                                                                  .isLoadingOlderMessages,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                // Tab 2: second guardian's private thread.
                                                if (_guardianEntries.length > 1)
                                                  Stack(
                                                    children: [
                                                      ListView.builder(
                                                        controller:
                                                            _parent2Controller,
                                                        physics:
                                                            const AlwaysScrollableScrollPhysics(),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: AppSizes.xs,
                                                              vertical: AppSizes.sm,
                                                            ),
                                                        reverse: true,
                                                        itemCount:
                                                            _parent2Messages
                                                                .length,
                                                        itemBuilder: (context, index) {
                                                          final message =
                                                              _parent2Messages[_parent2Messages
                                                                      .length -
                                                                  1 -
                                                                  index];
                                                          final messageId =
                                                              message.id;
                                                          bool showDateHeader =
                                                              false;
                                                          final prevListIndex =
                                                              _parent2Messages
                                                                  .length -
                                                              2 -
                                                              index;

                                                          if (prevListIndex >=
                                                              0) {
                                                            final prevMessage =
                                                                _parent2Messages[prevListIndex];

                                                            final _schoolTz =
                                                                SchoolTimezoneResolver
                                                                    .lastKnownTimeZone;
                                                            final _currDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  message.time,
                                                                  _schoolTz,
                                                                );
                                                            final _prevDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  prevMessage
                                                                      .time,
                                                                  _schoolTz,
                                                                );
                                                            showDateHeader =
                                                                _currDate
                                                                        .year !=
                                                                    _prevDate
                                                                        .year ||
                                                                _currDate
                                                                        .month !=
                                                                    _prevDate
                                                                        .month ||
                                                                _currDate.day !=
                                                                    _prevDate
                                                                        .day;
                                                          } else {
                                                            showDateHeader =
                                                                true;
                                                          }
                                                          final prevMessage =
                                                              prevListIndex >= 0
                                                              ? _parent2Messages[prevListIndex]
                                                              : null;
                                                          final isGrouped =
                                                              !showDateHeader &&
                                                              _isSameSender(
                                                                prevMessage,
                                                                message,
                                                              );

                                                          return AutoScrollTag(
                                                            key: ValueKey(
                                                              messageId,
                                                            ),
                                                            controller:
                                                                _parent2Controller,
                                                            index: index,
                                                            highlightColor:
                                                                AppColors.messagingScrollHighlight
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (showDateHeader)
                                                                  Center(
                                                                    child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                8.0,
                                                                          ),
                                                                      child: _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (showDateHeader)
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),

                                                                ThreadMessageTile(
                                                                  isGuardian: widget
                                                                      .isGuardian,
                                                                  threadId:
                                                                      widget.parentInfo.code,
                                                                  messageCode:
                                                                      message
                                                                          .code,
                                                                  quotedMessageId:
                                                                      message
                                                                          .quotedMessageId,
                                                                  onDeleteAttachment: (attachment) {
                                                                    if (attachment
                                                                            .attachmentId !=
                                                                        null) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .deleteAttachment(
                                                                            widget.parentInfo.code,
                                                                            attachment.attachmentId!,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRetry: (msg) => context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .retrySendMessage(
                                                                        widget.parentInfo.code,
                                                                        msg,
                                                                      ),
                                                                  currentUserCode:
                                                                      _currentUserCode,
                                                                  reactionsController:
                                                                      _reactionsController,
                                                                  isParentMessaging:
                                                                      true,
                                                                  participants:
                                                                      _participants,
                                                                  senderIsOrgSide:
                                                                      _isOrgSideSender(
                                                                        message,
                                                                      ),
                                                                  viewerIsOrgSide:
                                                                      !widget
                                                                          .isGuardian,
                                                                  isAdminCanDeleteAny:
                                                                      _deletePermission
                                                                          .value
                                                                          .isAdminCanDeleteAny,
                                                                  deleteTimeLimitMinutes:
                                                                      _deletePermission
                                                                          .value
                                                                          .deleteTimeLimitMinutes,
                                                                  onReply:
                                                                      message
                                                                          .isDeleted
                                                                      ? null
                                                                      : () {
                                                                          _composer.quote(
                                                                            message,
                                                                          );
                                                                        },
                                                                  onReplyFromMenu: () {
                                                                    _composer
                                                                        .quote(
                                                                          message,
                                                                        );
                                                                  },
                                                                  onCopy: () {
                                                                    Clipboard.setData(
                                                                      ClipboardData(
                                                                        text: MessageContentProcessor.stripHtmlTags(
                                                                          message
                                                                              .text,
                                                                        ),
                                                                      ),
                                                                    );
                                                                    CoreUtils.showTopSnackBar(
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          'Message copied',
                                                                      isSuccess:
                                                                          true,
                                                                    );
                                                                  },
                                                                  onEdit: () {
                                                                    _startEditing(
                                                                      message,
                                                                    );
                                                                  },
                                                                  onDelete: () =>
                                                                      _deleteMessageWithFeedback(
                                                                        message
                                                                            .code,
                                                                      ),
                                                                  onInfo: () =>
                                                                      _showMessageStatusDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onScrollToQuoted:
                                                                      (
                                                                        quoteId,
                                                                      ) => _scrollToMessage(
                                                                        quoteId,
                                                                      ),
                                                                  onReactionAdded: (emoji) {
                                                                    if (message
                                                                        .userHasReaction(
                                                                          _currentUserCode ??
                                                                              '',
                                                                          emoji,
                                                                        )) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .removeReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    } else {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .addReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRemoveReaction: (emoji) {
                                                                    context
                                                                        .read<
                                                                          CommunicationCubit
                                                                        >()
                                                                        .removeReaction(
                                                                          widget.parentInfo.code,
                                                                          message
                                                                              .code,
                                                                          emoji,
                                                                          currentUserCode:
                                                                              _currentUserCode,
                                                                        );
                                                                  },
                                                                  onReactionTap: () =>
                                                                      _showEmojiPicker(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onReactionsInfoTap: () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  isGrouped:
                                                                      isGrouped,
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 8,
                                                        child: ValueListenableBuilder<bool>(
                                                          valueListenable:
                                                              _parent2ScrollBehavior
                                                                  .showNewMessageIndicator,
                                                          builder:
                                                              (
                                                                _,
                                                                visible,
                                                                __,
                                                              ) => NewMessagesIndicator(
                                                                visible:
                                                                    visible,
                                                                onTap: () =>
                                                                    _parent2ScrollBehavior
                                                                        .scrollToBottom(),
                                                              ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        top: 0,
                                                        child: LoadingOlderIndicator(
                                                          visible:
                                                              state
                                                                  is CommunicationLoaded &&
                                                              state
                                                                  .isLoadingOlderMessages,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ]
                                            : [
                                                if (isLoadingMessages)
                                                  const ChatThreadShimmer()
                                                else if (hasError)
                                                  _buildErrorState(
                                                    context,
                                                    errorMessage,
                                                  )
                                                else if (isEmpty)
                                                  _buildEmptyConversationState(
                                                    context,
                                                  )
                                                else
                                                  Stack(
                                                    children: [
                                                      ListView.builder(
                                                        controller:
                                                            _getActiveScrollController(),
                                                        physics:
                                                            const AlwaysScrollableScrollPhysics(),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: AppSizes.xs,
                                                              vertical: AppSizes.sm,
                                                            ),
                                                        reverse: true,
                                                        itemCount:
                                                            _messages.length,
                                                        itemBuilder: (context, index) {
                                                          final message =
                                                              _messages[_messages
                                                                      .length -
                                                                  1 -
                                                                  index];
                                                          final messageId =
                                                              message.id;
                                                          bool showDateHeader =
                                                              false;
                                                          final prevListIndex =
                                                              _messages.length -
                                                              2 -
                                                              index;

                                                          if (prevListIndex >=
                                                              0) {
                                                            final prevMessage =
                                                                _messages[prevListIndex];

                                                            final _schoolTz =
                                                                SchoolTimezoneResolver
                                                                    .lastKnownTimeZone;
                                                            final _currDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  message.time,
                                                                  _schoolTz,
                                                                );
                                                            final _prevDate =
                                                                SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                                  prevMessage
                                                                      .time,
                                                                  _schoolTz,
                                                                );
                                                            showDateHeader =
                                                                _currDate
                                                                        .year !=
                                                                    _prevDate
                                                                        .year ||
                                                                _currDate
                                                                        .month !=
                                                                    _prevDate
                                                                        .month ||
                                                                _currDate.day !=
                                                                    _prevDate
                                                                        .day;
                                                          } else {
                                                            showDateHeader =
                                                                true;
                                                          }
                                                          final prevMessage =
                                                              prevListIndex >= 0
                                                              ? _messages[prevListIndex]
                                                              : null;
                                                          final isGrouped =
                                                              !showDateHeader &&
                                                              _isSameSender(
                                                                prevMessage,
                                                                message,
                                                              );

                                                          return AutoScrollTag(
                                                            key: ValueKey(
                                                              messageId,
                                                            ),
                                                            controller:
                                                                _getActiveScrollController(),
                                                            index: index,
                                                            highlightColor:
                                                                AppColors.messagingScrollHighlight
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (showDateHeader)
                                                                  Center(
                                                                    child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                8.0,
                                                                          ),
                                                                      child: _buildDateChip(
                                                                        message
                                                                            .time,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (showDateHeader)
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),

                                                                ThreadMessageTile(
                                                                  isGuardian: widget
                                                                      .isGuardian,
                                                                  threadId:
                                                                      widget.parentInfo.code,
                                                                  messageCode:
                                                                      message
                                                                          .code,
                                                                  quotedMessageId:
                                                                      message
                                                                          .quotedMessageId,
                                                                  onDeleteAttachment: (attachment) {
                                                                    if (attachment
                                                                            .attachmentId !=
                                                                        null) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .deleteAttachment(
                                                                            widget.parentInfo.code,
                                                                            attachment.attachmentId!,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRetry: (msg) => context
                                                                      .read<
                                                                        CommunicationCubit
                                                                      >()
                                                                      .retrySendMessage(
                                                                        widget.parentInfo.code,
                                                                        msg,
                                                                      ),
                                                                  currentUserCode:
                                                                      _currentUserCode,
                                                                  reactionsController:
                                                                      _reactionsController,
                                                                  isParentMessaging:
                                                                      true,
                                                                  participants:
                                                                      _participants,
                                                                  senderIsOrgSide:
                                                                      _isOrgSideSender(
                                                                        message,
                                                                      ),
                                                                  viewerIsOrgSide:
                                                                      !widget
                                                                          .isGuardian,
                                                                  isAdminCanDeleteAny:
                                                                      _deletePermission
                                                                          .value
                                                                          .isAdminCanDeleteAny,
                                                                  deleteTimeLimitMinutes:
                                                                      _deletePermission
                                                                          .value
                                                                          .deleteTimeLimitMinutes,
                                                                  onReply:
                                                                      message
                                                                          .isDeleted
                                                                      ? null
                                                                      : () {
                                                                          _composer.quote(
                                                                            message,
                                                                          );
                                                                        },
                                                                  onReplyFromMenu: () {
                                                                    _composer
                                                                        .quote(
                                                                          message,
                                                                        );
                                                                  },
                                                                  onCopy: () {
                                                                    Clipboard.setData(
                                                                      ClipboardData(
                                                                        text: MessageContentProcessor.stripHtmlTags(
                                                                          message
                                                                              .text,
                                                                        ),
                                                                      ),
                                                                    );
                                                                    CoreUtils.showTopSnackBar(
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          'Message copied',
                                                                      isSuccess:
                                                                          true,
                                                                    );
                                                                  },
                                                                  onEdit: () {
                                                                    _startEditing(
                                                                      message,
                                                                    );
                                                                  },
                                                                  onDelete: () =>
                                                                      _deleteMessageWithFeedback(
                                                                        message
                                                                            .code,
                                                                      ),
                                                                  onInfo: () =>
                                                                      _showMessageStatusDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onScrollToQuoted:
                                                                      (
                                                                        quoteId,
                                                                      ) => _scrollToMessage(
                                                                        quoteId,
                                                                      ),
                                                                  onReactionAdded: (emoji) {
                                                                    if (message
                                                                        .userHasReaction(
                                                                          _currentUserCode ??
                                                                              '',
                                                                          emoji,
                                                                        )) {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .removeReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    } else {
                                                                      context
                                                                          .read<
                                                                            CommunicationCubit
                                                                          >()
                                                                          .addReaction(
                                                                            widget.parentInfo.code,
                                                                            message.code,
                                                                            emoji,
                                                                            currentUserCode:
                                                                                _currentUserCode,
                                                                          );
                                                                    }
                                                                  },
                                                                  onRemoveReaction: (emoji) {
                                                                    context
                                                                        .read<
                                                                          CommunicationCubit
                                                                        >()
                                                                        .removeReaction(
                                                                          widget.parentInfo.code,
                                                                          message
                                                                              .code,
                                                                          emoji,
                                                                          currentUserCode:
                                                                              _currentUserCode,
                                                                        );
                                                                  },
                                                                  onReactionTap: () =>
                                                                      _showEmojiPicker(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  onReactionsInfoTap: () =>
                                                                      _showReactionInfoDialog(
                                                                        context,
                                                                        message,
                                                                      ),
                                                                  isGrouped:
                                                                      isGrouped,
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 8,
                                                        child: ValueListenableBuilder<bool>(
                                                          valueListenable:
                                                              _getActiveScrollBehavior()
                                                                  .showNewMessageIndicator,
                                                          builder:
                                                              (
                                                                _,
                                                                visible,
                                                                __,
                                                              ) => NewMessagesIndicator(
                                                                visible:
                                                                    visible,
                                                                onTap: () =>
                                                                    _getActiveScrollBehavior()
                                                                        .scrollToBottom(),
                                                              ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        top: 0,
                                                        child: LoadingOlderIndicator(
                                                          visible:
                                                              state
                                                                  is CommunicationLoaded &&
                                                              state
                                                                  .isLoadingOlderMessages,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.xsPlus),
                          SafeArea(
                            top: false,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.cardColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blackColor.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child:
                                  BlocBuilder<
                                    ComposerCubit<Message>,
                                    ComposerState<Message>
                                  >(
                                    bloc: _composer,
                                    builder: (context, composer) => ChatInputBar(
                                      controller: _controller,
                                      focusNode: _inputFocusNode,
                                      onSend: _sendMessage,
                                      onAttachmentTap: _showAttachmentSheet,
                                      enabled:
                                          !_studentInactive &&
                                          !_noActiveGuardian &&
                                          !_currentUserInactive,
                                      disabledMessage: _currentUserInactive
                                          ? 'Your staff account is inactive. You '
                                                'can no longer send messages.'
                                          : _studentInactive
                                          ? 'This student is inactive. You can no '
                                                'longer send messages.'
                                          : 'No active parent or guardian is '
                                                'available in this conversation. '
                                                'You can no longer send messages.',
                                      showCharCounter: true,
                                      pendingAttachments:
                                          composer.pendingAttachments,
                                      quotedMessage: composer.quotedMessage,
                                      onCancelQuote: _composer.clearQuote,
                                      onRemoveAttachment:
                                          _composer.removeAttachment,
                                      editingMessage: composer.editingMessage,
                                      onCancelEdit: () {
                                        _composer.cancelEdit();
                                        _controller.clear();
                                      },
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
              ), // Padding
            ); // GestureDetector
            // The message list (and its scroll controllers) must stay mounted — and
            // therefore attached — the whole time, or `scrollToBottom()` has nothing
            // to scroll and silently no-ops. The opacity/shimmer that hides the list
            // until the first scroll-to-bottom settles is scoped to the message pane
            // itself (see `_buildThreadPane`) so the header, tabs and input bar stay
            // visible during load instead of the whole screen being covered.
            if (!widget.showOwnScaffold) return threadBody;
            return Scaffold(body: SafeArea(child: threadBody));
          },
        );
      },
    );
  }

  /// Shown when the thread has loaded successfully but has no messages yet —
  /// the input bar stays usable so the user can start the conversation,
  /// unlike the loading/error states which replace the whole screen.
  Widget _buildEmptyConversationState(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xsPlus),
        child: Column(
          children: [
            Expanded(
              // A bare Center has no scrollable ancestor for the pull
              // gesture (routed up from CustomRefreshIndicator, wrapped
              // around the TabBarView above) to register against — wrap in
              // a scrollable so pull-to-refresh works on a brand-new/empty
              // conversation too, not just once messages exist.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 56,
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            const CustomTextWidget(
                              text: 'No messages yet',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: AppSizes.xxs),
                            CustomTextWidget(
                              text: AppStrings.sayHelloToStart,
                              fontSize: 13,
                              fontColor: AppColors.messagingTextMeta,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // No ChatInputBar here: this empty-state is rendered INSIDE the thread body (the
            // `else if (isEmpty)` branch of the message area), and that body already has an
            // always-present ChatInputBar below it. Rendering a second one here showed a DUPLICATE
            // composer when a conversation was opened, until the first message was sent (which flips
            // isEmpty=false and hides this branch). The body's composer keeps input usable while empty.
          ],
        ),
      ),
    );
  }

  /// True for a backend "you're not a participant of this conversation"
  /// response (403 Access denied) — happens for a conversation that was
  /// never actually created properly. Retrying the same load will just
  /// 403 again forever, so this gets a different message/CTA than a
  /// transient network failure.
  bool _isUnauthorizedConversationError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('access denied') ||
        lower.contains('not authorized') ||
        lower.contains('403');
  }

  /// Shown when [CommunicationCubit] has no cached history to fall back on
  /// and the latest fetch failed — gives the user a way to retry instead of
  /// staring at a blank screen. A 403/"not authorized" failure means this
  /// conversation was never actually created properly, so it offers "Go
  /// back" instead of a "Retry" that would just fail the same way again.
  Widget _buildErrorState(BuildContext context, String message) {
    final isUnauthorized = _isUnauthorizedConversationError(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnauthorized
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.error_outline_rounded,
              size: 48,
              color: isUnauthorized ? AppColors.messagingIconMuted : AppColors.messagingErrorIcon,
            ),
            const SizedBox(height: AppSizes.sm),
            CustomTextWidget(
              text: isUnauthorized
                  ? AppStrings.chatNotCreatedYet
                  : AppStrings.unableToLoadMessages,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 6),
            CustomTextWidget(
              text: isUnauthorized
                  ? AppStrings.goBackStartNew
                  : message,
              fontSize: 13,
              fontColor: AppColors.messagingTextMeta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            GestureDetector(
              onTap: () {
                if (isUnauthorized) {
                  Navigator.of(context).pop();
                  return;
                }
                final convCode = widget.parentInfo.code;
                context.read<CommunicationCubit>().loadMessages(
                  convCode,
                  currentUserId: _currentUserCode,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: AppSizes.sm,
                ),
                decoration: AppSurfaces.key(
                  KeyVariant.primary,
                  radius: AppRadius.pill,
                ),
                child: CustomTextWidget(
                  text: isUnauthorized ? AppStrings.goBack : AppStrings.retry,
                  fontColor: AppColors.messagingOnAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ConversationParticipant> get _participants {
    if (_refreshedParticipants.value != null)
      return _refreshedParticipants.value!;
    return widget.parentInfo.participants;
  }

  /// Whether the current user is still an ACTIVE participant in this
  /// conversation, per the freshest data we have. `null` (no match found)
  /// is treated as active rather than blocking — a user who somehow isn't
  /// in the participant list at all (e.g. participants haven't loaded yet)
  /// shouldn't be silently locked out by this client-side check; the
  /// backend is the authority that actually enforces this.
  bool get _amIActiveParticipant {
    if (_currentUserCode == null) return true;
    final mine = _participants.where((p) => p.userCode == _currentUserCode);
    if (mine.isEmpty) return true;
    return mine.first.isActive;
  }

  /// True when staff/admin is viewing this Room Chat but every guardian has
  /// left/been removed — no one is left on the parent side to receive a new
  /// message. A guardian's OWN view is unaffected (their own active status
  /// is enforced by [_amIActiveParticipant] instead) — this only gates the
  /// staff/admin side. Mirrors `ConversationThreadScreen._noActiveGuardian`.
  bool get _noActiveGuardian =>
      !widget.isGuardian &&
      !_participants.any(
        (p) =>
            ParticipantRole.fromApiString(p.role) == ParticipantRole.parent &&
            p.isActive,
      );

  /// True when this Room Chat conversation's student is no longer active
  /// (withdrawn/inactive) — every side (staff, admin, and the guardian)
  /// loses the ability to send once the student itself is gone, unlike
  /// [_noActiveGuardian] which only blocks the staff/admin side. Takes
  /// priority over [_noActiveGuardian] when composing the composer's
  /// disabled message. Mirrors `ConversationThreadScreen._studentInactive`.
  bool get _studentInactive {
    // Only INACTIVE (withdrawn) actually blocks sending — UPCOMING is a
    // normal, not-yet-started enrollment state and must behave like ACTIVE
    // here.
    final status = (widget.parentInfo.studentStatus)
        ?.trim()
        .toUpperCase();
    return status == 'INACTIVE';
  }

  /// True when the CURRENT USER's own participant record shows a staff
  /// employment status of INACTIVE. Distinct from [_amIActiveParticipant]
  /// (which only covers being removed from THIS conversation) — a
  /// since-terminated/deactivated staff member can still be `active: true`
  /// with `leftAt: null` on the participant row while their `staffStatus`
  /// says INACTIVE, so both checks are needed.
  bool get _currentUserInactive {
    if (_currentUserCode == null) return false;
    final mine = _participants.where((p) => p.userCode == _currentUserCode);
    if (mine.isEmpty) return false;
    final status = mine.first.staffStatus?.trim().toUpperCase();
    return status == 'INACTIVE';
  }

  /// Fetches the current conversation fresh from the backend and replaces
  /// [_refreshedParticipants.value] with whatever it actually returns — the
  /// `participants` the screen was opened with came from the inbox list,
  /// which can be stale relative to classroom/guardian/admin changes that
  /// happened since that list was last loaded. Best-effort: a failure here
  /// just means the screen keeps using the (possibly stale) data it already
  /// had, same as before this existed.
  Future<void> _refreshParticipants(String conversationCode) async {
    final result = await context.read<CommunicationCubit>()
        .getConversationEntity(conversationCode);
    if (!mounted) return;
    result.fold(
      (_) {
        // Stay on whatever participants we already have — the thread is
        // still usable, just potentially stale until the next refresh.
      },
      (conversation) {
        _refreshedParticipants.value = legacyParticipantsFromEntities(
          conversation.participants,
        );
        // Re-seed the recipient count read/delivered-by-all tick
        // aggregation uses (CommunicationCubit.seedRecipientCount) with
        // this fresher roster — the seed the caller screen provided at
        // navigation time can be stale/incomplete for the exact same
        // reason [_refreshedParticipants.value] exists, and unlike that field it
        // is otherwise never corrected for the life of this screen (see
        // seedRecipientCount's own doc), which was making a group message
        // look "read by everyone" once just the FEW participants the stale
        // seed knew about had actually read it.
        final freshCount = conversation.participants
            .where((p) => p.isActive && p.userCode != _currentUserCode)
            .length;
        if (freshCount > 0 && mounted) {
          context.read<CommunicationCubit>().seedRecipientCount(
            conversationCode,
            freshCount,
          );
        }
      },
    );
  }

  /// Returns a human-readable label for [role] when the backend hasn't
  /// provided a display name. Never exposes raw user / staff codes.
  static String _roleLabelFallback(String role) {
    switch (role.toUpperCase()) {
      case 'STAFF':
      case 'TEACHER':
      case 'LEAD_TEACHER':
        return 'Staff Member';
      case 'ADMIN':
      case 'DIRECTOR':
      case 'PRINCIPAL':
      case 'ASSISTANT_DIRECTOR':
        return 'Admin';
      case 'PARENT':
      case 'GUARDIAN':
        return 'Guardian';
      default:
        return 'Participant';
    }
  }

  List<ParticipantDisplayData> get _participantDisplayData =>
      _participants.where((p) => p.isActive).map((p) {
        final roleStr = p.role.toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        // Never fall back to p.userCode — that would expose internal codes
        // like 'STF001' or 'EMP102' in the UI (Task 3).
        final displayName = p.userName.trim().isNotEmpty
            ? p.userName.trim()
            : _roleLabelFallback(roleStr);
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: displayName,
          role: normalised,
          avatarUrl: p.avatarUrl,
          staffCode: p.staffCode,
        );
      }).toList();

  /// True if [m]'s sender is staff/admin/teacher/director, false if
  /// guardian/parent — the role-class signal the canonical bubble
  /// alignment rule needs (docs/messaging/06-ui-standards.md).
  ///
  /// Prefers [Message.senderRole] — the exact role THIS message was sent
  /// under — over a participant-list lookup by `senderUserCode`. A dual-role
  /// account (e.g. an admin who is also the enrolled child's guardian) has
  /// TWO participant entries sharing the same userCode; looking up "by code"
  /// alone can't tell which persona sent a given message and would silently
  /// pick whichever entry happens to be first, exactly the bug already fixed
  /// for message ownership via `senderRole` (see [withRoleAwareOwnership]) —
  /// this is that same fix applied to the org/guardian colour-and-alignment
  /// signal. Only falls back to the participant list (defaulting to
  /// guardian) when a message has no `senderRole` at all (older cached rows,
  /// system messages, or stale data mid-refresh).
  bool _isOrgSideSender(Message m) {
    final senderRole = m.senderRole;
    if (senderRole != null && senderRole.isNotEmpty) {
      return ParticipantRole.fromApiString(senderRole) !=
          ParticipantRole.parent;
    }
    final code = m.senderUserCode;
    final role =
        _participantDisplayData
            .where((d) => d.userCode == code)
            .firstOrNull
            ?.role ??
        'GUARDIAN';
    return role == 'STAFF' ||
        role == 'ADMIN' ||
        role == 'DIRECTOR' ||
        role == 'TEACHER';
  }

  void _showParticipantsDialog() {
    final studentName = widget.parentInfo.name;
    final avatarUuid = widget.parentInfo.avatar;
    ParticipantInfoDialog.show(
      context,
      participants: _participantDisplayData,
      studentName: studentName,
      studentAvatarUuid: avatarUuid,
    );
  }

  void _showAttachmentSheet() {
    MessageAttachmentBottomSheet.show(
      context,
      onAttachmentsSelected: (attachments) {
        if (attachments.isEmpty) return;
        // Add to whatever's already staged — picking multiple photos/videos
        // together (or picking again before sending) must accumulate, not
        // discard everything but the newest single file.
        _composer.addAttachments(attachments);
      },
      onEmojiSelected: (emoji) {
        final pos = _controller.selection.isValid
            ? _controller.selection.baseOffset
            : _controller.text.length;
        final text = _controller.text;
        _controller.value = _controller.value.copyWith(
          text: text.substring(0, pos) + emoji + text.substring(pos),
          selection: TextSelection.collapsed(offset: pos + emoji.length),
        );
      },
      onViewParticipants: _showParticipantsDialog,
      onAttachmentError: (message) {
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: message,
          isError: true,
        );
      },
    );
  }

  Widget _buildParticipantHeader() {
    // Only currently-active participants count toward the header's
    // count/chip display — a Past Participant (left or deactivated) is
    // still kept in message-attribution logic elsewhere, but shouldn't
    // clutter this "who's in the conversation right now" summary.
    final participants = _participants.where((p) => p.isActive).toList();
    final title = widget.parentInfo.name;
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        border: Border(bottom: BorderSide(color: AppColors.messagingBorderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Avatar + Title + Info + Private Mode Toggle (Guardian only)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.xxs, AppSizes.xs),
            child: Row(
              children: [
                // Back arrow — hidden for guardian persona (PRD requirement)
                if (!widget.isGuardian)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.xxs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                if (!widget.isGuardian) const SizedBox(width: AppSizes.xsPlus),
                DocumentImageWidget(
                  disableAttendanceStatusLookup: true,
                  fileUuid: '',
                  imageUrl:
                      widget.parentInfo.avatar.startsWith(
                        'http',
                      )
                      ? widget.parentInfo.avatar
                      : null,
                  mediaAssetCode:
                      widget.parentInfo.avatar
                              .isNotEmpty &&
                          !widget.parentInfo.avatar
                              .startsWith('http')
                      ? widget.parentInfo.avatar
                      : null,
                  name: title,
                  size: 34,
                ),
                const SizedBox(width: AppSizes.xsPlus),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextWidget(
                        text: title,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (count != null)
                        Text(
                          AppStrings.participantCountLabel(count),
                          style: AppTextStyles.size14.copyWith(
                            fontSize: 11,
                            color: AppColors.messagingTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Custom Private Mode Toggle — Only for guardian persona (PRD requirement)
                if (widget.isGuardian && _privateModeToggleCubit != null)
                  BlocProvider<PrivateModeToggleCubit>.value(
                    value: _privateModeToggleCubit!,
                    child:
                        BlocConsumer<
                          PrivateModeToggleCubit,
                          PrivateModeToggleState
                        >(
                          listener: (context, toggleState) {
                            if (toggleState.errorMessage != null) {
                              CoreUtils.showTopSnackBar(
                                context: context,
                                message: toggleState.errorMessage!,
                                isError: true,
                              );
                            }
                            if (toggleState.successMessage != null) {
                              CoreUtils.showTopSnackBar(
                                context: context,
                                message: toggleState.successMessage!,
                                isSuccess: true,
                              );
                            }
                          },
                          builder: (context, toggleState) {
                            // Only the guardian who activated it (or nobody
                            // yet, i.e. about to turn it ON) may operate the
                            // toggle — matches the backend's own 403 rule.
                            // Disabling it here, now that `activatedBy` is
                            // tracked live (see PrivateModeToggleCubit), means
                            // a non-activator sees a disabled switch instead
                            // of tapping it and hitting that rejection.
                            final isActivator =
                                toggleState.activatedBy == null ||
                                toggleState.activatedBy == _currentUserCode;
                            final canOperate =
                                !toggleState.isLoading &&
                                (isActivator || !toggleState.isEnabled);
                            return Tooltip(
                              message: !canOperate
                                  ? AppStrings.privateModeOnlyActivatorCanDisable
                                  : toggleState.isEnabled
                                  ? AppStrings.privateModeOnTooltip
                                  : AppStrings.privateModeOffTooltip,
                              child: CustomToggle(
                                label: AppStrings.privateLabel,
                                isToggled: toggleState.isEnabled,
                                onToggle: (value) {
                                  context
                                      .read<PrivateModeToggleCubit>()
                                      .toggle();
                                },
                                labelOnLeftSide: true,
                                labelStyle: AppTextStyles.size14.copyWith(
                                  color: toggleState.isEnabled
                                      ? AppColors.messagingRoleDirector
                                      : AppColors.messagingTextMeta,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                enabled: canOperate,
                              ),
                            );
                          },
                        ),
                  ),
                const SizedBox(width: AppSizes.xs),
                Tooltip(
                  message: 'View Participants',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    onPressed: _showParticipantsDialog,
                  ),
                ),
              ],
            ),
          ),
          // Persistently-visible "who started this" banner for the guardian
          // persona — mirrors the equivalent banner already shown on the
          // admin/staff side (ConversationThreadScreen's
          // _buildPrivateModeHeader). Previously a guardian only had the
          // toggle's own tooltip (hover/long-press only) to learn this, and
          // nothing at all told the guardian who DIDN'T activate it why
          // their thread suddenly went private — this shows unconditionally
          // whenever private mode is active for this widget's guardian
          // (self or another), same as the toggle's own is-active state.
          if (widget.isGuardian && _privateModeToggleCubit != null)
            BlocBuilder<PrivateModeToggleCubit, PrivateModeToggleState>(
              bloc: _privateModeToggleCubit,
              builder: (context, toggleState) {
                if (!toggleState.isEnabled) return const SizedBox.shrink();
                final activatorCode = toggleState.activatedBy;
                final activatorName = activatorCode == null
                    ? null
                    : (activatorCode == _currentUserCode
                          ? 'You'
                          : (_participantDisplayData
                                    .where((p) => p.userCode == activatorCode)
                                    .firstOrNull
                                    ?.displayName ??
                                'a guardian'));
                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xs),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xsPlus,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.messagingNoticeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.messagingNoticeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.messagingNoticeText,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              activatorName == null
                                  ? AppStrings.privateLabel
                                  : AppStrings.privateBy(activatorName),
                              style: AppTextStyles.size14.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.messagingNoticeText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          // Chip row: when private mode is on (staff/admin view) the chips are
          // interactive tab selectors; otherwise they are read-only name badges.
          if (_privateModeEnabled) ...[
            // Tab-selector chips: "Group Chat" + one chip per guardian.
            // Tapping switches the TabBarView without showing a TabBar.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xs),
              child: SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTabChip(
                      label: AppStrings.groupChat,
                      tabIndex: 0,
                      color: AppColors.themeColor,
                      isPrivate: false,
                    ),
                    ..._guardianEntries.take(2).toList().asMap().entries.map((
                      e,
                    ) {
                      final tabIndex = e.key + 1;
                      final guardianName = e.value.value;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildTabChip(
                          label: guardianName,
                          tabIndex: tabIndex,
                          color: AppColors.messagingRoleGuardian,
                          isPrivate: _isParentInPrivateMode(guardianName),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Read-only guardian chips when private mode is off (guardian view
            // or staff view without active private mode).
            Builder(
              builder: (context) {
                final guardianChips = participants.where((p) {
                  final role = p.role.toUpperCase();
                  return role == 'PARENT' || role == 'GUARDIAN';
                }).toList();
                if (guardianChips.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xs),
                  child: ParentParticipantChips(
                    participants: guardianChips,
                    privateModeEnabled: false,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final schoolDate = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      date,
      schoolTz,
    );
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      ServerTimeService.instance.nowUtc(),
      schoolTz,
    );

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Matches web's groupMessagesByDate (ChatMessageArea.tsx): "Today" /
    // "Yesterday" alone, with no date suffix — mobile used to append the
    // full date after those labels ("Today, 12 August 2026"), which web
    // never does.
    String label;
    if (schoolDate.year == now.year &&
        schoolDate.month == now.month &&
        schoolDate.day == now.day) {
      label = 'Today';
    } else if (schoolDate.year == now.year &&
        schoolDate.month == now.month &&
        schoolDate.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label =
          "${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: AppColors.messagingChipBgPlum,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomTextWidget(
        text: label,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        applyLetterSpacing: false,
      ),
    );
  }

  /// Builds a single interactive chip that drives [tabIndex] in
  /// [_tabController]. The chip highlights when that tab is active and shows
  /// a lock icon when [isPrivate] is true (mirrors the old _buildTab lock).
  Widget _buildTabChip({
    required String label,
    required int tabIndex,
    required Color color,
    required bool isPrivate,
  }) {
    final isSelected = (_tabController?.index ?? 0) == tabIndex;
    return GestureDetector(
      onTap: () {
        if (_tabController?.index != tabIndex) {
          _tabController?.animateTo(tabIndex);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.size14.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.messagingOnAccent : color,
              ),
            ),
            if (isPrivate) ...[
              const SizedBox(width: AppSizes.xxs),
              Icon(
                Icons.visibility_off,
                size: 12,
                color: isSelected ? AppColors.messagingOnAccent : AppColors.messagingNotificationDot,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Avatar for [code] — the only thing the receipt/reaction row itself
  /// doesn't carry. A dual-role account's two participant rows share the
  /// same photo in practice, so an unqualified first match is fine here;
  /// name and role come straight off the row (see [_toInfoRecipient] /
  /// [_showReactionInfoDialog]) rather than being guessed from participants.
  String? _avatarForCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return _participants
        .where((p) => p.userCode == code)
        .firstOrNull
        ?.avatarUrl;
  }

  MessageInfoRecipient _toInfoRecipient(
    RecipientStatus r, {
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    final code = r.userId;
    final isMe = code != null && code.isNotEmpty && code == _currentUserCode;
    final name = r.name.trim().isNotEmpty
        ? r.name.trim()
        : (isMe ? 'You' : 'Participant');
    return MessageInfoRecipient(
      name: name,
      role: r.role,
      avatarSource: _avatarForCode(code),
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  void _showReactionInfoDialog(BuildContext context, Message message) {
    final people = message.reactions.map((r) {
      final code = r.userCode;
      final isMe = code == _currentUserCode;
      // "You" only when this reaction was placed under the SAME persona
      // this screen is currently viewing as — a dual-role account (e.g.
      // guardian + admin) reacting under its OTHER persona isn't "you" in
      // the sense this dialog means, even though it's the same account.
      final roleMatchesCurrentPersona = r.role == null || r.role!.trim().isEmpty
          ? true
          : (ParticipantRole.fromApiString(r.role!) ==
                    ParticipantRole.parent) ==
                widget.isGuardian;
      final showAsYou = isMe && roleMatchesCurrentPersona;

      String name;
      if (showAsYou) {
        name = 'You';
      } else if (r.userName?.trim().isNotEmpty == true) {
        name = r.userName!.trim();
      } else {
        // Same account, different persona than the one being viewed — we
        // know the EXACT role from r.role (not a guess), so look up that
        // specific persona's participant row instead of a generic label.
        final roleMatch = _participants
            .where(
              (p) =>
                  p.userCode == code &&
                  r.role != null &&
                  ParticipantRole.fromApiString(p.role) ==
                      ParticipantRole.fromApiString(r.role!),
            )
            .firstOrNull;
        name = roleMatch?.userName.trim().isNotEmpty == true
            ? roleMatch!.userName.trim()
            : 'Participant';
      }

      return ReactionPerson(
        emoji: r.emoji,
        name: name,
        role: r.role,
        avatarSource: _avatarForCode(code),
      );
    }).toList();

    ReactionInfoDialog.show(context, reactions: people);
  }

  void _showMessageStatusDialog(BuildContext context, Message message) {
    // Fetch fresh from the dedicated per-message receipts endpoint — the
    // message's own embedded receipts field is a lighter shape that
    // doesn't reliably carry userName/role. Capture the cubit before
    // entering the dialog builder, same reasoning as _showEmojiPicker.
    final cubit = context.read<CommunicationCubit>();
    Future<List<MessageInfoRecipient>> fetchRecipients() async {
      final receipts = await cubit.fetchMessageReceipts(message.code);
      // Rows are already mutually exclusive per-row (see
      // MessageModel._parseRecipientStatuses) — a dual-role account can
      // legitimately appear in BOTH lists at once under its two different
      // personas (e.g. delivered-only as Admin, separately read as
      // Guardian), so no further cross-row dedup by userCode belongs here.
      return [
        for (final r in receipts.readBy)
          _toInfoRecipient(r, readAt: r.timestamp),
        for (final r in receipts.deliveredTo)
          _toInfoRecipient(r, deliveredAt: r.timestamp),
      ];
    }

    MessageInfoDialog.show(
      context,
      messageText: message.text,
      recipientsFuture: fetchRecipients(),
    );
  }
}
