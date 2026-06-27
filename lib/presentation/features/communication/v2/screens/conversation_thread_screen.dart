import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_scroll_behavior.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/usecases/search_messages_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_status_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_state.dart';
import 'package:wowcare/presentation/features/communication/v2/util/message_entity_mapper.dart';
import 'package:wowcare/presentation/features/communication/v2/widgets/entity_message_tile.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/loading_older_indicator.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/new_messages_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

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

    /// Initial private-mode state seed (from [ConversationEntity.privateModeStates]).
    this.initialPrivateModeEnabled = false,
  });

  final ConversationEntity conversation;
  final bool showOwnScaffold;
  final bool showPrivateModeToggle;
  final bool initialPrivateModeEnabled;

  @override
  State<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen>
    with WidgetsBindingObserver {
  late final ConversationThreadCubit _cubit;
  final TextEditingController _inputController = TextEditingController();

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
  String? _conversationPrivateModeActivatedBy;
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

  // ── Draft persistence ─────────────────────────────────────────────────────

  /// SharedPreferences key for the per-conversation draft.
  String get _draftStorageKey => 'msg_draft_${widget.conversation.code}';

  // ── Per-message GlobalKeys (scroll-to-original) ───────────────────────────

  /// Maps message code → GlobalKey so [Scrollable.ensureVisible] can jump to
  /// any rendered bubble precisely.
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _keyForMessage(String code) =>
      _messageKeys.putIfAbsent(code, GlobalKey.new);

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
      watchMessagesUseCase: serviceLocator(),
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      editMessageUseCase: serviceLocator(),
      deleteMessageUseCase: serviceLocator(),
      deleteAttachmentUseCase: serviceLocator(),
      addReactionUseCase: serviceLocator(),
      removeReactionUseCase: serviceLocator(),
      markConversationReadUseCase: serviceLocator(),
      attachmentUploader: serviceLocator(),
    );
    _searchUseCase = SearchMessagesUseCase(serviceLocator());

    _cubit.startWatchingMessages();
    unawaited(_loadSenderInfo());
    unawaited(_loadDraft());

    if (widget.showPrivateModeToggle) {
      _privateModeToggleCubit = PrivateModeToggleCubit(
        togglePrivateModeUseCase: TogglePrivateModeUseCase(serviceLocator()),
        conversationCode: widget.conversation.code,
        initialEnabled: widget.conversation.privateModeActive ||
            widget.initialPrivateModeEnabled,
      );
      _conversationPrivateModeActivatedBy =
          widget.conversation.privateModeActivatedBy;
    }
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
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '')
        .trim()
        .toUpperCase();

    if (!mounted) return;
    setState(() {
      _senderCode = userCode;
      _senderName = displayName.isNotEmpty ? displayName : userCode;
      _organizationCode = orgCode;
      _schoolCode = school;
      _senderRole = ParticipantRole.fromApiString(rolesRaw);
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

  List<ParticipantDisplayData> get _participantData =>
      widget.conversation.participants.map((p) {
        final roleStr = p.role.toApiString().toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
        );
      }).toList();

  void _showParticipantsDialog() {
    ParticipantInfoDialog.show(
      context,
      participants: _participantData,
      studentName: widget.conversation.title,
    );
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
      _inputController.clear();
      final originalEditMsg = _editingMessage!;
      setState(() {
        _editingMessage = null;
      });

      if (text != originalEditMsg.text) {
        await _cubit.editMessage(messageCode: messageCode, newText: text);
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message updated successfully',
            isSuccess: true,
          );
        }
      }
      return;
    }

    _inputController.clear();
    unawaited(_saveDraft()); // clears the stored draft (text is now empty)
    // Sending always scrolls to bottom regardless of current scroll position
    // — _onMessagesChanged() picks this flag up as soon as the cubit's
    // optimistic message lands in state (before the network call resolves).
    _ownSendPending = true;
    final attachmentsBeingSent = _pendingAttachments;
    final bool isPrivate = widget.showPrivateModeToggle &&
        _privateModeToggleCubit?.state.isEnabled == true;

    await _cubit.sendMessage(
      text: text,
      senderCode: _senderCode,
      senderName: _senderName,
      senderRole: _senderRole,
      organizationCode: _organizationCode,
      schoolCode: _schoolCode,
      attachments: attachmentsBeingSent,
      isPrivate: isPrivate,
      threadParentCode: _quotedMessage?.code,
    );
    if (!mounted) return;
    if (_cubit.state.sendError != null) {
      // Upload or send failed — preserve the pending attachments (still the
      // same local files) so the user can retry without re-picking them.
      CoreUtils.showTopSnackBar(
        context: context,
        message: _cubit.state.sendError!,
        isError: true,
      );
      return;
    }
    setState(() {
      _quotedMessage = null;
      _pendingAttachments.clear();
    });
  }

  // ── Date chip ─────────────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime date) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(date, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
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
    final participants = widget.conversation.participants;
    final title = widget.conversation.title.isNotEmpty
        ? widget.conversation.title
        : 'Conversation';
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
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
              // Private Mode toggle — parent persona only
              if (widget.showPrivateModeToggle &&
                  _privateModeToggleCubit != null)
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
                    setState(() {
                      if (pmState.isEnabled) {
                        _conversationPrivateModeActivatedBy = _senderCode;
                      } else {
                        _conversationPrivateModeActivatedBy = null;
                      }
                    });
                  },
                  builder: (_, pmState) => Tooltip(
                    message: pmState.isEnabled
                        ? (_conversationPrivateModeActivatedBy ==
                                  _senderCode ||
                              _conversationPrivateModeActivatedBy == null
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
                          onChanged: pmState.isLoading
                              ? null
                              : (_conversationPrivateModeActivatedBy !=
                                        null &&
                                    _conversationPrivateModeActivatedBy !=
                                        _senderCode &&
                                    pmState.isEnabled)
                                  ? null
                                  : (_) => _privateModeToggleCubit!.toggle(),
                          activeThumbColor: const Color(0xFF6C63FF),
                          activeTrackColor: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
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
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isAdminChat =
                    widget.conversation.type == ConversationType.adminChat;
                final visibleParticipants = isAdminChat
                    ? participants
                          .where(
                            (p) =>
                                p.role.toApiString().toUpperCase() == 'ADMIN',
                          )
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
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';
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
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: color.withValues(alpha: 0.25),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
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
        ],
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
      return const Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(color: Color(0xFFB2BEC3), fontSize: 14),
        ),
      );
    }

    final messages = state.messages;

    // The list (and its ScrollController) must stay mounted — and
    // therefore attached — the whole time, or `scrollToBottom()` has
    // nothing to scroll and silently no-ops. So instead of swapping the
    // shimmer in for the real list, keep the real list underneath at all
    // times and just hide it with opacity until the first scroll-to-bottom
    // has actually settled, with the shimmer painted on top in the
    // meantime.
    return Stack(
      children: [
        Opacity(
          opacity: _isPositionedAtBottom ? 1 : 0,
          child: _buildRealMessageList(messages),
        ),
        if (!_isPositionedAtBottom)
          const Positioned.fill(child: ChatThreadShimmer()),
      ],
    );
  }

  Widget _buildRealMessageList(List<MessageEntity> messages) {
    return RefreshIndicator(
      onRefresh: _cubit.refreshMessages,
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
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
                    child: CustomTextWidget(
                      text: _dateSeparatorLabel(msg.sentAt),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      applyLetterSpacing: false,
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
                      text: MessageContentProcessor.stripHtmlTags(msg.text),
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
                  setState(() {
                    _editingMessage = msg;
                    _inputController.text =
                        MessageContentProcessor.stripHtmlTags(msg.text);
                  });
                  _inputFocusNode.requestFocus();
                },
                onDelete: msg.isDeleted
                    ? null
                    : () async {
                  await _cubit.deleteMessage(msg.code);
                  if (context.mounted) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Message deleted successfully',
                      isSuccess: true,
                    );
                  }
                },
                onInfo: msg.isDeleted
                    ? null
                    : () => MessageStatusDialog.show(context, message: msg),
                onDeleteAttachment: (attachment) {
                  if (attachment.attachmentId != null) {
                    _cubit.deleteAttachment(
                      messageCode: msg.code,
                      attachmentId: attachment.attachmentId!,
                    );
                  }
                },
                onReactionAdded: (emoji) {
                  final myReaction = msg.reactions[_senderCode];
                  if (myReaction == emoji) {
                    _cubit.removeReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                  } else {
                    _cubit.addReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                  }
                },
                onRemoveReaction: (emoji) {
                  _cubit.removeReaction(
                    messageCode: msg.code,
                    emoji: emoji,
                    currentUserCode: _senderCode,
                  );
                },
                onReactionTap: () => _showEmojiPicker(context, msg),
                isParentMessaging: _senderRole == ParticipantRole.parent,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThreadBody() {
    return BlocConsumer<ConversationThreadCubit, ConversationThreadState>(
      listener: (context, state) {
        _onMessagesChanged(state.messages);
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showOwnScaffold) ...[
              CustomTextWidget(text: 'Messaging', fontSize: 16),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF4F7FD),
                ),
                child: Column(
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
                      child: ChatInputBar(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        isSending: state.isSending,
                        onSend: () => unawaited(_sendMessage()),
                        onAttachmentTap: _showAttachmentSheet,
                        pendingAttachments: _pendingAttachments,
                        onRemoveAttachment: (i) =>
                            setState(() => _pendingAttachments.removeAt(i)),
                        quotedMessage: _quotedMessage != null
                            ? mapMessageEntityToMessage(
                                _quotedMessage!,
                                _senderCode,
                              )
                            : null,
                        onCancelQuote: () =>
                            setState(() => _quotedMessage = null),
                        editingMessage: _editingMessage != null
                            ? mapMessageEntityToMessage(
                                _editingMessage!,
                                _senderCode,
                              )
                            : null,
                        onCancelEdit: () => setState(() {
                          _editingMessage = null;
                          _inputController.clear();
                        }),
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

    final body = BlocProvider<ConversationThreadCubit>.value(
      value: _cubit,
      child: _buildThreadBody(),
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
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
            ? const Center(child: CircularProgressIndicator())
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
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryColor.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        hit.senderName.isNotEmpty
                            ? hit.senderName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
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

  void _showEmojiPicker(BuildContext context, MessageEntity message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final sheetHeight =
            (MediaQuery.of(context).size.height * 0.55).clamp(240.0, 400.0) +
            MediaQuery.of(context).padding.bottom;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context); // close picker
              final myReaction = message.reactions[_senderCode];
              if (myReaction == emoji.emoji) {
                _cubit.removeReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              } else {
                _cubit.addReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              }
            },
            config: const Config(
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
}
