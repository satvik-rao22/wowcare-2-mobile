import 'dart:async';

import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/role_aware_ownership.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/parent_participant_chips.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import '../../../../../../domain/features/communication/entities/conversation.dart';
import '../../../../../../domain/features/communication/entities/message.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_scroll_behavior.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/loading_older_indicator.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/new_messages_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import '../widgets/thread_message_tile.dart';
import '../../../cubit/private_mode_toggle_cubit.dart';
import '../../../cubit/private_mode_toggle_state.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/room_chat_privacy_helper.dart';
import '../../../../../../domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import '../../../../../../domain/features/communication/usecases/get_conversation_entity_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/participant_mapper.dart';
import 'package:wowcare/core/util/server_time_service.dart';

class ParentMessagingThread extends StatefulWidget {
  const ParentMessagingThread({
    super.key,
    required this.parentInfo,
    this.showOwnScaffold = true,
    this.isGuardian = true,
    this.conversationType = ConversationType.roomChat,
    this.onRefreshConversationList,
  });
  final Map<String, dynamic> parentInfo;

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
  bool _isPositionedAtBottom = false;

  late final ReactionsController _reactionsController;
  Message? _quotedMessage = null;
  String? _quotedMessageId;
  List<ChatAttachment> _pendingAttachments = [];
  String? _currentUserCode;
  String? _currentSender;
  Message? _editingMessage;
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoadingOlder = false;
  static const double _loadOlderScrollThreshold = 200.0;

  /// Overrides `widget.parentInfo['participants']` once a fresh fetch
  /// completes — the participant list passed in via `parentInfo` is
  /// whatever was last loaded into the inbox (potentially stale: classroom
  /// reassignments, new guardians/admins, or removals that happened after
  /// that list was fetched). Null until the refresh below finishes, at
  /// which point [_participants] prefers this over the widget input.
  List<ConversationParticipant>? _refreshedParticipants;

  /// Created once [_currentUserCode] resolves, scoped to this thread's
  /// lifetime — manages this guardian's own Private Mode toggle (PATCH to
  /// the same backend resource the v2 Admin Chat toggle already uses).
  PrivateModeToggleCubit? _privateModeToggleCubit;

  bool get _privateModeActive =>
      widget.parentInfo['privateModeActive'] as bool? ?? false;

  String? get _privateModeActivatedBy =>
      widget.parentInfo['privateModeActivatedBy'] as String?;

  Map<String, String> get _guardianMap =>
      (widget.parentInfo['guardianMap'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, value.toString()));

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

