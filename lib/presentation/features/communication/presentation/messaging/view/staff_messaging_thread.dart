import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import '../../../../../../domain/features/communication/entities/message.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_scroll_behavior.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/loading_older_indicator.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/reaction_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/new_messages_indicator.dart';
import '../widgets/thread_message_tile.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/activities/utils/resolve_logged_in_staff_code.dart';

class StaffMessagingThread extends StatefulWidget {
  const StaffMessagingThread({super.key, required this.staffInfo});
  final Map<String, dynamic> staffInfo;

  @override
  State<StaffMessagingThread> createState() => _StaffMessagingThreadState();
}

class _StaffMessagingThreadState extends State<StaffMessagingThread>
    with WidgetsBindingObserver {
  //final ScrollController _scrollController = ScrollController();
  final AutoScrollController _scrollController = AutoScrollController();
  final HtmlAwareTextController _controller = HtmlAwareTextController();
  late final ChatScrollBehavior _scrollBehavior = ChatScrollBehavior(
    _scrollController,
  );
  double _lastKeyboardInset = 0;
  // Tracks the latest message's id rather than a raw count — a raw count
  // can desync across edits/deletes/optimistic-rollbacks, silently
  // breaking the "did a new message arrive" check this drives. Identity
  // comparison is correct regardless of why the list changed.
  String? _lastMessageId;
  bool _initialLoadInFlight = true;
  bool _ownSendPending = false;

  /// True once the thread has successfully loaded at least once. Used to
  /// tell a genuine initial-load failure (shown as a full-page error, see
  /// `build()`) apart from a MID-thread action failure (reaction/delete/
  /// send/etc.) — the latter's `CommunicationError` state is immediately
  /// superseded by a follow-up `CommunicationLoaded` emit in the same
  /// cubit call (see `CommunicationCubit._emitSendFailure`), so it never
  /// survives to a painted frame; `build()` alone silently skips it. The
  /// `listener` callback below fires synchronously per-emission regardless
  /// of frame batching, so it's the only reliable place to catch it.
  bool _hasLoadedThreadOnce = false;

  /// False until the very first scroll-to-bottom has actually landed on the
  /// true latest message. The real message list stays hidden behind the
  /// shimmer until this flips, so opening a thread shows the conversation
  /// already sitting at the latest message instead of visibly scrolling
  /// down to it from the top.
  bool _isPositionedAtBottom = false;

  /// `staffInfo['avatar']` is either a resolved URL or a raw media-asset
  /// code depending on which screen started the conversation — `fileUuid`
  /// on [DocumentImageWidget] is never actually used to resolve an image
  /// (only `imageUrl`/`mediaAssetCode` are), so route to whichever one
  /// matches the value's shape instead.
  String get _rawStaffAvatar =>
      (widget.staffInfo['avatar'] as String?)?.trim() ?? '';
  String? get _staffAvatarAsImageUrl =>
      _rawStaffAvatar.startsWith('http') ? _rawStaffAvatar : null;
  String? get _staffAvatarAsMediaAssetCode =>
      _rawStaffAvatar.startsWith('http') ? null : _rawStaffAvatar;

  /// True when the staff counterpart of this 1:1 STAFF_DIRECT conversation
  /// is no longer active (withdrawn/terminated) — the STAFF_DIRECT
  /// equivalent of `ConversationThreadScreen`/`ParentMessagingThread`'s
  /// `_studentInactive`. Only INACTIVE actually blocks sending — UPCOMING
  /// is a normal, not-yet-started employment state and must behave like
  /// ACTIVE here.
  bool get _staffInactive {
    final status = (widget.staffInfo['staffStatus'] as String?)
        ?.trim()
        .toUpperCase();
    if (status == 'INACTIVE') return true;
    // Backend-authoritative "still active" flag, independent of
    // staffStatus — a participant can be deactivated (e.g. account
    // disabled) for a reason other than an INACTIVE employment status. See
    // ConversationParticipant.isActive's doc comment. `false` (not just
    // absent/null) is required to flip this — a missing signal fails open.
    final isActiveParticipant =
        widget.staffInfo['staffIsActiveParticipant'] as bool?;
    return isActiveParticipant == false;
  }

  /// True when the CURRENT (logged-in) staff member's own employment status
  /// is INACTIVE — distinct from [_staffInactive], which only covers the
  /// COUNTERPART (`widget.staffInfo`) of this 1:1 conversation. Resolved
  /// once in [initState] via [_loadCurrentUserStaffStatus]; defaults to
  /// false (fail-open) until that completes or if it fails, matching
  /// [ParentMessagingThread._amIActiveParticipant]'s "backend is the real
  /// authority" reasoning.
  bool _currentUserInactive = false;

  Future<void> _loadCurrentUserStaffStatus() async {
    try {
      final staffCode = await resolveLoggedInStaffCode();
      if (staffCode == null || staffCode.isEmpty) return;
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: staffCode,
      );
      if (!mounted) return;
      final inactive = profile.status.trim().toUpperCase() == 'INACTIVE';
      if (inactive != _currentUserInactive) {
        setState(() => _currentUserInactive = inactive);
      }
    } catch (_) {
      // Best-effort: the composer stays enabled on failure — the backend
      // is the actual authority and will reject the send if truly inactive.
    }
  }

  String? _currentUserCode;

  /// Guards against firing more than one `loadOlderMessages` request while
  /// one is already in flight — mirrors the cubit's own guard but avoids
  /// even constructing the call when we already know the answer locally.
  bool _isLoadingOlder = false;

  static const double _loadOlderScrollThreshold = 200.0;

  List<Message> get _messages {
    final state = context.read<CommunicationCubit>().state;
    if (state is CommunicationLoaded) {
      final threadId = widget.staffInfo['code'] as String;
      return state.threads[threadId] ?? [];
    }
    return [];
  }

  late final ReactionsController _reactionsController;

  Message? _quotedMessage = null;
  String? _quotedMessageCode;
  List<ChatAttachment> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    // Primary source: auth cubit state (already in memory after login).
    final authState = context.read<AuthCubit>().state;
    final userCodeFromAuth = authState is AuthLoaded
        ? authState.loginResponse.userCode.trim()
        : '';

    _currentUserCode = userCodeFromAuth.isNotEmpty ? userCodeFromAuth : null;

    _reactionsController = ReactionsController(
      currentUserId: _currentUserCode ?? 'me',
    );

    unawaited(_loadCurrentUserStaffStatus());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final storage = serviceLocator<StorageService>();

      // senderUserCode from the backend is the USR-/STF-... userCode, not the
      // JWT sub UUID. Use userCode for ownership comparison.
      final storedUserCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();

      _currentUserCode = userCodeFromAuth.isNotEmpty
          ? userCodeFromAuth
          : storedUserCode.isNotEmpty
          ? storedUserCode
          : null;

      if (mounted) {
        final threadId = widget.staffInfo['code'] as String;
        final communicationCubit = context.read<CommunicationCubit>();
        // Fire an immediate, unawaited mark-read on open — BEFORE
        // loadMessages, not after (see parent_messaging_thread.dart's
        // matching fix for why): sequencing it after `await loadMessages`
        // meant any failure/stall in that call silently skipped the read
        // receipt entirely, leaving the conversation's unread count stuck
        // even though the user genuinely opened and viewed it. As before,
        // deliberately NOT gated on `mounted` either — a quick
        // open-then-back tap must still record the read receipt even with
        // no UI left to update.
        unawaited(communicationCubit.markConversationRead(threadId));
        await communicationCubit.loadMessages(
          threadId,
          currentUserId: _currentUserCode,
        );
        if (!mounted) return;
        // Realtime listener starts only after the API/Isar history has
        // loaded — Firestore only ever applies deltas on top of it.
        communicationCubit.startWatchingThread(
          threadId,
          organizationCode: widget.staffInfo['organizationCode'] as String?,
          schoolCode: widget.staffInfo['schoolCode'] as String?,
        );
        final initialMessages = _messages;
        _lastMessageId = initialMessages.isNotEmpty
            ? initialMessages.last.id
            : null;
        _initialLoadInFlight = false;
        _scrollBehavior.scrollToBottom(
          animate: false,
          onSettled: () {
            if (!mounted) return;
            setState(() => _isPositionedAtBottom = true);
          },
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _reactionsController.dispose();
    _scrollBehavior.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _loadOlderScrollThreshold) return;
    _loadOlderMessages();
  }

  /// Fetches the next older page and keeps whatever the user is currently
  /// looking at pinned in place — the list's `maxScrollExtent` grows by
  /// exactly the height of the newly-prepended messages, so adding that
  /// delta to the current offset cancels out the shift, regardless of how
  /// tall the new messages turn out to be (text vs. images/attachments).
  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    final cubit = context.read<CommunicationCubit>();
    final state = cubit.state;
    if (state is! CommunicationLoaded) return;
    if (state.isLoadingOlderMessages || !state.hasMoreOlderMessages) return;

    _isLoadingOlder = true;
    final oldExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final oldOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    final threadId = widget.staffInfo['code'] as String;
    await cubit.loadOlderMessages(threadId, currentUserId: _currentUserCode);
    _isLoadingOlder = false;
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final delta = _scrollController.position.maxScrollExtent - oldExtent;
      if (delta > 0) {
        _scrollController.jumpTo(oldOffset + delta);
      }
    });
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
        _scrollBehavior.onKeyboardOpened();
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
    unawaited(
      context.read<CommunicationCubit>().markConversationRead(
        widget.staffInfo['code'] as String,
      ),
    );
    // Sending always scrolls to bottom, regardless of scroll position.
    // Other growth (realtime/API) only scrolls when already near bottom.
    if (wasOwnSend) {
      _scrollBehavior.scrollToBottom();
    } else {
      _scrollBehavior.onIncomingMessage();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;
    final hasAttachments = _pendingAttachments.isNotEmpty;

    if (!hasText && !hasAttachments) return;

    // Defense-in-depth — the composer already disables sending for this
    // (see _buildMessageInput's `enabled:`), but the backend is the real
    // authority so this is a client-side speed bump only.
    if (_currentUserInactive) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Your staff account is inactive. You can no longer send messages.',
        isError: true,
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final senderName = authState is AuthLoaded
        ? authState.loginResponse.displayName
        : 'Me';

    _ownSendPending = true;
    context.read<CommunicationCubit>().sendMessage(
      widget.staffInfo['code'] as String,
      text,
      attachments: List.from(_pendingAttachments),
      quotedMessageId: _quotedMessageCode,
      senderName: senderName,
      senderUserCode: _currentUserCode,
    );

    setState(() {
      _controller.clear();
      _pendingAttachments.clear();
      _quotedMessage = null;
      _quotedMessageCode = null;
    });
  }

  int? _getMessageIndex(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    return index >= 0 ? index : null;
  }

  void _scrollToMessage(String messageId) {
    final index = _getMessageIndex(messageId);
    if (index == null) {
      AppLogger.d("Message $messageId not found");
      return;
    }

    _scrollController.animateTo(
      (_scrollController.position.maxScrollExtent / _messages.length) *
          (index + 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  /// Returns true when [current] continues from the same sender as [prev],
  /// and was sent within 5 minutes.
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

  void _onReactionAdded(Message message, String emoji) {
    context.read<CommunicationCubit>().addReaction(
      widget.staffInfo['code'] as String,
      message.code,
      emoji,
      currentUserCode: _currentUserCode,
    );
  }

  void _showEmojiPicker(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final sheetHeight =
            (MediaQuery.of(context).size.height * 0.55).clamp(240.0, 400.0) +
            MediaQuery.of(context).padding.bottom;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context); // close picker
              _onReactionAdded(message, emoji.emoji);
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

  /// Delete a message and acknowledge the real outcome: a success toast, or
  /// the server's reason (e.g. the delete window has passed) — mirrors
  /// ParentMessagingThread's `_deleteMessageWithFeedback`. The two inline
  /// `onDelete` handlers this replaces called `deleteMessage` without
  /// awaiting it and showed an unconditional green "deleted successfully"
  /// toast regardless of the outcome — a 403 (delete window passed) showed
  /// as a false success and the user was never told it actually failed.
  Future<void> _deleteMessageWithFeedback(String messageCode) async {
    final failure = await context.read<CommunicationCubit>().deleteMessage(
      widget.staffInfo['code'] as String,
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

  void _showEditDialog(BuildContext context, Message message) {
    final TextEditingController editingController = TextEditingController(
      text: MessageContentProcessor.stripHtmlTags(message.text),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        backgroundColor: AppColors.white,

        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          //height: 60,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(89, 120, 247, 0.1),
                Color.fromRGBO(156, 132, 255, 0.1),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomTextWidget(text: 'Edit message'),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: Icon(Icons.clear, color: AppColors.primaryColor),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: editingController,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.redAccent,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.redAccent,
                  width: 2,
                ),
              ),
              //border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 60,
            //padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: TextButton(
              onPressed: () {
                final newText = editingController.text.trim();
                if (newText.isNotEmpty && newText != message.text) {
                  if (!mounted) return;
                  context.read<CommunicationCubit>().editMessage(
                    widget.staffInfo['code'] as String,
                    message.code,
                    newText,
                  );
                  // Cubit's editMessage already applies the optimistic update.
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: 'Message updated successfully',
                    isSuccess: true,
                  );
                }
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(overlayColor: AppColors.transparent),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunicationCubit, CommunicationState>(
      listener: (context, state) {
        if (state is CommunicationLoaded) {
          _hasLoadedThreadOnce = true;
          _onMessagesChanged(state.messages);
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
        final bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        if (state is CommunicationError && _messages.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildThreadHeader(context),
                  Expanded(child: _buildErrorState(state.message)),
                ],
              ),
            ),
          );
        }

        if (state is CommunicationLoaded && _messages.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildThreadHeader(context),
                  Expanded(child: _buildEmptyConversationState(context, state)),
                ],
              ),
            ),
          );
        }

        // The list (and its ScrollController) must stay mounted — and
        // therefore attached — the whole time, or `scrollToBottom()` has
        // nothing to scroll and silently no-ops. So instead of swapping the
        // shimmer in for the real list, keep the real list underneath at
        // all times and just hide it with opacity until the first
        // scroll-to-bottom has actually settled, with the shimmer painted
        // on top in the meantime. That's also why this never visibly
        // scrolls into place — the jump already happened before it's shown.
        return Scaffold(
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: Stack(
                              children: [
                                // Visibility (not Opacity) excludes the
                                // hidden list from semantics while off-screen
                                // — avoids the `!semantics.parentDataDirty`
                                // assertion this Stack+Opacity+ListView shape
                                // can trigger when the visible child flips.
                                Visibility(
                                  visible: _isPositionedAtBottom,
                                  maintainState: true,
                                  maintainAnimation: true,
                                  maintainSize: true,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF4F7FD),
                                    ),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      reverse: false,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        final messageId = message.id;
                                        //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                        // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                        // final key = keyMap.putIfAbsent(
                                        //   messageId,
                                        //   () => GlobalKey(),
                                        // );
                                        bool showDateHeader = false;
                                        final prevMessageIndex = index - 1;

                                        if (prevMessageIndex >= 0) {
                                          final prevMessage =
                                              _messages[prevMessageIndex];
                                          final schoolTz =
                                              SchoolTimezoneResolver
                                                  .lastKnownTimeZone;
                                          final currentDate =
                                              SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                message.time,
                                                schoolTz,
                                              );
                                          final prevDate =
                                              SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                prevMessage.time,
                                                schoolTz,
                                              );

                                          showDateHeader =
                                              currentDate.year !=
                                                  prevDate.year ||
                                              currentDate.month !=
                                                  prevDate.month ||
                                              currentDate.day != prevDate.day;
                                        } else {
                                          showDateHeader = true;
                                        }
                                        final prevMessage =
                                            prevMessageIndex >= 0
                                            ? _messages[prevMessageIndex]
                                            : null;
                                        final isGrouped =
                                            !showDateHeader &&
                                            _isSameSender(prevMessage, message);

                                        return AutoScrollTag(
                                          key: ValueKey(messageId),
                                          controller: _scrollController,
                                          index: index,
                                          highlightColor: AppColors.green
                                              .withValues(alpha: 0.7),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (showDateHeader)
                                                Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ),
                                                    child: _buildDateChip(
                                                      message.time,
                                                    ),
                                                  ),
                                                ),
                                              if (showDateHeader)
                                                const SizedBox(height: 10),
                                              // Spacing: compact for grouped, normal for new group
                                              SizedBox(
                                                height: isGrouped ? 2.0 : 8.0,
                                              ),
                                              ThreadMessageTile(
                                                threadId:
                                                    widget.staffInfo['code']
                                                        as String,
                                                messageCode: message.code,
                                                quotedMessageId:
                                                    message.quotedMessageId,
                                                onDeleteAttachment: (attachment) {
                                                  if (attachment.attachmentId !=
                                                      null) {
                                                    context
                                                        .read<
                                                          CommunicationCubit
                                                        >()
                                                        .deleteAttachment(
                                                          widget.staffInfo['code']
                                                              as String,
                                                          attachment
                                                              .attachmentId!,
                                                        );
                                                  }
                                                },
                                                onRetry: (msg) => context
                                                    .read<CommunicationCubit>()
                                                    .retrySendMessage(
                                                      widget.staffInfo['code']
                                                          as String,
                                                      msg,
                                                    ),
                                                currentUserCode:
                                                    _currentUserCode,
                                                reactionsController:
                                                    _reactionsController,
                                                onScrollToQuoted: (quoteId) {
                                                  _scrollToMessage(quoteId);
                                                },
                                                onReply: message.isDeleted
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _quotedMessageCode =
                                                              message.id;
                                                          _quotedMessage =
                                                              message;
                                                        });
                                                      },
                                                onReplyFromMenu:
                                                    message.isDeleted
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _quotedMessageCode =
                                                              message.id;
                                                          _quotedMessage =
                                                              message;
                                                        });
                                                      },
                                                onCopy: message.isDeleted
                                                    ? null
                                                    : () {
                                                        Clipboard.setData(
                                                          ClipboardData(
                                                            text:
                                                                MessageContentProcessor.stripHtmlTags(
                                                                  message.text,
                                                                ),
                                                          ),
                                                        );
                                                        CoreUtils.showTopSnackBar(
                                                          context: context,
                                                          message:
                                                              'Message copied successfully',
                                                          isSuccess: true,
                                                        );
                                                      },
                                                onEdit: message.isDeleted
                                                    ? null
                                                    : () => _showEditDialog(
                                                        context,
                                                        message,
                                                      ),
                                                onDelete: message.isDeleted
                                                    ? null
                                                    : () =>
                                                          _deleteMessageWithFeedback(
                                                            message.code,
                                                          ),
                                                onInfo: message.isDeleted
                                                    ? null
                                                    : () =>
                                                          _showMessageStatusDialog(
                                                            context,
                                                            message,
                                                          ),
                                                onReactionAdded: (emoji) =>
                                                    _onReactionAdded(
                                                      message,
                                                      emoji,
                                                    ),
                                                onRemoveReaction: (emoji) {
                                                  context
                                                      .read<
                                                        CommunicationCubit
                                                      >()
                                                      .removeReaction(
                                                        widget.staffInfo['code']
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
                                                onReactionsInfoTap: () =>
                                                    _showReactionInfoDialog(
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
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 8,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _scrollBehavior.showNewMessageIndicator,
                                    builder: (_, visible, __) =>
                                        NewMessagesIndicator(
                                          visible: visible,
                                          onTap: () =>
                                              _scrollBehavior.scrollToBottom(),
                                        ),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  child: LoadingOlderIndicator(
                                    visible:
                                        state is CommunicationLoaded &&
                                        state.isLoadingOlderMessages,
                                  ),
                                ),
                                if (!_isPositionedAtBottom)
                                  const Positioned.fill(
                                    child: ChatThreadShimmer(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
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
                                  color: AppColors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                  child: _buildMessageInput(state),
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
                                color: const Color(0xFFF4F7FD),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildThreadHeader(context),
                                  Flexible(
                                    child: Stack(
                                      children: [
                                        // See the landscape branch above for
                                        // why this is Visibility, not Opacity.
                                        Visibility(
                                          visible: _isPositionedAtBottom,
                                          maintainState: true,
                                          maintainAnimation: true,
                                          maintainSize: true,
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 12,
                                            ),
                                            reverse: false,
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final message = _messages[index];
                                              final messageId = message.id;
                                              //final scrollKey = _scrollKeys.putIfAbsent(messageId, () => GlobalKey());
                                              // final keyMap = message.isSentByMe ? _messageKeysSent : _messageKeysReceived;
                                              // final key = keyMap.putIfAbsent(
                                              //   messageId,
                                              //   () => GlobalKey(),
                                              // );
                                              bool showDateHeader = false;
                                              final prevMessageIndex =
                                                  index - 1;

                                              if (prevMessageIndex >= 0) {
                                                final prevMessage =
                                                    _messages[prevMessageIndex];
                                                final schoolTz =
                                                    SchoolTimezoneResolver
                                                        .lastKnownTimeZone;
                                                final currentDate =
                                                    SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                      message.time,
                                                      schoolTz,
                                                    );
                                                final prevDate =
                                                    SchoolZoneDateTime.dateTimeFromInstantInSchool(
                                                      prevMessage.time,
                                                      schoolTz,
                                                    );

                                                showDateHeader =
                                                    currentDate.year !=
                                                        prevDate.year ||
                                                    currentDate.month !=
                                                        prevDate.month ||
                                                    currentDate.day !=
                                                        prevDate.day;
                                              } else {
                                                showDateHeader = true;
                                              }
                                              final prevMessage =
                                                  prevMessageIndex >= 0
                                                  ? _messages[prevMessageIndex]
                                                  : null;
                                              final isGrouped =
                                                  !showDateHeader &&
                                                  _isSameSender(
                                                    prevMessage,
                                                    message,
                                                  );

                                              return AutoScrollTag(
                                                key: ValueKey(messageId),
                                                controller: _scrollController,
                                                index: index,
                                                highlightColor: AppColors.green
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
                                                          child: _buildDateChip(
                                                            message.time,
                                                          ),
                                                        ),
                                                      ),
                                                    if (showDateHeader)
                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                    ThreadMessageTile(
                                                      threadId:
                                                          widget.staffInfo['code']
                                                              as String,
                                                      messageCode: message.code,
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
                                                                widget.staffInfo['code']
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
                                                            widget.staffInfo['code']
                                                                as String,
                                                            msg,
                                                          ),
                                                      currentUserCode:
                                                          _currentUserCode,
                                                      reactionsController:
                                                          _reactionsController,
                                                      onScrollToQuoted:
                                                          (quoteId) {
                                                            _scrollToMessage(
                                                              quoteId,
                                                            );
                                                          },
                                                      onReply: message.isDeleted
                                                          ? null
                                                          : () {
                                                              setState(() {
                                                                _quotedMessageCode =
                                                                    message.id;
                                                                _quotedMessage =
                                                                    message;
                                                              });
                                                            },
                                                      onReplyFromMenu:
                                                          message.isDeleted
                                                          ? null
                                                          : () {
                                                              setState(() {
                                                                _quotedMessageCode =
                                                                    message.id;
                                                                _quotedMessage =
                                                                    message;
                                                              });
                                                            },
                                                      onCopy: () {
                                                        Clipboard.setData(
                                                          ClipboardData(
                                                            text: message.text,
                                                          ),
                                                        );
                                                        CoreUtils.showTopSnackBar(
                                                          context: context,
                                                          message:
                                                              'Message copied successfully',
                                                          isSuccess: true,
                                                        );
                                                      },
                                                      onEdit: () =>
                                                          _showEditDialog(
                                                            context,
                                                            message,
                                                          ),
                                                      onDelete: () =>
                                                          _deleteMessageWithFeedback(
                                                            message.code,
                                                          ),
                                                      onInfo: () =>
                                                          _showMessageStatusDialog(
                                                            context,
                                                            message,
                                                          ),
                                                      onReactionAdded:
                                                          (emoji) =>
                                                              _onReactionAdded(
                                                                message,
                                                                emoji,
                                                              ),
                                                      onRemoveReaction: (emoji) {
                                                        context
                                                            .read<
                                                              CommunicationCubit
                                                            >()
                                                            .removeReaction(
                                                              widget.staffInfo['code']
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
                                                      onReactionsInfoTap: () =>
                                                          _showReactionInfoDialog(
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
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 8,
                                          child: ValueListenableBuilder<bool>(
                                            valueListenable: _scrollBehavior
                                                .showNewMessageIndicator,
                                            builder: (_, visible, __) =>
                                                NewMessagesIndicator(
                                                  visible: visible,
                                                  onTap: () => _scrollBehavior
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
                                                state is CommunicationLoaded &&
                                                state.isLoadingOlderMessages,
                                          ),
                                        ),
                                        if (!_isPositionedAtBottom)
                                          const Positioned.fill(
                                            child: ChatThreadShimmer(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              child: _buildMessageInput(state),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shown when the thread has loaded successfully but has no messages yet —
  /// the input bar stays usable so the user can start the conversation,
  /// unlike the loading/error states which replace the whole screen.
  Widget _buildEmptyConversationState(
    BuildContext context,
    CommunicationState state,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
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
                      fontColor: AppColors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: _buildMessageInput(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True for a backend "you're not a participant of this conversation"
  /// response (403 Access denied) — happens for a conversation that was
  /// never actually created properly (or one created before the creator's
  /// own code was always included as a participant). Retrying the same
  /// load will just 403 again forever, so this gets a different message/CTA
  /// than a transient network failure.
  bool _isUnauthorizedConversationError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('access denied') ||
        lower.contains('not authorized') ||
        lower.contains('403');
  }

  /// Back button, avatar + online dot, name, and info icon — shown above the
  /// message list on every state (loading/error/empty/loaded) so opening a
  /// brand-new conversation (which starts out empty) still shows who you're
  /// talking to instead of a bare screen with no way back but the OS gesture.
  Widget _buildThreadHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                  size: 20,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              children: [
                DocumentImageWidget(
                  disableAttendanceStatusLookup: true,
                  fileUuid: '',
                  imageUrl: _staffAvatarAsImageUrl,
                  mediaAssetCode: _staffAvatarAsMediaAssetCode,
                  name: widget.staffInfo['name'],
                  size: 45,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: (widget.staffInfo['isSigned'] ?? false)
                          ? const Color.fromRGBO(0, 177, 21, 1)
                          : AppColors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (widget.staffInfo['isSigned'] ?? false)
                            ? AppColors.white
                            : AppColors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextWidget(
                      text: widget.staffInfo['name'],
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: CustomTextWidget(
                            text: widget.staffInfo['name'],
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.staffInfo['designation'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Designation: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: widget.staffInfo['designation']
                                              .toString(),
                                          style: const TextStyle(
                                            color: AppColors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (widget.staffInfo['email'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Email: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: widget.staffInfo['email']
                                              .toString(),
                                          style: const TextStyle(
                                            color: AppColors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when [CommunicationCubit] has no cached history to fall back on
  /// and the latest fetch failed — gives the user a way to retry instead of
  /// staring at a blank screen. A 403/"not authorized" failure means this
  /// conversation was never actually created properly, so it offers "Go
  /// back" instead of a "Retry" that would just fail the same way again.
  Widget _buildErrorState(String message) {
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
              color: isUnauthorized ? AppColors.grey : AppColors.redAccent,
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
                  ? 'Go back and start a new conversation with this person.'
                  : message,
              fontSize: 13,
              fontColor: AppColors.grey[600],
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (isUnauthorized) {
                  Navigator.of(context).pop();
                  return;
                }
                final threadId = widget.staffInfo['code'] as String;
                context.read<CommunicationCubit>().loadMessages(
                  threadId,
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
                  fontColor: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(CommunicationState state) {
    return SafeArea(
      child: ChatInputBar(
        controller: _controller,
        onSend: _sendMessage,
        onAttachmentTap: _showAttachmentPicker,
        isSending: state is CommunicationSending,
        enabled: !_staffInactive && !_currentUserInactive,
        disabledMessage: _currentUserInactive
            ? 'Your staff account is inactive. You can no longer send '
                  'messages.'
            : 'This staff member is inactive. You can no longer send '
                  'messages.',
        pendingAttachments: _pendingAttachments,
        quotedMessage: _quotedMessage,
        showCharCounter: true,
        onCancelQuote: () => setState(() {
          _quotedMessage = null;
          _quotedMessageCode = null;
        }),
        onRemoveAttachment: (i) =>
            setState(() => _pendingAttachments.removeAt(i)),
      ),
    );
  }

  void _showAttachmentPicker() {
    unawaited(
      MessageAttachmentBottomSheet.show(
        context,
        onAttachmentsSelected: (attachments) {
          if (attachments.isEmpty) return;
          // Add to whatever's already staged — picking multiple photos/
          // videos together (or picking again before sending) must
          // accumulate, not discard everything but the newest single file.
          setState(
            () =>
                _pendingAttachments = [..._pendingAttachments, ...attachments],
          );
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
        onAttachmentError: (message) {
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message: message,
            isError: true,
          );
        },
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final schoolDate = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      date,
      schoolTz,
    );
    final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      ServerTimeService.instance.nowUtc(),
      schoolTz,
    );

    // Matches web's groupMessagesByDate (ChatMessageArea.tsx): "Today" /
    // "Yesterday" alone, with no date suffix — mobile used to append the
    // full date after those labels ("Today, 12 August 2026"), which web
    // never does.
    String label;
    if (schoolDate.year == schoolNow.year &&
        schoolDate.month == schoolNow.month &&
        schoolDate.day == schoolNow.day) {
      label = 'Today';
    } else if (schoolDate.year == schoolNow.year &&
        schoolDate.month == schoolNow.month &&
        schoolDate.day == schoolNow.day - 1) {
      label = 'Yesterday';
    } else {
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

  /// Resolves a receipt to a display name. Realtime receipts carry an empty
  /// [RecipientStatus.name], so fall back to the 1:1 counterpart's name from
  /// [staffInfo] ('You' for the current user) — never the raw user code.
  String _resolveRecipientName(RecipientStatus r) {
    if (r.name.trim().isNotEmpty) return r.name.trim();
    final code = r.userId;
    if (code != null && code.isNotEmpty && code == _currentUserCode) {
      return 'You';
    }
    final counterpart = (widget.staffInfo['name'] as String?)?.trim() ?? '';
    if (counterpart.isNotEmpty) return counterpart;
    return 'Participant';
  }

  /// Resolves a receipt's role — 'You' for the current user, else the 1:1
  /// counterpart's designation from [staffInfo].
  String? _resolveRecipientRole(RecipientStatus r) {
    final code = r.userId;
    if (code != null && code.isNotEmpty && code == _currentUserCode) {
      return null;
    }
    return (widget.staffInfo['designation'] as String?)?.trim();
  }

  /// Resolves a receipt's avatar — the 1:1 counterpart's photo from
  /// [staffInfo] (null for the current user; the dialog shows "You").
  String? _resolveRecipientAvatar(RecipientStatus r) {
    final code = r.userId;
    if (code != null && code.isNotEmpty && code == _currentUserCode) {
      return null;
    }
    return (widget.staffInfo['avatar'] as String?)?.trim();
  }

  MessageInfoRecipient _toInfoRecipient(
    RecipientStatus r, {
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return MessageInfoRecipient(
      name: _resolveRecipientName(r),
      // The receipt row carries the recipient's own role directly —
      // prefer it over the static staffInfo designation.
      role: r.role ?? _resolveRecipientRole(r),
      avatarSource: _resolveRecipientAvatar(r),
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  void _showMessageStatusDialog(BuildContext context, Message message) {
    // Fetch fresh from the dedicated per-message receipts endpoint — the
    // message's own embedded receipts field is a lighter shape that
    // doesn't reliably carry userName/role.
    final cubit = context.read<CommunicationCubit>();
    Future<List<MessageInfoRecipient>> fetchRecipients() async {
      final receipts = await cubit.fetchMessageReceipts(message.code);
      // Rows are already mutually exclusive per-row (see
      // MessageModel._parseRecipientStatuses) — no cross-row dedup by
      // userCode belongs here.
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

  void _showReactionInfoDialog(BuildContext context, Message message) {
    final people = message.reactions.map((r) {
      final isMe = r.userCode == _currentUserCode;
      final name = isMe
          ? 'You'
          : ((widget.staffInfo['name'] as String?)?.trim().isNotEmpty == true
                ? (widget.staffInfo['name'] as String).trim()
                : 'Participant');
      return ReactionPerson(
        emoji: r.emoji,
        name: name,
        // The reaction row carries the reactor's own role directly —
        // prefer it over the static staffInfo designation.
        role:
            r.role ??
            (isMe
                ? null
                : (widget.staffInfo['designation'] as String?)?.trim()),
        avatarSource: isMe
            ? null
            : (widget.staffInfo['avatar'] as String?)?.trim(),
      );
    }).toList();

    ReactionInfoDialog.show(context, reactions: people);
  }
}
