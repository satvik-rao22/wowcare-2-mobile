import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/usecases/get_classroom_roster_present_user_codes_usecase.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_scroll_behavior.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity_display.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/search_messages_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/notifications/cubit/push_notification_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/reaction_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/cubit/private_mode_toggle_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/private_mode_toggle_state.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/room_chat_privacy_helper.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/message_entity_mapper.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/entity_message_tile.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/loading_older_indicator.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/new_messages_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import '../../../../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/server_time_service.dart';

/// Full-screen conversation thread for v2 conversations (STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT).
class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({
    super.key,
    required this.conversation,

    /// When false the widget renders only its body (no GlobalScaffold / nav
    /// bar). Use this to embed the thread inline inside a parent screen.
    this.showOwnScaffold = true,

    /// When true a Private Mode toggle is shown at the top-right of the
    /// participant header. Only meaningful for the parent persona.
    this.showPrivateModeToggle = false,

    /// When true the [conversation] is a placeholder that doesn't exist on the
    /// server yet (e.g. a classroom chat never used). The thread shows the
    /// composer over an empty list, and the conversation is created lazily on
    /// the first send via [onResolveConversation] — mirroring the web client.
    this.isDraft = false,

    /// Creates/resolves the real conversation for a draft thread on first send.
    /// Required when [isDraft] is true. Returns the real conversation, or null
    /// on failure.
    this.onResolveConversation,
  });

  final ConversationEntity conversation;
  final bool showOwnScaffold;
  final bool showPrivateModeToggle;
  final bool isDraft;
  final Future<ConversationEntity?> Function()? onResolveConversation;

  @override
  State<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final ConversationThreadCubit _cubit;
  final HtmlAwareTextController _inputController = HtmlAwareTextController();

  /// The conversation actually backing this thread. Starts as
  /// [widget.conversation] but switches to the cubit's resolved conversation
  /// the moment a draft (e.g. a brand-new classroom chat) is created on first
  /// send — so participant-dependent UI (bubble alignment, header roster) uses
  /// the real participants immediately instead of waiting for a refresh/revisit.
  ConversationEntity? _resolvedConversation;

  /// Falls back to [widget.conversation] — always fully populated, since
  /// it's what opened this thread in the first place — whenever
  /// [_resolvedConversation] would otherwise hand the header a blank title.
  /// Pull-to-refresh was observed dropping the header to the generic
  /// placeholder name/logo; whatever transiently produces an
  /// incompletely-populated resolved conversation, the header should never
  /// actually render it over the known-good original.
  ConversationEntity get _conversation {
    final resolved = _resolvedConversation;
    if (resolved != null && resolved.title.trim().isNotEmpty) return resolved;
    return widget.conversation;
  }

  // `AutoScrollController` is required by [ChatScrollBehavior]'s signature,
  // but only plain `ScrollController`/`ScrollPosition` members are used here
  // — `_messageKeys`-based `Scrollable.ensureVisible` (below) remains the
  // mechanism for scroll-to-specific-message.
  final AutoScrollController _scrollController = AutoScrollController();

  /// Keyboard-aware, near-bottom-aware scroll engine — the same utility the
  /// legacy StaffMessagingThread/ParentMessagingThread screens use.
  /// `reverse: true` matches this screen's `ListView(reverse: true)` (index
  /// 0 = newest, resting at `pixels == 0`) — get this flag wrong and every
  /// method below scrolls to the *oldest* message instead of the newest.
  late final ChatScrollBehavior _scrollBehavior = ChatScrollBehavior(
    _scrollController,
    reverse: true,
  );

  double _lastKeyboardInset = 0;

  /// Tracks the latest message's code rather than a raw count — a raw count
  /// can desync across edits/deletes/optimistic-rollbacks (e.g. a reaction
  /// mutation that fails and reverts touches `messages` without changing the
  /// count, but a delete does change it without anything being "new" to
  /// scroll to), silently breaking the "did a new message arrive" check
  /// this drives. Identity comparison is correct regardless of why the
  /// list changed — pagination, edits, and reactions never change the
  /// *latest* message's code, so they never trigger an auto-scroll.
  String? _lastMessageCode;
  bool _initialLoadInFlight = true;
  bool _ownSendPending = false;

  /// False until the very first scroll-to-bottom has actually landed on the
  /// true latest message. The real message list stays hidden behind the
  /// shimmer until this flips, so opening a thread shows the conversation
  /// already sitting at the latest message instead of visibly scrolling
  /// down to it from the top.
  bool _isPositionedAtBottom = false;

  /// Guards against firing more than one `loadOlderMessages` request while
  /// one is already in flight — mirrors the cubit's own guard but avoids
  /// even constructing the call when we already know the answer locally.
  bool _isLoadingOlder = false;
  static const double _loadOlderScrollThreshold = 200.0;

  String _senderCode = '';
  String _senderName = '';
  ParticipantRole _senderRole = ParticipantRole.staff;
  String _organizationCode = '';
  String _schoolCode = '';

  late final ReactionsController _reactionsController;
  MessageEntity? _quotedMessage;
  MessageEntity? _editingMessage;
  final FocusNode _inputFocusNode = FocusNode();

  /// Attachments selected from [MessageAttachmentBottomSheet] but not yet sent.
  List<ChatAttachment> _pendingAttachments = [];

  /// Only non-null when [widget.showPrivateModeToggle] is true.
  PrivateModeToggleCubit? _privateModeToggleCubit;

  // ── Per-parent private chat tabs (staff/admin viewer) ───────────────────
  //
  // Mirrors the legacy v1 stack's `ParentMessagingThread` tab chips (Group
  // Chat + one chip per guardian), previously present only for Room Chat's
  // legacy screen and completely absent here — a staff/admin viewer of THIS
  // (v2) screen had no way to switch to a specific guardian's private
  // thread, and worse, every guardian's private messages were shown
  // unfiltered to every viewer (see [_visibleMessagesForActiveTab]).

  /// Drives which "tab" (Group Chat = 0, guardian N = N) is active. Length
  /// must match [_tabGuardians]`.length + 1` — recreated via
  /// [_syncTabController] whenever that changes (e.g. participants/private
  /// mode state arrive after the conversation resolves).
  TabController? _tabController;

  /// Every active guardian gets their own private tab — a student can have
  /// more than two parents/guardians on the roster (e.g. 4), and each one
  /// needs a way to be shown their own private thread with staff.
  List<ParticipantEntity> get _tabGuardians => _conversation.participants
      .where((p) => p.role == ParticipantRole.parent && p.isActive)
      .toList();

  /// True when staff/admin is viewing a Room Chat/Admin Chat conversation
  /// but every guardian has left/been removed — no one is left on the
  /// parent side to receive a new message. A guardian's OWN thread is
  /// unaffected (their own active status is enforced elsewhere) — this
  /// only gates the staff/admin side. Staff Direct/Classroom Notes never
  /// have guardian participants at all, so they're excluded rather than
  /// always reading as disabled.
  bool get _noActiveGuardian =>
      _senderRole != ParticipantRole.parent &&
      (_conversation.type == ConversationType.adminChat ||
          _conversation.type == ConversationType.roomChat) &&
      _tabGuardians.isEmpty;

  /// True when this Room Chat/Admin Chat conversation's student is no
  /// longer active (withdrawn/inactive) — every side (staff, admin, and
  /// the guardian) loses the ability to send once the student itself is
  /// gone, unlike [_noActiveGuardian] which only blocks the staff/admin
  /// side. Takes priority over [_noActiveGuardian] when composing the
  /// composer's disabled message.
  bool get _studentInactive {
    if (_conversation.type != ConversationType.adminChat &&
        _conversation.type != ConversationType.roomChat) {
      return false;
    }
    // Only INACTIVE (withdrawn) actually blocks sending — UPCOMING is a
    // normal, not-yet-started enrollment state and must behave like ACTIVE
    // here.
    final status = _conversation.studentStatus?.trim().toUpperCase();
    return status == 'INACTIVE';
  }

  /// True when the CURRENT USER's own participant record shows a staff
  /// employment status of INACTIVE — unlike [_studentInactive]/
  /// [_noActiveGuardian] (which gate the OTHER side of the conversation),
  /// this blocks the sender themselves: a since-terminated/deactivated
  /// staff member must not be able to send in ANY conversation type.
  bool get _currentUserInactive {
    ParticipantEntity? self;
    for (final p in _conversation.participants) {
      if (p.userCode == _senderCode) {
        self = p;
        break;
      }
    }
    final status = self?.staffStatus?.trim().toUpperCase();
    return status == 'INACTIVE';
  }

  /// Only staff/admin/director/teacher viewers get tabs — a guardian's own
  /// thread is always just their single (group + own-private) merged view,
  /// same as the legacy screen. Tabs only make sense once private mode is
  /// actually active for at least one guardian; before that there's nothing
  /// to switch between.
  bool get _showChatTabs =>
      _senderRole != ParticipantRole.parent &&
      (_conversation.type == ConversationType.adminChat ||
          _conversation.type == ConversationType.roomChat) &&
      _conversation.hasActivePrivateMode &&
      _tabGuardians.isNotEmpty;

  /// Creates or resizes [_tabController] to match [_showChatTabs]/
  /// [_tabGuardians]. Cheap no-op when the required length hasn't changed
  /// (called every build via [_buildThreadBody]). Preserves the current tab
  /// selection across a resize where possible, otherwise resets to Group
  /// Chat (index 0) rather than an out-of-range index.
  void _syncTabController() {
    final desiredLength = _showChatTabs ? 1 + _tabGuardians.length : 1;
    if (_tabController != null && _tabController!.length == desiredLength) {
      return;
    }
    final previousIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _tabController =
        TabController(
          length: desiredLength,
          vsync: this,
          initialIndex: previousIndex < desiredLength ? previousIndex : 0,
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  /// Which messages are visible right now, given the currently active chat
  /// tab (staff/admin: Group Chat vs. a specific guardian's private
  /// thread), or — for a guardian viewer, who never sees tabs — the
  /// always-on merge of the group thread with just their OWN private
  /// messages. Without this, every guardian's private messages were shown
  /// to every viewer of this screen (staff and other guardians alike) with
  /// no filtering at all.
  List<MessageEntity> _visibleMessagesForActiveTab(
    List<MessageEntity> messages,
  ) {
    if (_senderRole == ParticipantRole.parent) {
      return messages
          .where((m) => !m.isPrivate || m.privateParentUserCode == _senderCode)
          .toList();
    }
    if (!_showChatTabs) {
      return messages.where((m) => !m.isPrivate).toList();
    }
    final activeIndex = _tabController?.index ?? 0;
    if (activeIndex == 0) {
      return messages.where((m) => !m.isPrivate).toList();
    }
    final guardians = _tabGuardians;
    final guardianIndex = activeIndex - 1;
    if (guardianIndex >= guardians.length) {
      return messages.where((m) => !m.isPrivate).toList();
    }
    final guardianCode = guardians[guardianIndex].userCode;
    return messages
        .where((m) => m.isPrivate && m.privateParentUserCode == guardianCode)
        .toList();
  }

  // ── Draft persistence ─────────────────────────────────────────────────────

  /// SharedPreferences key for the per-conversation draft.
  String get _draftStorageKey => 'msg_draft_${widget.conversation.code}';

  // ── Per-message GlobalKeys (scroll-to-original) ───────────────────────────

  /// Maps message code → GlobalKey so [Scrollable.ensureVisible] can jump to
  /// any rendered bubble precisely.
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _keyForMessage(String code) =>
      _messageKeys.putIfAbsent(code, GlobalKey.new);

  // ── Classroom Notes roster ────────────────────────────────────────────────

  /// Present-vs-missing staff for a Classroom Notes chat — see
  /// [GetClassroomRosterPresentUserCodesUseCase]. Null until loaded (or for
  /// any non-classroom-chat conversation, where it's simply never fetched),
  /// in which case the participant header falls back to showing everyone —
  /// same as before this existed.
  Set<String>? _presentUserCodes;

  Future<void> _loadClassroomRosterStatus() async {
    final classroomCode = _conversation.classroomCode?.trim();
    if (classroomCode == null || classroomCode.isEmpty) return;
    final result =
        await serviceLocator<GetClassroomRosterPresentUserCodesUseCase>()(
          classroomCode,
        );
    if (!mounted) return;
    result.fold((_) {}, (codes) => setState(() => _presentUserCodes = codes));
  }

  // ── In-thread search ──────────────────────────────────────────────────────

  late final SearchMessagesUseCase _searchUseCase;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  List<MessageEntity> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    final authState = context.read<AuthCubit>().state;
    final userCodeFromAuth = authState is AuthLoaded
        ? authState.loginResponse.userCode.trim()
        : '';

    _reactionsController = ReactionsController(
      currentUserId: userCodeFromAuth.isNotEmpty ? userCodeFromAuth : 'me',
    );

    _cubit = ConversationThreadCubit(
      conversationCode: widget.conversation.code,
      currentUserCode: userCodeFromAuth,
      // Pass the full conversation so the Firestore message listener uses this
      // conversation's own org/school (not the session's active school) — fixes
      // no-live-messages for Classroom Notes and any cross-school thread.
      conversation: widget.conversation,
      watchMessagesUseCase: serviceLocator(),
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      editMessageUseCase: serviceLocator(),
      deleteMessageUseCase: serviceLocator(),
      deleteAttachmentUseCase: serviceLocator(),
      getMessageReceiptsUseCase: serviceLocator(),
      addReactionUseCase: serviceLocator(),
      removeReactionUseCase: serviceLocator(),
      markConversationReadUseCase: serviceLocator(),
      attachmentUploader: serviceLocator(),
      cacheDraftMessageUseCase: serviceLocator(),
      markDraftMessageFailedUseCase: serviceLocator(),
      getCachedMessagesEntityUseCase: serviceLocator(),
      isDraft: widget.isDraft,
      onResolveConversation: widget.onResolveConversation,
    );
    _searchUseCase = SearchMessagesUseCase(serviceLocator());

    // Pre-set _senderCode synchronously so it matches the cubit's _currentUserCode
    // from the moment the screen is built. _loadSenderInfo will confirm/update it
    // from storage (same value) along with the other sender fields.
    _senderCode = userCodeFromAuth;

    _cubit.startWatchingMessages();
    // Fire an immediate, undebounced mark-read on open — matches Room
    // Chat/Staff Direct (staff_messaging_thread.dart, parent_messaging_thread.dart),
    // which call markConversationRead unconditionally as soon as the thread
    // opens. Without this, Admin Chat only had _scheduleMarkRead's 2s
    // debounce (see ConversationThreadCubit._markReadDebounceDuration),
    // which resets on every Firestore snapshot during that window — so
    // continuous activity right after opening could keep deferring the
    // badge zero well past when Room Chat would've already cleared it.
    unawaited(_cubit.markConversationRead());
    unawaited(_loadSenderInfo());
    unawaited(_loadDraft());

    if (widget.conversation.participants.isEmpty && !widget.isDraft) {
      unawaited(_fetchConversationDetails());
    }

    if (_conversation.type == ConversationType.classroomChat) {
      unawaited(_loadClassroomRosterStatus());
    }

    // Private mode applies to both Room Chat and Admin Chat per spec — this
    // was previously gated to Room Chat only, which meant a guardian could
    // never turn private mode ON for an Admin Chat thread at all, and staff
    // would correspondingly never see any private tabs to switch to there.
    final canShowPrivateToggle =
        widget.showPrivateModeToggle &&
        (_conversation.type == ConversationType.roomChat ||
            _conversation.type == ConversationType.adminChat);

    if (canShowPrivateToggle) {
      // No local/cached seed for isEnabled or activatedBy — starts unset
      // (off, unknown activator) and is populated exclusively from the API
      // fetch below, never from `widget.conversation`. That local data is
      // exactly what was letting the toggle show a stale value until the
      // user's own interaction (or a lucky realtime event) corrected it.
      _privateModeToggleCubit = PrivateModeToggleCubit(
        togglePrivateModeUseCase: TogglePrivateModeUseCase(serviceLocator()),
        conversationCode: widget.conversation.code,
        viewerRole: () => _senderRole == ParticipantRole.parent
            ? RoomChatViewerRole.guardian
            : RoomChatViewerRole.staffOrAdmin,
        currentUserCode: () => _senderCode,
      );
      // Unconditionally fetch this conversation via REST — the previous
      // conditional fetch above only ran when `participants.isEmpty`, which
      // left the toggle with nothing but that removed local seed for a
      // conversation that already had a full participant list.
      unawaited(_fetchConversationDetails());
    }
  }

  Future<void> _fetchConversationDetails() async {
    final result = await serviceLocator<ConversationEntityRepository>()
        .getConversation(widget.conversation.code);
    if (!mounted) return;
    result.fold((_) {}, (conversation) {
      if (conversation.participants.isNotEmpty) {
        setState(() => _resolvedConversation = conversation);
      }
      // Independent of the participants check above — privateModeActive/
      // privateModeActivatedBy are meaningful even when this particular
      // fetch's participant list happens to come back empty.
      _privateModeToggleCubit?.syncFromRemote(
        active: conversation.privateModeActive,
        activatedBy: conversation.privateModeActivatedBy,
      );
    });
  }

  Future<void> _loadSenderInfo() async {
    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final displayName = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    // Prefer the active-persona resolver (activeSchoolRole, falling back to
    // the per-school cached snapshot, then the raw login roles list as a
    // last resort) over reading the raw `roles` list directly. A dual-role
    // account's `roles` string can contain BOTH e.g. "PARENT" and "ADMIN"
    // substrings; matching against it directly could resolve to the WRONG
    // persona (e.g. parent) even while the admin is genuinely viewing Admin
    // Chat as an admin, silently inverting `viewerIsOrgSide` and flipping
    // every message's alignment/colour. See `resolveActiveBackendRole`'s own
    // doc comment — this is the single source of truth every other
    // persona-scoping decision in the app already uses.
    final activeRole = (await resolveActiveBackendRole(
      storage,
    )).trim().toUpperCase();

    if (!mounted) return;
    setState(() {
      _senderCode = userCode;
      _senderName = displayName.isNotEmpty ? displayName : userCode;
      _organizationCode = orgCode;
      _schoolCode = school;
      _senderRole = ParticipantRole.fromApiString(activeRole);
    });
  }

  // ── Draft persistence ─────────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final storage = serviceLocator<StorageService>();
    final draft = await storage.getString(_draftStorageKey);
    if (draft != null && draft.isNotEmpty && mounted) {
      _inputController.text = draft;
      _inputController.selection = TextSelection.collapsed(
        offset: draft.length,
      );
    }
  }

  Future<void> _saveDraft() async {
    final storage = serviceLocator<StorageService>();
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      await storage.remove(_draftStorageKey);
    } else {
      await storage.saveString(_draftStorageKey, text);
    }
  }

  // ── In-thread search ──────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await _searchUseCase(
        conversationCode: widget.conversation.code,
        query: query.trim(),
        limit: 30,
      );
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _isSearching = false),
        (hits) => setState(() {
          _searchResults = hits;
          _isSearching = false;
        }),
      );
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _showSearch = false;
      _searchResults = [];
      _isSearching = false;
    });
    _searchController.clear();
  }

  // ── Scroll to message (GlobalKey-based) ───────────────────────────────────

  void _scrollToMessage(String messageCode) {
    final key = _messageKeys[messageCode];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saveDraft());
    _searchDebounce?.cancel();
    unawaited(_cubit.close());
    _privateModeToggleCubit?.close();
    _tabController?.dispose();
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollBehavior.dispose();
    _scrollController.dispose();
    _reactionsController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ── Pagination trigger ─────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // `reverse: true` — the oldest-history end is `maxScrollExtent`, not 0.
    if (position.maxScrollExtent - position.pixels >
        _loadOlderScrollThreshold) {
      return;
    }
    unawaited(_loadOlderMessages());
  }

  /// Fetches the next older page. No manual scroll-position correction is
  /// needed here (unlike a non-reversed list): because `itemBuilder` maps
  /// `index -> messages[messages.length - 1 - index]`, prepending older
  /// messages to the front of `messages` only adds new, higher indices at
  /// the far end — every currently-visible item keeps the exact index (and
  /// therefore position) it already had.
  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    if (!_cubit.state.hasOlderMessages ||
        _cubit.state.isLoading ||
        _cubit.state.isRefreshing) {
      return;
    }
    _isLoadingOlder = true;
    await _cubit.loadOlderMessages();
    _isLoadingOlder = false;
  }

  // ── Keyboard handling ──────────────────────────────────────────────────────

  /// WhatsApp/Telegram-style keyboard handling: when the keyboard opens,
  /// scroll to the latest message — but only if the user was already near
  /// the bottom, never while they're reading older history. Keyboard close
  /// is intentionally left unhandled — Flutter's default Scaffold inset
  /// behavior already preserves scroll position with no extra code.
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
        _scrollBehavior.onKeyboardOpened();
      }
    });
  }

  // ── Smart auto-scroll ──────────────────────────────────────────────────────

  /// Reacts to the latest message changing identity from any source (initial
  /// load, API refresh, realtime delta, or our own optimistic send): scrolls
  /// to bottom when the user is already there, otherwise surfaces the "new
  /// messages" indicator rather than forcing a jump while they're reading
  /// older history. The initial load is handled explicitly (jump, no
  /// animation) so the thread never opens mid-list.
  void _onMessagesChanged(List<MessageEntity> messages) {
    final latestCode = messages.isNotEmpty ? messages.last.code : null;

    if (_initialLoadInFlight) {
      _lastMessageCode = latestCode;
      _initialLoadInFlight = false;
      if (messages.isNotEmpty) {
        _scrollBehavior.scrollToBottom(
          animate: false,
          onSettled: () {
            if (!mounted) return;
            setState(() => _isPositionedAtBottom = true);
          },
        );
      } else {
        _isPositionedAtBottom = true;
      }
      return;
    }

    final wasOwnSend = _ownSendPending;
    _ownSendPending = false;
    final hasNewLatest = latestCode != null && latestCode != _lastMessageCode;
    _lastMessageCode = latestCode;
    if (!hasNewLatest) return;

    // `_conversation` (participants, privateModeStates) only ever updates
    // when the CONVERSATION CODE changes (draft → real) — see
    // `_syncResolvedConversation` — never when its FIELDS change, because
    // this cubit only watches messages, not the conversation document
    // itself. If someone else turns private mode on (or a new guardian
    // joins) mid-session, `_showChatTabs`/`_visibleMessagesForActiveTab`
    // were left computing against a stale snapshot — a brand-new private
    // message from a guardian would silently vanish (no tab ever appeared
    // to reveal it, and it doesn't pass the stale "not private" filter),
    // looking exactly like "only the previous chat is showing". Refresh the
    // conversation snapshot whenever a genuinely new INCOMING message
    // arrives so tabs/filtering stay in sync with reality.
    if (!wasOwnSend) {
      unawaited(_fetchConversationDetails());
    }

    // Sending always scrolls to bottom, regardless of scroll position.
    // Other growth (realtime/API/pagination) only scrolls when already near
    // bottom — pagination never reaches here at all, since prepending older
    // messages never changes `messages.last`.
    if (wasOwnSend) {
      _scrollBehavior.scrollToBottom();
    } else {
      _scrollBehavior.onIncomingMessage();
    }
  }

  // ── Participants ──────────────────────────────────────────────────────────

  /// Avatar for [code] — the only thing the receipt/reaction row itself
  /// doesn't carry. A dual-role account's two participant rows share the
  /// same photo in practice, so an unqualified first match is fine here;
  /// name and role come straight off the row (see [_showMessageInfoDialog] /
  /// [_showReactionInfoDialog]) rather than being guessed from participants.
  String? _avatarForCode(String code) {
    return _conversation.participants
        .where((p) => p.userCode == code)
        .firstOrNull
        ?.avatarUrl;
  }

  List<ParticipantDisplayData> get _participantData =>
      _conversation.participants.where((p) => p.isActive).map((p) {
        final roleStr = p.role.toApiString().toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
          avatarUrl: p.avatarUrl,
        );
      }).toList();

  void _showParticipantsDialog() {
    ParticipantInfoDialog.show(
      context,
      participants: _participantData,
      studentName: _conversation.title,
    );
  }

  void _showMessageInfoDialog(BuildContext context, MessageEntity msg) {
    MessageInfoRecipient toInfoRecipient(
      ReadReceiptEntity r, {
      DateTime? deliveredAt,
      DateTime? readAt,
    }) {
      return MessageInfoRecipient(
        name: r.userName.isNotEmpty ? r.userName : 'Participant',
        role: r.role,
        avatarSource: _avatarForCode(r.userCode),
        deliveredAt: deliveredAt,
        readAt: readAt,
      );
    }

    // Fetch fresh from the dedicated per-message receipts endpoint — the
    // message's own embedded receipts field is a lighter shape that
    // doesn't reliably carry userName/role.
    Future<List<MessageInfoRecipient>> fetchRecipients() async {
      final receipts = await _cubit.fetchMessageReceipts(msg.code);
      // receipts carries one row per RECIPIENT-PERSONA (a dual-role account
      // — e.g. staff who's also a guardian — gets one row per role, sharing
      // one userCode, each independently delivered/read). Classify each row
      // purely by its OWN isRead — never cross-referenced against other
      // rows for the same userCode, which previously suppressed one
      // persona's receipt whenever the other persona's had already been
      // read.
      return [
        for (final r in receipts)
          if (r.isRead) toInfoRecipient(r, readAt: r.readAt),
        for (final r in receipts)
          if (!r.isRead && r.deliveredAt != null)
            toInfoRecipient(r, deliveredAt: r.deliveredAt),
      ];
    }

    MessageInfoDialog.show(
      context,
      messageText: msg.text,
      recipientsFuture: fetchRecipients(),
    );
  }

  void _showReactionInfoDialog(BuildContext context, MessageEntity msg) {
    final people = msg.reactions.map((r) {
      final code = r.userCode;
      final isMe = code == _senderCode;
      // "You" only when this reaction was placed under the SAME persona
      // this screen is currently viewing as — a dual-role account (e.g.
      // guardian + admin) reacting under its OTHER persona isn't "you" in
      // the sense this dialog means, even though it's the same account.
      final roleMatchesCurrentPersona = r.role == null || r.role!.trim().isEmpty
          ? true
          : ParticipantRole.fromApiString(r.role!) == _senderRole;
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
        final roleMatch = _conversation.participants
            .where(
              (p) =>
                  p.userCode == code &&
                  r.role != null &&
                  p.role == ParticipantRole.fromApiString(r.role!),
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

  // ── Attachment sheet ──────────────────────────────────────────────────────

  void _showAttachmentSheet() {
    unawaited(
      MessageAttachmentBottomSheet.show(
        context,
        onAttachmentsSelected: (attachments) {
          setState(() => _pendingAttachments.addAll(attachments));
        },
        onEmojiSelected: (emoji) {
          final pos = _inputController.selection.isValid
              ? _inputController.selection.baseOffset
              : _inputController.text.length;
          final text = _inputController.text;
          _inputController.value = _inputController.value.copyWith(
            text: text.substring(0, pos) + emoji + text.substring(pos),
            selection: TextSelection.collapsed(offset: pos + emoji.length),
          );
        },
        onViewParticipants: _showParticipantsDialog,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if ((text.isEmpty && _pendingAttachments.isEmpty) || _senderCode.isEmpty) {
      return;
    }

    if (_editingMessage != null) {
      final messageCode = _editingMessage!.code;
      final originalEditMsg = _editingMessage!;

      // Only clear and submit if text actually changed
      if (text != originalEditMsg.text) {
        setState(() {
          _editingMessage = null;
        });
        _inputController.clear();

        await _cubit.editMessage(messageCode: messageCode, newText: text);
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message updated successfully',
            isSuccess: true,
          );
        }
      } else {
        // Text unchanged — just cancel edit
        setState(() {
          _editingMessage = null;
        });
        _inputController.clear();
      }
      return;
    }

    _inputController.clear();
    unawaited(_saveDraft()); // clears the stored draft (text is now empty)
    // Sending always scrolls to bottom regardless of current scroll position
    // — _onMessagesChanged() picks this flag up as soon as the cubit's
    // optimistic message lands in state (before the network call resolves).
    _ownSendPending = true;
    // A COPY, not a reference — `_pendingAttachments` itself is cleared
    // below (synchronously, right after this) so the composer stops showing
    // the picked images immediately. Without `.from(...)` this was just an
    // alias to the same list object, so that clear() also wiped the
    // attachments out from under the send that was about to use them,
    // producing a text-less, attachment-less POST the backend correctly
    // rejected with "Message must contain text or at least one attachment".
    final attachmentsBeingSent = List<ChatAttachment>.from(_pendingAttachments);
    // Captured before the composer is cleared below — _quotedMessage is
    // about to become null.
    final quotedMessageCode = _quotedMessage?.code;
    // A guardian sends private via their own toggle; staff/admin has no such
    // toggle — instead, replying while a specific guardian's tab is active
    // (see [_showChatTabs]/[_buildChatTabChips]) scopes the reply as private
    // to THAT guardian automatically, mirroring the legacy screen's
    // `selectedGuardianUserCode` behaviour. Group Chat (tab 0) never sends
    // private regardless of who's viewing.
    final activeTabIndex = _tabController?.index ?? 0;
    final String? targetGuardianCode = (_showChatTabs && activeTabIndex > 0)
        ? _tabGuardians[activeTabIndex - 1].userCode
        : null;
    final bool isPrivate =
        (widget.showPrivateModeToggle &&
            _privateModeToggleCubit?.state.isEnabled == true) ||
        targetGuardianCode != null;

    // Clear the composer's attachment preview + quote immediately — matches
    // Room Chat (staff_messaging_thread.dart/parent_messaging_thread.dart),
    // which clears synchronously the moment send is tapped rather than
    // waiting for the upload/send to finish. Previously this only cleared
    // AFTER awaiting the full send below, so the picked images stayed
    // visible in the composer for the entire upload — surviving even a
    // refresh/navigate-away-and-back in the meantime. A failed send is
    // retried from the bubble itself (EntityMessageTile's onRetry →
    // ConversationThreadCubit.retrySendMessage), which already carries its
    // own attachments, so there's nothing to "preserve here for retry".
    setState(() {
      _quotedMessage = null;
      _pendingAttachments.clear();
    });

    await _cubit.sendMessage(
      text: text,
      senderCode: _senderCode,
      senderName: _senderName,
      senderRole: _senderRole,
      organizationCode: _organizationCode,
      schoolCode: _schoolCode,
      attachments: attachmentsBeingSent,
      isPrivate: isPrivate,
      threadParentCode: quotedMessageCode,
      privateParentUserCode: targetGuardianCode,
    );
    if (!mounted) return;
    if (_cubit.state.sendError != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: _cubit.state.sendError!,
        isError: true,
      );
    }
  }

  // ── Date chip ─────────────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime date) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(date, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      ServerTimeService.instance.nowUtc(),
      tz,
    );
    const months = [
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
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${d.day} ${months[d.month - 1]} ${d.year}';
    } else if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) {
      return 'Yesterday, ${d.day} ${months[d.month - 1]} ${d.year}';
    }
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final da = SchoolZoneDateTime.dateTimeFromInstantInSchool(a, tz);
    final db = SchoolZoneDateTime.dateTimeFromInstantInSchool(b, tz);
    return da.year != db.year || da.month != db.month || da.day != db.day;
  }

  // ── Role color (matches parent messaging) ────────────────────────────────

  String _roleFallbackName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'GUARDIAN':
        return 'Guardian';
      case 'STAFF':
        return 'Staff';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'GUARDIAN':
        return const Color(0xFF6C63FF);
      case 'STAFF':
        return const Color(0xFF00897B);
      case 'ADMIN':
        return const Color(0xFFE65100);
      default:
        return AppColors.primaryColor;
    }
  }

  // ── Participant header ────────────────────────────────────────────────────

  Widget _buildParticipantHeader() {
    // Only currently-active participants count toward the header's
    // count/chip display — a Past Participant (left or deactivated) is
    // still kept in message-attribution logic elsewhere, but shouldn't
    // clutter this "who's in the conversation right now" summary.
    final participants = _conversation.participants
        .where((p) => p.isActive)
        .toList();
    final title = _conversation.title.isNotEmpty
        ? _conversation.title
        : 'Conversation';
    // 1:1 chats carry no conversation-level avatar — resolve the other participant's photo; group
    // chats use the conversation (student) avatar.
    final headerAvatar = _conversation.displayAvatar(_senderCode);
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DocumentImageWidget(
                disableAttendanceStatusLookup: true,
                // Stable across every BlocConsumer rebuild (pull-to-refresh,
                // new messages, …) so its element — and therefore its
                // internally-resolved photo/initials state — is never torn
                // down and recreated from scratch by an unrelated state
                // change.
                key: ValueKey('thread-header-avatar-${_conversation.code}'),
                fileUuid: '',
                // `avatarUrl` is either a resolved URL or a raw media-asset
                // code depending on which screen started the conversation.
                imageUrl: headerAvatar.startsWith('http') ? headerAvatar : null,
                mediaAssetCode: headerAvatar.startsWith('http')
                    ? null
                    : (headerAvatar.isNotEmpty ? headerAvatar : null),
                studentCode: _conversation.studentCode,
                name: title,
                size: 36,
                fontSize: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      text: title,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
              // Private Mode toggle — Room Chat and Admin Chat.
              if (widget.showPrivateModeToggle &&
                  _privateModeToggleCubit != null &&
                  (_conversation.type == ConversationType.roomChat ||
                      _conversation.type == ConversationType.adminChat))
                BlocConsumer<PrivateModeToggleCubit, PrivateModeToggleState>(
                  bloc: _privateModeToggleCubit,
                  listener: (context, pmState) {
                    if (pmState.errorMessage != null) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: pmState.errorMessage!,
                        isError: true,
                      );
                    }
                    if (pmState.successMessage != null) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: pmState.successMessage!,
                        isSuccess: true,
                      );
                    }
                  },
                  builder: (_, pmState) {
                    // `pmState.activatedBy` is now tracked live by the cubit
                    // itself (see PrivateModeToggleCubit) — this used to be
                    // a screen-local field re-derived here by ASSUMING the
                    // current viewer is the activator whenever isEnabled is
                    // true, which was simply wrong for anyone who didn't
                    // just personally toggle it (e.g. a remote sync from a
                    // DIFFERENT guardian turning it on made every other
                    // guardian's screen think THEY were the activator too).
                    final isActivator =
                        pmState.activatedBy == null ||
                        pmState.activatedBy == _senderCode;
                    final canOperate =
                        !pmState.isLoading &&
                        (isActivator || !pmState.isEnabled);
                    return Tooltip(
                      message: pmState.isEnabled
                          ? (isActivator
                                ? 'Private Mode ON'
                                : 'Private Mode was enabled by another guardian and can only be disabled by that guardian.')
                          : 'Private Mode OFF',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Private Mode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pmState.isEnabled
                                  ? const Color(0xFF6C63FF)
                                  : const Color(0xFFB2BEC3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: pmState.isEnabled,
                            onChanged: canOperate
                                ? (_) => _privateModeToggleCubit!.toggle()
                                : null,
                            activeThumbColor: const Color(0xFF6C63FF),
                            activeTrackColor: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.4),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              Tooltip(
                message: _showSearch ? 'Close search' : 'Search messages',
                child: IconButton(
                  icon: Icon(
                    _showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    if (_showSearch) {
                      _closeSearch();
                    } else {
                      setState(() => _showSearch = true);
                    }
                  },
                ),
              ),
              Tooltip(
                message: 'View Participants',
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: _showParticipantsDialog,
                ),
              ),
            ],
          ),
          // Read-only guardian/participant chips — hidden once the
          // interactive tab chips below are showing, since those already
          // represent every guardian (avatar + name) as a tab; showing both
          // duplicated every guardian's name/avatar twice in a row. Mirrors
          // the legacy Room Chat screen's own either/or between its
          // read-only `ParentParticipantChips` and its interactive tab
          // chips — never both at once.
          if (participants.isNotEmpty && !_showChatTabs) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isAdminChat =
                    _conversation.type == ConversationType.adminChat;
                final isRoomChat =
                    _conversation.type == ConversationType.roomChat;
                final isClassroomChat =
                    _conversation.type == ConversationType.classroomChat;
                // Admin chat and Room chat → guardian/parent chips only.
                // Classroom Notes → present-roster staff/admins only (the
                // conversation can still list someone the classroom roster
                // has since dropped — see [_presentUserCodes]/[GetClassroomRosterPresentUserCodesUseCase]).
                // All other types → show everyone.
                final visibleParticipants = (isAdminChat || isRoomChat)
                    ? participants.where((p) {
                        final role = p.role.toApiString().toUpperCase();
                        return role == 'PARENT' || role == 'GUARDIAN';
                      }).toList()
                    : (isClassroomChat && _presentUserCodes != null)
                    ? participants
                          .where((p) => _presentUserCodes!.contains(p.userCode))
                          .toList()
                    : participants;
                if (visibleParticipants.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleParticipants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final p = visibleParticipants[index];
                      final roleStr =
                          p.role.toApiString().toUpperCase() == 'PARENT'
                          ? 'GUARDIAN'
                          : p.role.toApiString().toUpperCase();
                      // Always show display name — never fall back to userCode
                      final name = p.userName.isNotEmpty
                          ? p.userName
                          : _roleFallbackName(roleStr);
                      final color = _roleColor(roleStr);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DocumentImageWidget(
                              disableAttendanceStatusLookup: true,
                              fileUuid: '',
                              imageUrl: (p.avatarUrl ?? '').startsWith('http')
                                  ? p.avatarUrl
                                  : null,
                              mediaAssetCode:
                                  (p.avatarUrl ?? '').isNotEmpty &&
                                      !(p.avatarUrl ?? '').startsWith('http')
                                  ? p.avatarUrl
                                  : null,
                              staffCode: (p.staffCode ?? '').trim().isNotEmpty
                                  ? p.staffCode
                                  : null,
                              name: name,
                              size: 16,
                              fontSize: 9,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
          // Staff/admin viewer, private mode active: interactive tab chips
          // to switch between Group Chat and each guardian's private
          // thread. This is what was missing compared to Room Chat's
          // legacy screen — that screen has always had this; this (v2,
          // Admin Chat included) screen never did.
          if (_showChatTabs) ...[
            const SizedBox(height: 8),
            _buildChatTabChips(),
          ],
          // Shown to EVERY persona (previously parent-only, which meant an
          // admin/staff viewer could never see who turned private mode on
          // for a conversation they're looking at) — gated instead on the
          // conversation type plus an actual live "is private mode active"
          // check inside `_buildPrivateModeHeader` itself.
          if (_conversation.type == ConversationType.adminChat ||
              _conversation.type == ConversationType.roomChat) ...[
            const SizedBox(height: 8),
            _buildPrivateModeHeader(),
          ],
        ],
      ),
    );
  }

  /// Horizontal row of "Group Chat" + one chip per guardian in
  /// [_tabGuardians]. Mirrors the legacy `ParentMessagingThread`'s tab
  /// chips visually (same colors/shape) — tapping a chip calls
  /// `_tabController.animateTo`, and [_visibleMessagesForActiveTab] reacts
  /// to the resulting index change (via the listener in
  /// [_syncTabController], which just triggers a rebuild).
  Widget _buildChatTabChips() {
    final controller = _tabController;
    if (controller == null) return const SizedBox.shrink();
    final guardians = _tabGuardians;
    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChatTabChip(
            label: 'Group Chat',
            tabIndex: 0,
            // Matches the legacy Room Chat screen's own Group Chat chip
            // colour exactly (AppColors.themeColor, not primaryColor).
            color: AppColors.themeColor,
            showLockIcon: false,
          ),
          ...guardians.asMap().entries.map((entry) {
            final tabIndex = entry.key + 1;
            final guardian = entry.value;
            final label = guardian.userName.isNotEmpty
                ? guardian.userName
                : guardian.userCode;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _buildChatTabChip(
                label: label,
                tabIndex: tabIndex,
                color: const Color(0xFF00B4DB),
                showLockIcon: _conversation.isPrivateModeEnabledFor(
                  guardian.userCode,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatTabChip({
    required String label,
    required int tabIndex,
    required Color color,
    required bool showLockIcon,
  }) {
    final controller = _tabController!;
    final isSelected = controller.index == tabIndex;
    return GestureDetector(
      onTap: () {
        if (controller.index != tabIndex) controller.animateTo(tabIndex);
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
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (showLockIcon) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.visibility_off,
                size: 12,
                color: isSelected ? Colors.white : const Color(0xFFD63031),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The userCode of whichever parent actually has private mode enabled —
  /// preferring the per-parent [ConversationEntity.privateModeStates] map
  /// (accurate when several guardians are on the conversation and only one
  /// enabled it) over the room-wide [ConversationEntity.privateModeActivatedBy]
  /// (only meaningful when there's a single relevant guardian).
  ///
  /// When [forGuardianCode] is given (the guardian whose tab is currently
  /// active), prefers THAT guardian's own state entry — a guardian swept
  /// into private mode by the other parent (per the private-mode spec, both
  /// parents' threads go private together) still has an entry, just with
  /// `owner` pointing at whoever actually triggered it.
  String? _privateModeOwnerCode({String? forGuardianCode}) {
    final states = _conversation.privateModeStates;
    if (forGuardianCode != null) {
      final ownState = states[forGuardianCode];
      if (ownState != null && ownState.enabled) return ownState.owner;
    }
    for (final entry in states.entries) {
      if (entry.value.enabled) return entry.value.owner;
    }
    return _conversation.privateModeActivatedBy;
  }

  Widget _buildPrivateModeHeader() {
    if (!_conversation.hasActivePrivateMode) return const SizedBox.shrink();

    // Tabbed staff/admin view: the banner only makes sense while looking at
    // an actual private (guardian) tab — Group Chat itself is never
    // private, so showing it there regardless of tab was confusing. Scope
    // the resolved owner to whichever guardian's tab is active.
    String? activeGuardianCode;
    if (_showChatTabs) {
      final activeIndex = _tabController?.index ?? 0;
      if (activeIndex == 0) return const SizedBox.shrink();
      final guardians = _tabGuardians;
      final guardianIndex = activeIndex - 1;
      if (guardianIndex < guardians.length) {
        activeGuardianCode = guardians[guardianIndex].userCode;
      }
    }

    final ownerCode = _privateModeOwnerCode(
      forGuardianCode: activeGuardianCode,
    );
    final parentParticipant = _conversation.participants.firstWhere(
      (p) => p.userCode == ownerCode,
      orElse: () => _conversation.participants.firstWhere(
        (p) => p.role == ParticipantRole.parent && p.userCode != _senderCode,
        orElse: () => _conversation.participants.firstWhere(
          (p) => p.role == ParticipantRole.parent,
          orElse: () => _conversation.participants.first,
        ),
      ),
    );

    final parentName = parentParticipant.userName.isNotEmpty
        ? parentParticipant.userName
        : parentParticipant.userCode;

    // A compact pill sized to its own content (matching the tab chips'
    // scale) — the previous `Expanded` text inside an unconstrained-width
    // Container stretched the box to the full header width while the text
    // stayed small, leaving a big empty box around a tiny label.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE8B3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: Color(0xFFC9A000)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Private by $parentName',
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
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

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

  /// True if [msg]'s sender is staff/admin/teacher/director, false if
  /// guardian/parent — see [MessageBubble.senderIsOrgSide].
  ///
  /// Trusts [MessageEntity.senderRole] — the exact role THIS message was
  /// sent under — directly, rather than cross-checking it against a
  /// participant-list lookup by `senderCode`. A dual-role account (e.g. an
  /// admin who is also the enrolled child's guardian) has TWO participant
  /// entries sharing the same userCode; `.where(userCode == ...).firstOrNull`
  /// can't tell which persona sent THIS message and would silently pick
  /// whichever entry happens to be first (typically the org-side one),
  /// wrongly flagging a guardian-sent message as org-side and pulling it
  /// onto the wrong side/colour — the same class of bug already fixed for
  /// message ownership via `senderRole` elsewhere (see
  /// `withRoleAwareOwnership` / `mapMessageEntityToMessage`'s
  /// `viewingAsGuardian`). `senderRole` is populated reliably from the REST
  /// response for every message, so there's no missing-data case left to
  /// fall back to a participant-list guess for.
  bool _isOrgSideSender(MessageEntity msg) =>
      msg.senderRole != ParticipantRole.parent;

  Widget _buildMessageList(ConversationThreadState state) {
    if (state.isLoading && !state.hasMessages) {
      return const ChatThreadShimmer();
    }

    if (!state.hasMessages && state.errorMessage != null) {
      final errorMessage = state.errorMessage!;
      final isUnauthorized = _isUnauthorizedConversationError(errorMessage);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnauthorized
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                isUnauthorized
                    ? 'This chat hasn\'t been created yet. Go back and start a new conversation.'
                    : errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: isUnauthorized
                    ? () => Navigator.of(context).pop()
                    : _cubit.loadMessages,
                child: Text(isUnauthorized ? 'Go back' : 'Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.hasMessages) {
      // A bare Center has no scrollable ancestor for RefreshIndicator to
      // detect the pull gesture against — wrap it in a scrollable (matching
      // the non-empty list below, which already supports pull-to-refresh)
      // so a brand-new/empty conversation can still be refreshed.
      return CustomRefreshIndicator(
        onRefresh: _cubit.refreshMessages,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Text(
                    'No messages yet. Say hello!',
                    style: TextStyle(color: Color(0xFFB2BEC3), fontSize: 14),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final messages = _visibleMessagesForActiveTab(state.messages);

    // The list (and its ScrollController) must stay mounted — and
    // therefore attached — the whole time, or `scrollToBottom()` has
    // nothing to scroll and silently no-ops. So instead of swapping the
    // shimmer in for the real list, keep the real list underneath at all
    // times and just hide it with opacity until the first scroll-to-bottom
    // has actually settled, with the shimmer painted on top in the
    // meantime.
    return Stack(
      children: [
        // Visibility (not Opacity) so the hidden list is excluded from the
        // semantics tree while off-screen — a reverse:true ListView whose
        // hidden subtree still participates in semantics while this Stack's
        // visible child flips is what was triggering Flutter's
        // `!semantics.parentDataDirty` assertion crash on open.
        Visibility(
          visible: _isPositionedAtBottom,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: _buildRealMessageList(messages),
        ),
        if (!_isPositionedAtBottom)
          const Positioned.fill(child: ChatThreadShimmer()),
      ],
    );
  }

  Widget _buildRealMessageList(List<MessageEntity> messages) {
    return CustomRefreshIndicator(
      onRefresh: _cubit.refreshMessages,
      child: ListView.builder(
        controller: _scrollController,
        // A handful of messages don't fill the viewport, and without this a
        // ListView with unfilled content isn't scrollable at all — so the
        // pull gesture never reaches CustomRefreshIndicator. Forces it to
        // stay scrollable (and therefore pull-to-refresh-able) regardless
        // of message count.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // reverse: true means index 0 = last message
          final msg = messages[messages.length - 1 - index];
          final prevIndex = messages.length - 2 - index;

          bool showDateHeader;
          if (prevIndex >= 0) {
            showDateHeader = _isDifferentDay(
              msg.sentAt,
              messages[prevIndex].sentAt,
            );
          } else {
            showDateHeader = true;
          }

          final prevMsg = prevIndex >= 0 ? messages[prevIndex] : null;
          final isGrouped = !showDateHeader && _isSameSender(prevMsg, msg);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDateHeader) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1A573353),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomTextWidget(
                        text: _dateSeparatorLabel(msg.sentAt),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        applyLetterSpacing: false,
                      ),
                    ),
                  ),
                ),
              ],
              EntityMessageTile(
                key: _keyForMessage(msg.code.isNotEmpty ? msg.code : msg.id),
                messageCode: msg.code,
                quotedMessageCode: msg.threadParentCode,
                isGrouped: isGrouped,
                reactionsController: _reactionsController,
                currentUserCode: _senderCode,
                onScrollToQuoted: (quoteId) => _scrollToMessage(quoteId),
                // Deleted messages disable all interactions except viewing/adding reactions
                onReply: msg.isDeleted
                    ? null
                    : () => setState(() => _quotedMessage = msg),
                onReplyFromMenu: msg.isDeleted
                    ? null
                    : () => setState(() => _quotedMessage = msg),
                onCopy: msg.isDeleted
                    ? null
                    : () {
                        Clipboard.setData(
                          ClipboardData(
                            text: MessageContentProcessor.stripHtmlTags(
                              msg.text,
                            ),
                          ),
                        );
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: 'Message copied successfully',
                          isSuccess: true,
                        );
                      },
                onEdit: msg.isDeleted
                    ? null
                    : () {
                        final cleanedText =
                            MessageContentProcessor.stripHtmlTags(msg.text);
                        setState(() {
                          _editingMessage = msg;
                          _inputController.value = TextEditingValue(
                            text: cleanedText,
                            selection: TextSelection.collapsed(
                              offset: cleanedText.length,
                            ),
                          );
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _inputFocusNode.requestFocus();
                          }
                        });
                      },
                onDelete: msg.isDeleted
                    ? null
                    : () async {
                        await _cubit.deleteMessage(msg.code);
                        if (!context.mounted) return;
                        // deleteMessage has no return value to check — the
                        // BlocListener below already shows the real API
                        // error (e.g. "delete window has passed") when
                        // ConversationThreadState.errorMessage gets set on
                        // failure. Showing a success toast unconditionally
                        // here, regardless of outcome, meant a failed
                        // delete showed BOTH a false green "deleted
                        // successfully" toast AND the real error right
                        // after it. Only confirm success when the state
                        // agrees nothing went wrong.
                        if (_cubit.state.errorMessage == null) {
                          CoreUtils.showTopSnackBar(
                            context: context,
                            message: 'Message deleted successfully',
                            isSuccess: true,
                          );
                        }
                      },
                onInfo: msg.isDeleted
                    ? null
                    : () => _showMessageInfoDialog(context, msg),
                onDeleteAttachment: (attachment) {
                  if (attachment.attachmentId != null) {
                    _cubit.deleteAttachment(
                      messageCode: msg.code,
                      attachmentId: attachment.attachmentId!,
                    );
                  }
                },
                onReactionAdded: (emoji) {
                  if (msg.userHasReaction(_senderCode, emoji)) {
                    _cubit.removeReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Reaction removed',
                      isSuccess: true,
                    );
                  } else {
                    _cubit.addReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Reaction added',
                      isSuccess: true,
                    );
                  }
                },
                onRemoveReaction: (emoji) {
                  _cubit.removeReaction(
                    messageCode: msg.code,
                    emoji: emoji,
                    currentUserCode: _senderCode,
                  );
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: 'Reaction removed',
                    isSuccess: true,
                  );
                },
                onReactionTap: () {
                  // Dismiss any open overlay then focus the chat input so
                  // the user can compose an emoji reply or pick a reaction
                  // via the app's own emoji keyboard — no third-party picker.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _inputFocusNode.requestFocus();
                  });
                },
                onReactionsInfoTap: () => _showReactionInfoDialog(context, msg),
                isParentMessaging: _senderRole == ParticipantRole.parent,
                senderIsOrgSide: _isOrgSideSender(msg),
                viewerIsOrgSide: _senderRole != ParticipantRole.parent,
                participants: _conversation.participants,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Once a draft thread's conversation is created on first send, the cubit
  /// emits the real [ConversationEntity] (with participants). Adopt it so the
  /// header roster and bubble alignment update immediately — no refresh needed.
  void _syncResolvedConversation(ConversationThreadState state) {
    final resolved = state.conversation;
    if (resolved != null &&
        resolved.code.isNotEmpty &&
        resolved.code != _conversation.code) {
      setState(() => _resolvedConversation = resolved);
    }
  }

  Widget _buildThreadBody() {
    return BlocConsumer<ConversationThreadCubit, ConversationThreadState>(
      listener: (context, state) {
        _syncResolvedConversation(state);
        _onMessagesChanged(state.messages);
        if (state.successMessage != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.successMessage!,
            isSuccess: true,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _cubit.clearSuccess();
          });
        }
        // Surface an action error (e.g. a delete rejected by the server because
        // the delete window has passed) as a snackbar. The full-screen error is
        // only used for an initial load failure (no messages), so here — with the
        // thread loaded — an errorMessage is always a mid-thread action failure.
        if (state.errorMessage != null && state.hasMessages) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _cubit.clearError();
          });
        }
      },
      builder: (context, state) {
        _syncTabController();
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (widget.showOwnScaffold) ...[
            //   // CustomTextWidget(text: 'Messaging ', fontSize: 16),
            //   const SizedBox(height: 10),
            // ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF4F7FD),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildParticipantHeader(),
                    // ── In-thread search bar ─────────────────────────────────
                    if (_showSearch) _buildSearchBar(),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMessageList(state),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: LoadingOlderIndicator(
                              // The only path that sets `isLoading` while
                              // `hasMessages` is already true is
                              // loadOlderMessages() — the initial/full load
                              // only ever runs while the list is still empty.
                              visible: state.isLoading && state.hasMessages,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: ValueListenableBuilder<bool>(
                              valueListenable:
                                  _scrollBehavior.showNewMessageIndicator,
                              builder: (_, visible, __) => NewMessagesIndicator(
                                visible: visible,
                                onTap: () => _scrollBehavior.scrollToBottom(),
                              ),
                            ),
                          ),
                          // Search results overlay
                          if (_showSearch &&
                              (_searchResults.isNotEmpty || _isSearching))
                            _buildSearchResultsOverlay(),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: ChatInputBar(
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          isSending: state.isSending,
                          enabled:
                              !_studentInactive &&
                              !_noActiveGuardian &&
                              !_currentUserInactive,
                          disabledMessage: _currentUserInactive
                              ? 'Your staff account is inactive. You can no '
                                    'longer send messages.'
                              : _studentInactive
                              ? 'This student is inactive. You can no '
                                    'longer send messages.'
                              : 'No active parent or guardian is available in '
                                    'this conversation. You can no longer send '
                                    'messages.',
                          onSend: () => unawaited(_sendMessage()),
                          onAttachmentTap: _showAttachmentSheet,
                          pendingAttachments: _pendingAttachments,
                          showCharCounter: true,
                          onRemoveAttachment: (i) =>
                              setState(() => _pendingAttachments.removeAt(i)),
                          quotedMessage: _quotedMessage != null
                              ? mapMessageEntityToMessage(
                                  _quotedMessage!,
                                  _senderCode,
                                  viewingAsGuardian:
                                      _senderRole == ParticipantRole.parent,
                                )
                              : null,
                          onCancelQuote: () =>
                              setState(() => _quotedMessage = null),
                          editingMessage: _editingMessage != null
                              ? mapMessageEntityToMessage(
                                  _editingMessage!,
                                  _senderCode,
                                  viewingAsGuardian:
                                      _senderRole == ParticipantRole.parent,
                                )
                              : null,
                          onCancelEdit: () => setState(() {
                            _editingMessage = null;
                            _inputController.clear();
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final body = BlocListener<PushNotificationCubit, PushNotificationState>(
      listenWhen: (prev, curr) =>
          curr.newMessageEventSeq != prev.newMessageEventSeq &&
          curr.incomingConversationCode == widget.conversation.code,
      listener: (_, __) => _cubit.refreshMessages(),
      child: BlocProvider<ConversationThreadCubit>.value(
        value: _cubit,
        child: _buildThreadBody(),
      ),
    );

    if (!widget.showOwnScaffold) return body;

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: !isLandscape,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }

  bool _isSameSender(MessageEntity? prev, MessageEntity current) {
    if (prev == null) return false;
    final prevCode = prev.senderCode;
    final currCode = current.senderCode;
    if (prevCode.isNotEmpty && currCode.isNotEmpty) {
      return prevCode == currCode &&
          current.sentAt.difference(prev.sentAt).inMinutes <= 5;
    }
    return (prev.senderCode == _senderCode) ==
            (current.senderCode == _senderCode) &&
        current.sentAt.difference(prev.sentAt).inMinutes <= 5;
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: const TextStyle(
                  color: Color(0xFFB2BEC3),
                  fontSize: 14,
                  fontFamily: 'Manrope',
                ),
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: PrimaryCircularLoader(size: 16, strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFB2BEC3),
                        size: 20,
                      ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFB2BEC3),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F7FD),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _closeSearch,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search results overlay ────────────────────────────────────────────────

  Widget _buildSearchResultsOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.white.withValues(alpha: 0.97),
        child: _isSearching && _searchResults.isEmpty
            ? const Center(child: PrimaryCircularLoader())
            : _searchResults.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.primaryColor.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No messages found',
                      style: TextStyle(
                        color: const Color(0xFF636E72),
                        fontSize: 14,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final hit = _searchResults[i];
                  final query = _searchController.text.trim().toLowerCase();
                  final plain = hit.text
                      .replaceAll(RegExp(r'<[^>]*>'), '')
                      .trim();

                  return ListTile(
                    dense: true,
                    leading: DocumentImageWidget(
                      disableAttendanceStatusLookup: true,
                      fileUuid: '',
                      name: hit.senderName,
                      size: 32,
                      fontSize: 12,
                    ),
                    title: Text(
                      hit.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF573353),
                      ),
                    ),
                    subtitle: _buildHighlightedText(plain, query),
                    trailing: Text(
                      _formatSearchTime(hit.sentAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    onTap: () {
                      _closeSearch();
                      // Give the list time to rebuild before scrolling.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToMessage(
                          hit.code.isNotEmpty ? hit.code : hit.id,
                        );
                      });
                    },
                  );
                },
              ),
      ),
    );
  }

  /// Returns a [RichText] where every occurrence of [query] in [text] is
  /// rendered in bold / primary-colour so the match stands out.
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
      );
    }

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final idx = lower.indexOf(query, start);
      if (idx == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
          ),
        );
        break;
      }
      if (idx > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, idx),
            style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      );
      start = idx + query.length;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  String _formatSearchTime(DateTime dt) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