    _tabController?.addListener(() {
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
        setState(() {
          _currentSender = authState.loginResponse.displayName.isNotEmpty
              ? authState.loginResponse.displayName
              : authState.loginResponse.userCode;
        });
      }
      // senderUserCode from the backend is the USR-/STF-... userCode, not the
      // JWT sub UUID. Always compare against userCode.
      final storage = serviceLocator<StorageService>();
      final storedUserCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();
      final authUserCode = authState is AuthLoaded
          ? authState.loginResponse.userCode
          : null;
      final currentUserId = (authUserCode?.isNotEmpty ?? false)
          ? authUserCode
          : (storedUserCode.isNotEmpty ? storedUserCode : null);
      if (!mounted) return;
      setState(() {
        _currentUserCode = currentUserId;
        if (widget.isGuardian) {
          // No local/cached seed for isEnabled or activatedBy — starts
          // unset (off, unknown activator) and is populated exclusively
          // from the API fetch right below, never from
          // `widget.parentInfo`/participant data computed elsewhere. That
          // local data is exactly what was causing the toggle to show a
          // stale value until some later realtime event happened to
          // correct it.
          _privateModeToggleCubit = PrivateModeToggleCubit(
            togglePrivateModeUseCase: TogglePrivateModeUseCase(
              serviceLocator(),
            ),
            conversationCode: widget.parentInfo['code'] as String,
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
      });
      final convCode = widget.parentInfo['code'] as String;
      await context.read<CommunicationCubit>().loadMessages(
        convCode,
        currentUserId: currentUserId,
      );
      if (!mounted) return;
      // Clear unread count for this conversation now that the user is viewing it.
      unawaited(
        context.read<CommunicationCubit>().markConversationRead(convCode),
      );
      // Realtime listener starts only after the API/Isar history has
      // loaded — Firestore only ever applies deltas on top of it.
      context.read<CommunicationCubit>().startWatchingThread(
        convCode,
        organizationCode: widget.parentInfo['organizationCode'] as String?,
        schoolCode: widget.parentInfo['schoolCode'] as String?,
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
          setState(() => _isPositionedAtBottom = true);
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
    final threadId = widget.parentInfo['code'] as String;
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
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
        widget.parentInfo['code'] as String,
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
    final code = widget.parentInfo['code'] as String? ?? '';
    if (code.isEmpty) return;
    final result = await serviceLocator<ConversationEntityRepository>()
        .getConversation(code);
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
      final threadId = widget.parentInfo['code'] as String;
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
    final text = _controller.text.trim();
    if (_editingMessage != null) {
      if (text.isNotEmpty && text != _editingMessage!.text) {
        context.read<CommunicationCubit>().editMessage(
          widget.parentInfo['code'] as String,
          _editingMessage!.code,
          text,
        );
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Message updated successfully',
          isSuccess: true,
        );
      }
      setState(() {
        _editingMessage = null;
        _controller.clear();
      });
      return;
    }

    final hasText = text.isNotEmpty;
    final hasAttachments = _pendingAttachments.isNotEmpty;

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
      (widget.parentInfo['staffList'] as List<dynamic>? ?? []).cast<String>(),
    );

    if (!myPrivateModeEnabled) {
      receivers.addAll(
        (widget.parentInfo['parents'] as List<dynamic>? ?? []).cast<String>(),
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
      widget.parentInfo['code'] as String,
      text,
      attachments: List.from(_pendingAttachments),
      quotedMessageId: _quotedMessageId,
      senderName: senderName,
      senderUserCode: _currentUserCode,
      receivers: receivers,
      isPrivate: privateParentUserCode != null,
      privateParentUserCode: privateParentUserCode,
    );

    setState(() {
      _controller.clear();
      _pendingAttachments.clear();
      _quotedMessage = null;
      _quotedMessageId = null;
    });
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
    final convCode = widget.parentInfo['code'] as String;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            color: Colors.white,
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
      widget.parentInfo['code'] as String,
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
    setState(() {
      _editingMessage = message;
      _controller.text = MessageContentProcessor.stripHtmlTags(message.text);
    });
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
    final convCode = widget.parentInfo['code'] as String;
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
          visible: _isPositionedAtBottom,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: ListView.builder(
            controller: controller,
            // A handful of messages don't fill the viewport, and without
            // this the list isn't scrollable at all — so pull-to-refresh
            // never triggers regardless of message count.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                highlightColor: Colors.green.withValues(alpha: 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDateHeader)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildDateChip(message.time),
                        ),
                      ),
                    if (showDateHeader) const SizedBox(height: 10),
                    SizedBox(height: isGrouped ? 2.0 : 8.0),
                    ThreadMessageTile(
                      isGuardian: widget.isGuardian,
                      threadId: widget.parentInfo['code'] as String,
                      messageCode: message.code,
                      quotedMessageId: message.quotedMessageId,
                      onDeleteAttachment: (attachment) {
                        if (attachment.attachmentId != null) {
                          context.read<CommunicationCubit>().deleteAttachment(
                            widget.parentInfo['code'] as String,
                            attachment.attachmentId!,
                          );
                        }
                      },
                      onRetry: (msg) =>
                          context.read<CommunicationCubit>().retrySendMessage(
                            widget.parentInfo['code'] as String,
                            msg,
                          ),
                      currentUserCode: _currentUserCode,
                      reactionsController: _reactionsController,
                      isParentMessaging: true,
                      participants: _participants,
                      senderIsOrgSide: _isOrgSideSender(message),
                      viewerIsOrgSide: !widget.isGuardian,
                      onReply: message.isDeleted
                          ? null
                          : () {
                              setState(() {
                                _quotedMessageId = message.id;
                                _quotedMessage = message;
                              });
                            },
                      onReplyFromMenu: message.isDeleted
                          ? null
                          : () {
                              setState(() {
                                _quotedMessageId = message.id;
                                _quotedMessage = message;
                              });
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
                            widget.parentInfo['code'] as String,
                            message.code,
                            emoji,
                            currentUserCode: _currentUserCode,
                          );
                        } else {
                          context.read<CommunicationCubit>().addReaction(
                            widget.parentInfo['code'] as String,
                            message.code,
                            emoji,
                            currentUserCode: _currentUserCode,
                          );
                        }
                      },
                      onRemoveReaction: (emoji) {
                        context.read<CommunicationCubit>().removeReaction(
                          widget.parentInfo['code'] as String,
                          message.code,
                          emoji,
                          currentUserCode: _currentUserCode,
                        );
                      },
                      onReactionTap: () => _showEmojiPicker(context, message),
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
        if (!_isPositionedAtBottom)
          const Positioned.fill(child: ChatThreadShimmer()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
        final _groupMessages = _messages.where((m) => !m.isPrivate).toList();
        // Derived flags used by the full layout to decide what to show in the
        // message area — the header and composer are ALWAYS rendered so the
        // screen doesn't re-layout when messages arrive.
        final isLoadingMessages =
            state is CommunicationLoading && _messages.isEmpty;
        final hasError = state is CommunicationError && _messages.isEmpty;
        final isEmpty = state is CommunicationLoaded && _messages.isEmpty;
        // Resolved once here so the inline conditionals below can reference it
        // without a cast (Dart doesn't narrow through a boolean variable).
        final errorMessage = state is CommunicationError ? state.message : '';
        final threadBody = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF4F7FD),
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
                                                controller: _groupController,
                                                scrollBehavior:
                                                    _groupScrollBehavior,
                                                state: state,
                                                isLoading: isLoadingMessages,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Tab 1: first guardian's private thread.
                                        if (_guardianEntries.isNotEmpty)
                                          Stack(
                                            children: [
                                              ListView.builder(
                                                controller: _parent1Controller,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12,
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
                                                  final messageId = message.id;
                                                  //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                                  // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                                  // final key = keyMap.putIfAbsent(
                                                  //   messageId,
                                                  //   () => GlobalKey(),
                                                  // );
                                                  bool showDateHeader = false;
                                                  final prevListIndex =
                                                      _parent1Messages.length -
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
                                                            _prevDate.year ||
                                                        _currDate.month !=
                                                            _prevDate.month ||
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
                                                    key: ValueKey(messageId),
                                                    controller:
                                                        _parent1Controller,
                                                    index: index,
                                                    highlightColor: Colors.green
                                                        .withValues(alpha: 0.7),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (showDateHeader)
                                                          Center(
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
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
                                                          isGuardian:
                                                              widget.isGuardian,
                                                          threadId:
                                                              widget.parentInfo['code']
                                                                  as String,
                                                          messageCode:
                                                              message.code,
                                                          quotedMessageId: message
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                widget.parentInfo['code']
                                                                    as String,
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
                                                          onReply:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onReplyFromMenu:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onCopy:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
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
                                                                        'Message copied successfully',
                                                                    isSuccess:
                                                                        true,
                                                                  );
                                                                },
                                                          onEdit:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _startEditing(
                                                                      message,
                                                                    ),
                                                          onDelete:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                          onInfo:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _showMessageStatusDialog(
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                  widget.parentInfo['code']
                                                                      as String,
                                                                  message.code,
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
                                                          isGrouped: isGrouped,
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
                                                controller: _parent2Controller,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12,
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
                                                  final messageId = message.id;

                                                  bool showDateHeader = false;
                                                  final prevListIndex =
                                                      _parent2Messages.length -
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
                                                            _prevDate.year ||
                                                        _currDate.month !=
                                                            _prevDate.month ||
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
                                                    key: ValueKey(messageId),
                                                    controller:
                                                        _parent2Controller,
                                                    index: index,
                                                    highlightColor: Colors.green
                                                        .withValues(alpha: 0.7),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (showDateHeader)
                                                          Center(
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
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
                                                          isGuardian:
                                                              widget.isGuardian,
                                                          threadId:
                                                              widget.parentInfo['code']
                                                                  as String,
                                                          messageCode:
                                                              message.code,
                                                          quotedMessageId: message
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                widget.parentInfo['code']
                                                                    as String,
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
                                                          onReply:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onReplyFromMenu:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onCopy:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
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
                                                                        'Message copied successfully',
                                                                    isSuccess:
                                                                        true,
                                                                  );
                                                                },
                                                          onEdit:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _startEditing(
                                                                      message,
                                                                    ),
                                                          onDelete:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                          onInfo:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _showMessageStatusDialog(
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                  widget.parentInfo['code']
                                                                      as String,
                                                                  message.code,
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
                                                          isGrouped: isGrouped,
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
                                          _buildEmptyConversationState(context)
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
                                                      horizontal: 8,
                                                      vertical: 12,
                                                    ),
                                                reverse: true,
                                                itemCount: _messages.length,
                                                itemBuilder: (context, index) {
                                                  final message =
                                                      _messages[_messages
                                                              .length -
                                                          1 -
                                                          index];
                                                  final messageId = message.id;
                                                  bool showDateHeader = false;
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
                                                            _prevDate.year ||
                                                        _currDate.month !=
                                                            _prevDate.month ||
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
                                                    key: ValueKey(messageId),
                                                    controller:
                                                        _getActiveScrollController(),
                                                    index: index,
                                                    highlightColor: Colors.green
                                                        .withValues(alpha: 0.7),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (showDateHeader)
                                                          Center(
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
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
                                                          isGuardian:
                                                              widget.isGuardian,
                                                          threadId:
                                                              widget.parentInfo['code']
                                                                  as String,
                                                          messageCode:
                                                              message.code,
                                                          quotedMessageId: message
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                widget.parentInfo['code']
                                                                    as String,
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
                                                          onReply:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onReplyFromMenu:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
                                                                  setState(() {
                                                                    _quotedMessageId =
                                                                        message
                                                                            .id;
                                                                    _quotedMessage =
                                                                        message;
                                                                  });
                                                                },
                                                          onCopy:
                                                              message.isDeleted
                                                              ? null
                                                              : () {
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
                                                                        'Message copied successfully',
                                                                    isSuccess:
                                                                        true,
                                                                  );
                                                                },
                                                          onEdit:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _startEditing(
                                                                      message,
                                                                    ),
                                                          onDelete:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _deleteMessageWithFeedback(
                                                                      message
                                                                          .code,
                                                                    ),
                                                          onInfo:
                                                              message.isDeleted
                                                              ? null
                                                              : () =>
                                                                    _showMessageStatusDialog(
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                                  widget.parentInfo['code']
                                                                      as String,
                                                                  message.code,
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
                                                          isGrouped: isGrouped,
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
                      const SizedBox(width: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: SingleChildScrollView(
                          reverse: true, // new messages appear at bottom
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: ChatInputBar(
                              controller: _controller,
                              focusNode: _inputFocusNode,
                              onSend: _sendMessage,
                              onAttachmentTap: _showAttachmentSheet,
                              isSending: state is CommunicationSending,
                              showCharCounter: true,
                              pendingAttachments: _pendingAttachments,
                              quotedMessage: _quotedMessage,
                              onCancelQuote: () => setState(() {
                                _quotedMessage = null;
                                _quotedMessageId = null;
                              }),
                              onRemoveAttachment: (i) => setState(() {
                                _pendingAttachments.removeAt(i);
                              }),
                              editingMessage: _editingMessage,
                              onCancelEdit: () => setState(() {
                                _editingMessage = null;
                                _controller.clear();
                              }),
                            ),
                          ),
                        ),
                      ),

                      // SizedBox(
                      //   width: MediaQuery.of(context).size.width * 0.35,
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       borderRadius: BorderRadius.circular(12),
                      //       color: Colors.white,
                      //     ),
                      //     child: Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      //       child: _buildMessageInput(),
                      //     ),
                      //   ),// 35% is usually good balance
                      // )
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
                            color: const Color(0xFFF4F7FD),
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
                                                          horizontal: 8,
                                                          vertical: 12,
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
                                                      //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                                      // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                                      // final key = keyMap.putIfAbsent(
                                                      //   messageId,
                                                      //   () => GlobalKey(),
                                                      // );
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

                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo['code']
                                                                      as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      setState(() {
                                                                        _quotedMessageId =
                                                                            message.id;
                                                                        _quotedMessage =
                                                                            message;
                                                                      });
                                                                    },
                                                              onReplyFromMenu: () {
                                                                setState(() {
                                                                  _quotedMessageId =
                                                                      message
                                                                          .id;
                                                                  _quotedMessage =
                                                                      message;
                                                                });
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
                                                                setState(() {
                                                                  _editingMessage =
                                                                      message;
                                                                  _controller
                                                                          .text =
                                                                      MessageContentProcessor.stripHtmlTags(
                                                                        message
                                                                            .text,
                                                                      );
                                                                  _inputFocusNode
                                                                      .requestFocus();
                                                                });
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
                                                                  (quoteId) =>
                                                                      _scrollToMessage(
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                      widget.parentInfo['code']
                                                                          as String,
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
                                                          horizontal: 8,
                                                          vertical: 12,
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
                                                      //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                                      // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                                      // final key = keyMap.putIfAbsent(
                                                      //   messageId,
                                                      //   () => GlobalKey(),
                                                      // );
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

                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo['code']
                                                                      as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      setState(() {
                                                                        _quotedMessageId =
                                                                            message.id;
                                                                        _quotedMessage =
                                                                            message;
                                                                      });
                                                                    },
                                                              onReplyFromMenu: () {
                                                                setState(() {
                                                                  _quotedMessageId =
                                                                      message
                                                                          .id;
                                                                  _quotedMessage =
                                                                      message;
                                                                });
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
                                                                setState(() {
                                                                  _editingMessage =
                                                                      message;
                                                                  _controller
                                                                          .text =
                                                                      MessageContentProcessor.stripHtmlTags(
                                                                        message
                                                                            .text,
                                                                      );
                                                                  _inputFocusNode
                                                                      .requestFocus();
                                                                });
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
                                                                  (quoteId) =>
                                                                      _scrollToMessage(
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                      widget.parentInfo['code']
                                                                          as String,
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
                                                          horizontal: 8,
                                                          vertical: 12,
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
                                                      //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                                      // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                                      // final key = keyMap.putIfAbsent(
                                                      //   messageId,
                                                      //   () => GlobalKey(),
                                                      // );
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

                                                            ThreadMessageTile(
                                                              isGuardian: widget
                                                                  .isGuardian,
                                                              threadId:
                                                                  widget.parentInfo['code']
                                                                      as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                    widget.parentInfo['code']
                                                                        as String,
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
                                                              onReply:
                                                                  message
                                                                      .isDeleted
                                                                  ? null
                                                                  : () {
                                                                      setState(() {
                                                                        _quotedMessageId =
                                                                            message.id;
                                                                        _quotedMessage =
                                                                            message;
                                                                      });
                                                                    },
                                                              onReplyFromMenu: () {
                                                                setState(() {
                                                                  _quotedMessageId =
                                                                      message
                                                                          .id;
                                                                  _quotedMessage =
                                                                      message;
                                                                });
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
                                                                setState(() {
                                                                  _editingMessage =
                                                                      message;
                                                                  _controller
                                                                          .text =
                                                                      MessageContentProcessor.stripHtmlTags(
                                                                        message
                                                                            .text,
                                                                      );
                                                                  _inputFocusNode
                                                                      .requestFocus();
                                                                });
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
                                                                  (quoteId) =>
                                                                      _scrollToMessage(
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                        widget.parentInfo['code']
                                                                            as String,
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
                                                                      widget.parentInfo['code']
                                                                          as String,
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SafeArea(
                        top: false,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: ChatInputBar(
                            controller: _controller,
                            focusNode: _inputFocusNode,
                            onSend: _sendMessage,
                            onAttachmentTap: _showAttachmentSheet,
                            showCharCounter: true,
                            pendingAttachments: _pendingAttachments,
                            quotedMessage: _quotedMessage,
                            onCancelQuote: () => setState(() {
                              _quotedMessage = null;
                              _quotedMessageId = null;
                            }),
                            onRemoveAttachment: (i) => setState(() {
                              _pendingAttachments.removeAt(i);
                            }),
                            editingMessage: _editingMessage,
                            onCancelEdit: () => setState(() {
                              _editingMessage = null;
                              _controller.clear();
                            }),
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
  }

  /// Shown when the thread has loaded successfully but has no messages yet —
  /// the input bar stays usable so the user can start the conversation,
  /// unlike the loading/error states which replace the whole screen.
  Widget _buildEmptyConversationState(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
                            const SizedBox(height: 12),
                            const CustomTextWidget(
                              text: 'No messages yet',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustomTextWidget(
                              text: 'Say hello to start the conversation',
                              fontSize: 13,
                              fontColor: Colors.grey[600],
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnauthorized
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.error_outline_rounded,
              size: 48,
              color: isUnauthorized ? Colors.grey : Colors.redAccent,
            ),
            const SizedBox(height: 12),
            CustomTextWidget(
              text: isUnauthorized
                  ? 'This chat hasn\'t been created yet'
                  : 'Unable to load messages',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 6),
            CustomTextWidget(
              text: isUnauthorized
                  ? 'Go back and start a new conversation.'
                  : message,
              fontSize: 13,
              fontColor: Colors.grey[600],
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (isUnauthorized) {
                  Navigator.of(context).pop();
                  return;
                }
                final convCode = widget.parentInfo['code'] as String;
                context.read<CommunicationCubit>().loadMessages(
                  convCode,
                  currentUserId: _currentUserCode,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: CustomTextWidget(
                  text: isUnauthorized ? 'Go back' : 'Retry',
                  fontColor: Colors.white,
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
    if (_refreshedParticipants != null) return _refreshedParticipants!;
    final raw = widget.parentInfo['participants'];
    if (raw is List) {
      return raw.whereType<ConversationParticipant>().toList();
    }
    return [];
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

  /// Fetches the current conversation fresh from the backend and replaces
  /// [_refreshedParticipants] with whatever it actually returns — the
  /// `participants` the screen was opened with came from the inbox list,
  /// which can be stale relative to classroom/guardian/admin changes that
  /// happened since that list was last loaded. Best-effort: a failure here
  /// just means the screen keeps using the (possibly stale) data it already
  /// had, same as before this existed.
  Future<void> _refreshParticipants(String conversationCode) async {
    final result = await serviceLocator<GetConversationEntityUseCase>().call(
      conversationCode,
    );
    if (!mounted) return;
    result.fold(
      (_) {
        // Stay on whatever participants we already have — the thread is
        // still usable, just potentially stale until the next refresh.
      },
      (conversation) {
        setState(() {
          _refreshedParticipants = legacyParticipantsFromEntities(
            conversation.participants,
          );
        });
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
      _participants.map((p) {
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
    final studentName = widget.parentInfo['name'] as String? ?? '';
    final avatarUuid = widget.parentInfo['avatar'] as String?;
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
        setState(() {
          _pendingAttachments = [..._pendingAttachments, ...attachments];
        });
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
    );
  }

  Widget _buildParticipantHeader() {
    final participants = _participants;
    final title = widget.parentInfo['name'] as String? ?? '';
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Avatar + Title + Info + Private Mode Toggle (Guardian only)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                // Back arrow — hidden for guardian persona (PRD requirement)
                if (!widget.isGuardian)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                if (!widget.isGuardian) const SizedBox(width: 10),
                DocumentImageWidget(
                  fileUuid: '',
                  imageUrl:
                      (widget.parentInfo['avatar'] as String? ?? '').startsWith(
                        'http',
                      )
                      ? widget.parentInfo['avatar'] as String?
                      : null,
                  mediaAssetCode:
                      (widget.parentInfo['avatar'] as String? ?? '')
                              .isNotEmpty &&
                          !(widget.parentInfo['avatar'] as String? ?? '')
                              .startsWith('http')
                      ? widget.parentInfo['avatar'] as String?
                      : null,
                  name: title,
                  size: 34,
                ),
                const SizedBox(width: 10),
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
                          '$count participant${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF636E72),
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
                                  ? 'Only the guardian who turned Private Mode on can turn it off.'
                                  : toggleState.isEnabled
                                  ? 'Private: Messages visible to staff only'
                                  : 'Private: OFF - Messages visible to all',
                              child: CustomToggle(
                                label: 'Private',
                                isToggled: toggleState.isEnabled,
                                onToggle: (value) {
                                  context
                                      .read<PrivateModeToggleCubit>()
                                      .toggle();
                                },
                                labelOnLeftSide: true,
                                labelStyle: TextStyle(
                                  color: toggleState.isEnabled
                                      ? const Color(0xFFE63946)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                enabled: canOperate,
                              ),
                            );
                          },
                        ),
                  ),
                const SizedBox(width: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE8B3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Color(0xFFC9A000),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              activatorName == null
                                  ? 'Private'
                                  : 'Private by $activatorName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFC9A000),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                height: 28,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTabChip(
                      label: 'Group Chat',
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
                          color: const Color(0xFF00B4DB),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    String label;
    if (schoolDate.year == now.year &&
        schoolDate.month == now.month &&
        schoolDate.day == now.day) {
      label =
          "Today, ${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    } else if (schoolDate.year == now.year &&
        schoolDate.month == now.month &&
        schoolDate.day == now.day - 1) {
      label =
          "Yesterday, ${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    } else {
      label =
          "${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1A573353),
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
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (isPrivate) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.visibility_off,
                size: 12,
                color: isSelected ? Colors.white : Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Resolves a receipt to a display name + role + avatar. Realtime receipts
  /// carry an empty [RecipientStatus.name] (no display name at that layer),
  /// so fall back to the conversation participant list keyed by user code.
  ({String name, String? role, String? avatarUrl}) _resolveRecipientInfo(
    RecipientStatus r,
  ) {
    final code = r.userId;
    if (code != null && code.isNotEmpty) {
      final match = _participants.where((p) => p.userCode == code).firstOrNull;
      if (match != null) {
        final name = match.userName.trim().isNotEmpty
            ? match.userName.trim()
            : (code == _currentUserCode ? 'You' : 'Participant');
        return (name: name, role: match.role, avatarUrl: match.avatarUrl);
      }
      if (code == _currentUserCode) {
        return (name: 'You', role: null, avatarUrl: null);
      }
    }
    return (
      name: r.name.trim().isNotEmpty ? r.name.trim() : 'Participant',
      role: null,
      avatarUrl: null,
    );
  }

  MessageInfoRecipient _toInfoRecipient(
    RecipientStatus r, {
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    final info = _resolveRecipientInfo(r);
    return MessageInfoRecipient(
      name: info.name,
      role: info.role,
      avatarSource: info.avatarUrl,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  void _showMessageStatusDialog(BuildContext context, Message message) {
    final readCodes = message.readBy
        .map((r) => r.userId)
        .whereType<String>()
        .toSet();
    final recipients = <MessageInfoRecipient>[
      for (final r in message.readBy)
        _toInfoRecipient(r, readAt: r.timestamp),
      for (final r in message.deliveredTo)
        if (r.userId == null || !readCodes.contains(r.userId))
          _toInfoRecipient(r, deliveredAt: r.timestamp),
    ];

    MessageInfoDialog.show(
      context,
      messageText: message.text,
      recipients: recipients,
    );
  }
}
