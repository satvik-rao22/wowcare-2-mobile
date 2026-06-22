import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_input_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import '../util/message_content_processor.dart';
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
import '../util/chat_scroll_behavior.dart';
import '../widgets/chat_thread_shimmer.dart';
import '../widgets/loading_older_indicator.dart';
import '../widgets/new_messages_indicator.dart';
import '../widgets/thread_message_tile.dart';

class ParentMessagingThread extends StatefulWidget {
  const ParentMessagingThread({
    super.key,
    required this.parentInfo,
    this.showOwnScaffold = true,
  });
  final Map<String, dynamic> parentInfo;

  /// When false the widget renders only its body content (no [GlobalScaffold]).
  /// Use this when embedding the thread inside another scaffold.
  final bool showOwnScaffold;

  @override
  State<ParentMessagingThread> createState() => _ParentMessagingThreadState();
}

class _ParentMessagingThreadState extends State<ParentMessagingThread>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();

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

  bool isPrivateModeEnabled(Map<String, dynamic> parentInfo) {
    final privateParents =
        parentInfo['privateModeParents'] as List<dynamic>? ?? [];
    return privateParents.isNotEmpty;
  }

  bool _isParentInPrivateMode(String parentName) {
    final privateParents =
        widget.parentInfo['privateModeParents'] as List<dynamic>? ?? [];
    return privateParents.contains(parentName);
  }

  bool get _privateModeEnabled => isPrivateModeEnabled(widget.parentInfo);

  late final String parent1Name;
  late final String parent2Name;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reactionsController = ReactionsController(currentUserId: '');
    final parents =
        (widget.parentInfo['parents'] as List<dynamic>?)?.cast<String>() ?? [];
    parent1Name = parents.isNotEmpty ? parents[0] : 'Parent 1';
    parent2Name = parents.length > 1 ? parents[1] : 'Parent 2';

    _tabController = TabController(
      length: _privateModeEnabled ? 2 : 1,
      vsync: this,
    );

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
      });
      final convCode = widget.parentInfo['code'] as String;
      AppLogger.d(
        '[ParentThread] loading messages for $convCode '
        'currentUserId=$currentUserId',
      );
      await context.read<CommunicationCubit>().loadMessages(
        convCode,
        currentUserId: currentUserId,
      );
      if (!mounted) return;
      // Realtime listener starts only after the API/Isar history has
      // loaded — Firestore only ever applies deltas on top of it.
      context.read<CommunicationCubit>().startWatchingThread(convCode);
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
    if (position.maxScrollExtent - position.pixels > _loadOlderScrollThreshold) {
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
    // Sending always scrolls to bottom, regardless of scroll position.
    // Other growth (realtime/API) only scrolls when already near bottom.
    if (wasOwnSend) {
      _getActiveScrollBehavior().scrollToBottom();
    } else {
      _getActiveScrollBehavior().onIncomingMessage();
    }
  }

  AutoScrollController _getActiveScrollController() {
    if (!_privateModeEnabled) return _groupController;
    return _tabController?.index == 0 ? _parent1Controller : _parent2Controller;
  }

  ChatScrollBehavior _getActiveScrollBehavior() {
    if (!_privateModeEnabled) return _groupScrollBehavior;
    return _tabController?.index == 0
        ? _parent1ScrollBehavior
        : _parent2ScrollBehavior;
  }

  String? _getTagetParentForCurrentTab() {
    if (!_privateModeEnabled) return null;
    return _tabController?.index == 0 ? parent1Name : parent2Name;
  }

  List<Message> get _activeMessages {
    final state = context.read<CommunicationCubit>().state;
    if (state is CommunicationLoaded) {
      final threadId = widget.parentInfo['code'] as String;
      return state.threads[threadId] ?? [];
    }
    return [];
  }

  void _sendMessage() {
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

    List<String> receivers = [];
    receivers.addAll(
      (widget.parentInfo['staffList'] as List<dynamic>? ?? []).cast<String>(),
    );

    if (_privateModeEnabled) {
      final targetParent = _getTagetParentForCurrentTab();
      if (targetParent != null) {
        receivers.add(targetParent);
      }
    } else {
      receivers.addAll(
        (widget.parentInfo['parents'] as List<dynamic>? ?? []).cast<String>(),
      );
    }

    final authState = context.read<AuthCubit>().state;
    final senderName = authState is AuthLoaded
        ? authState.loginResponse.displayName
        : _currentSender;

    _ownSendPending = true;
    context.read<CommunicationCubit>().sendMessage(
      widget.parentInfo['code'] as String,
      text,
      attachments: List.from(_pendingAttachments),
      quotedMessageId: _quotedMessageId,
      senderName: senderName,
      senderUserCode: _currentUserCode,
      receivers: receivers,
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
            (MediaQuery.of(sheetContext).size.height * 0.55).clamp(240.0, 400.0) +
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
              final myReaction = message.reactions[_currentUserCode ?? 'me'];
              if (myReaction == emoji.emoji) {
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

  void _startEditing(Message message) {
    setState(() {
      _editingMessage = message;
      _controller.text = MessageContentProcessor.stripHtmlTags(message.text);
    });
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final tabNames = _privateModeEnabled
        ? [parent1Name, parent2Name]
        : ['${parent1Name}, ${parent2Name} and Staff'];

    return BlocConsumer<CommunicationCubit, CommunicationState>(
      listener: (context, state) {
        if (state is CommunicationLoaded) {
          _onMessagesChanged(_activeMessages);
        }
      },
      builder: (context, state) {
        final _messages = _activeMessages;
        if ((state is CommunicationLoading && _messages.isEmpty) ||
            (_messages.isNotEmpty && !_isPositionedAtBottom)) {
          if (!widget.showOwnScaffold) return const ChatThreadShimmer();
          return Scaffold(
            body: const ChatThreadShimmer(),
          );
        }
        if (state is CommunicationError && _messages.isEmpty) {
          final errorBody = _buildErrorState(context, state.message);
          if (!widget.showOwnScaffold) return errorBody;
          return Scaffold(body: SafeArea(child: errorBody));
        }
        if (state is CommunicationLoaded && _messages.isEmpty) {
          final emptyBody = _buildEmptyConversationState(context);
          if (!widget.showOwnScaffold) return emptyBody;
          return Scaffold(body: SafeArea(child: emptyBody));
        }
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
                          headerSliverBuilder: (context, innerBoxIsScrolled) => [
                            SliverToBoxAdapter(
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                padding: EdgeInsets.all(0),
                                labelColor: AppColors.primaryColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppColors.themeColor,
                                dividerColor: Colors.transparent,
                                //tabs: tabNames.map((name) => Tab(text: name,)).toList(),
                                tabs: tabNames
                                    .map((name) => _buildTab(name))
                                    .toList(),
                              ),
                            ),
                          ],
                          body: TabBarView(
                            controller: _tabController,
                            children: _privateModeEnabled
                                ? [
                                    Stack(
                                      children: [
                                    ListView.builder(
                                      controller: _getActiveScrollController(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      reverse: true,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message =
                                            _messages[_messages.length -
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
                                            _messages.length - 2 - index;

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
                                              _currDate.day != _prevDate.day;
                                        } else {
                                          showDateHeader = true;
                                        }
                                        final prevMessage = prevListIndex >= 0
                                            ? _messages[prevListIndex]
                                            : null;
                                        final isGrouped =
                                            !showDateHeader &&
                                            _isSameSender(prevMessage, message);

                                        return AutoScrollTag(
                                          key: ValueKey(messageId),
                                          controller:
                                              _getActiveScrollController(),
                                          index: index,
                                          highlightColor: Colors.green
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
                                              SizedBox(height: isGrouped ? 2.0 : 8.0),
                                              ThreadMessageTile(
                                                threadId: widget.parentInfo['code']
                                                    as String,
                                                messageCode: message.code,
                                                quotedMessageId:
                                                    message.quotedMessageId,
                                                onDeleteAttachment: (attachment) {
                                                  if (attachment.attachmentId != null) {
                                                    context.read<CommunicationCubit>().deleteAttachment(
                                                      widget.parentInfo['code'] as String,
                                                      attachment.attachmentId!,
                                                    );
                                                  }
                                                },
                                                currentUserCode:
                                                    _currentUserCode,
                                                reactionsController:
                                                    _reactionsController,
                                                isParentMessaging: true,
                                                onReplyFromMenu: message.isDeleted
                                                    ? null
                                                    : () {
                                                  setState(() {
                                                    _quotedMessageId =
                                                        message.id;
                                                    _quotedMessage = message;
                                                  });
                                                },
                                                onCopy: message.isDeleted
                                                    ? null
                                                    : () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: MessageContentProcessor.stripHtmlTags(message.text),
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
                                                    : () =>
                                                    _startEditing(message),
                                                onDelete: message.isDeleted
                                                    ? null
                                                    : () {
                                                  context
                                                      .read<
                                                        CommunicationCubit
                                                      >()
                                                      .deleteMessage(
                                                        widget.parentInfo['code']
                                                            as String,
                                                        message.code,
                                                      );
                                                  CoreUtils.showTopSnackBar(
                                                    context: context,
                                                    message:
                                                        'Message deleted successfully',
                                                    isSuccess: true,
                                                  );
                                                },
                                                onInfo: message.isDeleted
                                                    ? null
                                                    : () =>
                                                    _showMessageStatusDialog(
                                                      context,
                                                      message,
                                                    ),
                                                onScrollToQuoted: (quoteId) {
                                                  _scrollToMessage(quoteId);
                                                },
                                                onReactionAdded: (emoji) {
                                                  final myReaction =
                                                      message
                                                          .reactions[_currentUserCode ??
                                                          'me'];
                                                  if (myReaction == emoji) {
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
                                                  } else {
                                                    context
                                                        .read<
                                                          CommunicationCubit
                                                        >()
                                                        .addReaction(
                                                          widget.parentInfo['code']
                                                              as String,
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
                                          valueListenable: _getActiveScrollBehavior()
                                              .showNewMessageIndicator,
                                          builder: (_, visible, __) =>
                                              NewMessagesIndicator(
                                            visible: visible,
                                            onTap: () => _getActiveScrollBehavior()
                                                .scrollToBottom(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        child: LoadingOlderIndicator(
                                          visible: state is CommunicationLoaded &&
                                              state.isLoadingOlderMessages,
                                        ),
                                      ),
                                      ],
                                    ),
                                    Stack(
                                      children: [
                                    ListView.builder(
                                      controller: _getActiveScrollController(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      reverse: true,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message =
                                            _messages[_messages.length -
                                                1 -
                                                index];
                                        final messageId = message.id;

                                        bool showDateHeader = false;
                                        final prevListIndex =
                                            _messages.length - 2 - index;

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
                                              _currDate.day != _prevDate.day;
                                        } else {
                                          showDateHeader = true;
                                        }
                                        final prevMessage = prevListIndex >= 0
                                            ? _messages[prevListIndex]
                                            : null;
                                        final isGrouped =
                                            !showDateHeader &&
                                            _isSameSender(prevMessage, message);

                                        return AutoScrollTag(
                                          key: ValueKey(messageId),
                                          controller:
                                              _getActiveScrollController(),
                                          index: index,
                                          highlightColor: Colors.green
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
                                              SizedBox(height: isGrouped ? 2.0 : 8.0),
                                              ThreadMessageTile(
                                                threadId: widget.parentInfo['code']
                                                    as String,
                                                messageCode: message.code,
                                                quotedMessageId:
                                                    message.quotedMessageId,
                                                onDeleteAttachment: (attachment) {
                                                  if (attachment.attachmentId != null) {
                                                    context.read<CommunicationCubit>().deleteAttachment(
                                                      widget.parentInfo['code'] as String,
                                                      attachment.attachmentId!,
                                                    );
                                                  }
                                                },
                                                currentUserCode:
                                                    _currentUserCode,
                                                reactionsController:
                                                    _reactionsController,
                                                isParentMessaging: true,
                                                onReplyFromMenu: message.isDeleted
                                                    ? null
                                                    : () {
                                                  setState(() {
                                                    _quotedMessageId =
                                                        message.id;
                                                    _quotedMessage = message;
                                                  });
                                                },
                                                onCopy: message.isDeleted
                                                    ? null
                                                    : () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: MessageContentProcessor.stripHtmlTags(message.text),
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
                                                    : () =>
                                                    _startEditing(message),
                                                onDelete: message.isDeleted
                                                    ? null
                                                    : () {
                                                  context
                                                      .read<
                                                        CommunicationCubit
                                                      >()
                                                      .deleteMessage(
                                                        widget.parentInfo['code']
                                                            as String,
                                                        message.code,
                                                      );
                                                  CoreUtils.showTopSnackBar(
                                                    context: context,
                                                    message:
                                                        'Message deleted successfully',
                                                    isSuccess: true,
                                                  );
                                                },
                                                onInfo: message.isDeleted
                                                    ? null
                                                    : () =>
                                                    _showMessageStatusDialog(
                                                      context,
                                                      message,
                                                    ),
                                                onScrollToQuoted: (quoteId) {
                                                  _scrollToMessage(quoteId);
                                                },
                                                onReactionAdded: (emoji) {
                                                  final myReaction =
                                                      message
                                                          .reactions[_currentUserCode ??
                                                          'me'];
                                                  if (myReaction == emoji) {
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
                                                  } else {
                                                    context
                                                        .read<
                                                          CommunicationCubit
                                                        >()
                                                        .addReaction(
                                                          widget.parentInfo['code']
                                                              as String,
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
                                          valueListenable: _getActiveScrollBehavior()
                                              .showNewMessageIndicator,
                                          builder: (_, visible, __) =>
                                              NewMessagesIndicator(
                                            visible: visible,
                                            onTap: () => _getActiveScrollBehavior()
                                                .scrollToBottom(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        child: LoadingOlderIndicator(
                                          visible: state is CommunicationLoaded &&
                                              state.isLoadingOlderMessages,
                                        ),
                                      ),
                                      ],
                                    ),
                                  ]
                                : [
                                    Stack(
                                      children: [
                                    ListView.builder(
                                      controller: _getActiveScrollController(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      reverse: true,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message =
                                            _messages[_messages.length -
                                                1 -
                                                index];
                                        final messageId = message.id;
                                        bool showDateHeader = false;
                                        final prevListIndex =
                                            _messages.length - 2 - index;

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
                                              _currDate.day != _prevDate.day;
                                        } else {
                                          showDateHeader = true;
                                        }
                                        final prevMessage = prevListIndex >= 0
                                            ? _messages[prevListIndex]
                                            : null;
                                        final isGrouped =
                                            !showDateHeader &&
                                            _isSameSender(prevMessage, message);

                                        return AutoScrollTag(
                                          key: ValueKey(messageId),
                                          controller:
                                              _getActiveScrollController(),
                                          index: index,
                                          highlightColor: Colors.green
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
                                              SizedBox(height: isGrouped ? 2.0 : 8.0),
                                              ThreadMessageTile(
                                                threadId: widget.parentInfo['code']
                                                    as String,
                                                messageCode: message.code,
                                                quotedMessageId:
                                                    message.quotedMessageId,
                                                onDeleteAttachment: (attachment) {
                                                  if (attachment.attachmentId != null) {
                                                    context.read<CommunicationCubit>().deleteAttachment(
                                                      widget.parentInfo['code'] as String,
                                                      attachment.attachmentId!,
                                                    );
                                                  }
                                                },
                                                currentUserCode:
                                                    _currentUserCode,
                                                reactionsController:
                                                    _reactionsController,
                                                isParentMessaging: true,
                                                onReplyFromMenu: message.isDeleted
                                                    ? null
                                                    : () {
                                                  setState(() {
                                                    _quotedMessageId =
                                                        message.id;
                                                    _quotedMessage = message;
                                                  });
                                                },
                                                onCopy: message.isDeleted
                                                    ? null
                                                    : () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: MessageContentProcessor.stripHtmlTags(message.text),
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
                                                    : () =>
                                                    _startEditing(message),
                                                onDelete: message.isDeleted
                                                    ? null
                                                    : () {
                                                  context
                                                      .read<
                                                        CommunicationCubit
                                                      >()
                                                      .deleteMessage(
                                                        widget.parentInfo['code']
                                                            as String,
                                                        message.code,
                                                      );
                                                  CoreUtils.showTopSnackBar(
                                                    context: context,
                                                    message:
                                                        'Message deleted successfully',
                                                    isSuccess: true,
                                                  );
                                                },
                                                onInfo: message.isDeleted
                                                    ? null
                                                    : () =>
                                                    _showMessageStatusDialog(
                                                      context,
                                                      message,
                                                    ),
                                                onScrollToQuoted: (quoteId) {
                                                  _scrollToMessage(quoteId);
                                                },
                                                onReactionAdded: (emoji) {
                                                  final myReaction =
                                                      message
                                                          .reactions[_currentUserCode ??
                                                          'me'];
                                                  if (myReaction == emoji) {
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
                                                  } else {
                                                    context
                                                        .read<
                                                          CommunicationCubit
                                                        >()
                                                        .addReaction(
                                                          widget.parentInfo['code']
                                                              as String,
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
                                          valueListenable: _getActiveScrollBehavior()
                                              .showNewMessageIndicator,
                                          builder: (_, visible, __) =>
                                              NewMessagesIndicator(
                                            visible: visible,
                                            onTap: () => _getActiveScrollBehavior()
                                                .scrollToBottom(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        child: LoadingOlderIndicator(
                                          visible: state is CommunicationLoaded &&
                                              state.isLoadingOlderMessages,
                                        ),
                                      ),
                                      ],
                                    ),
                                  ],
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
                            //const SizedBox(height: 10,),
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              padding: EdgeInsets.all(0),
                              labelColor: AppColors.primaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppColors.themeColor,
                              dividerColor: Colors.transparent,
                              //tabs: tabNames.map((name) => Tab(text: name,)).toList(),
                              tabs: tabNames
                                  .map((name) => _buildTab(name))
                                  .toList(),
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: _privateModeEnabled
                                    ? [
                                        Stack(
                                          children: [
                                        ListView.builder(
                                          controller:
                                              _getActiveScrollController(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          reverse: true,
                                          itemCount: _messages.length,
                                          itemBuilder: (context, index) {
                                            final message =
                                                _messages[_messages.length -
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
                                                _messages.length - 2 - index;

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
                                            final prevMessage = prevListIndex >= 0
                                                ? _messages[prevListIndex]
                                                : null;
                                            final isGrouped =
                                                !showDateHeader &&
                                                _isSameSender(prevMessage, message);

                                            return AutoScrollTag(
                                              key: ValueKey(messageId),
                                              controller:
                                                  _getActiveScrollController(),
                                              index: index,
                                              highlightColor: Colors.green
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

                                                  ThreadMessageTile(
                                                    threadId: widget.parentInfo['code']
                                                        as String,
                                                    messageCode: message.code,
                                                    quotedMessageId:
                                                        message.quotedMessageId,
                                                    onDeleteAttachment: (attachment) {
                                                      if (attachment.attachmentId != null) {
                                                        context.read<CommunicationCubit>().deleteAttachment(
                                                          widget.parentInfo['code'] as String,
                                                          attachment.attachmentId!,
                                                        );
                                                      }
                                                    },
                                                    currentUserCode:
                                                        _currentUserCode,
                                                    reactionsController:
                                                        _reactionsController,
                                                    isParentMessaging: true,
                                                    onReplyFromMenu: () {
                                                      setState(() {
                                                        _quotedMessageId =
                                                            message.id;
                                                        _quotedMessage =
                                                            message;
                                                      });
                                                    },
                                                    onCopy: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: MessageContentProcessor.stripHtmlTags(message.text),
                                                        ),
                                                      );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message copied',
                                                        isSuccess: true,
                                                      );
                                                    },
                                                    onEdit: () {
                                                      setState(() {
                                                        _editingMessage =
                                                            message;
                                                        _controller.text =
                                                            MessageContentProcessor.stripHtmlTags(message.text);
                                                        _inputFocusNode
                                                            .requestFocus();
                                                      });
                                                    },
                                                    onDelete: () {
                                                      context
                                                          .read<
                                                            CommunicationCubit
                                                          >()
                                                          .deleteMessage(
                                                            widget.parentInfo['code']
                                                                as String,
                                                            message.code,
                                                          );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message deleted',
                                                        isSuccess: true,
                                                      );
                                                    },
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
                                                      final myReaction =
                                                          message
                                                              .reactions[_currentUserCode ??
                                                              'me'];
                                                      if (myReaction == emoji) {
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
                                                      } else {
                                                        context
                                                            .read<
                                                              CommunicationCubit
                                                            >()
                                                            .addReaction(
                                                              widget.parentInfo['code']
                                                                  as String,
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
                                              visible: state is CommunicationLoaded &&
                                                  state.isLoadingOlderMessages,
                                            ),
                                          ),
                                          ],
                                        ),
                                        Stack(
                                          children: [
                                        ListView.builder(
                                          controller:
                                              _getActiveScrollController(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          reverse: true,
                                          itemCount: _messages.length,
                                          itemBuilder: (context, index) {
                                            final message =
                                                _messages[_messages.length -
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
                                                _messages.length - 2 - index;

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
                                            final prevMessage = prevListIndex >= 0
                                                ? _messages[prevListIndex]
                                                : null;
                                            final isGrouped =
                                                !showDateHeader &&
                                                _isSameSender(prevMessage, message);

                                            return AutoScrollTag(
                                              key: ValueKey(messageId),
                                              controller:
                                                  _getActiveScrollController(),
                                              index: index,
                                              highlightColor: Colors.green
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

                                                  ThreadMessageTile(
                                                    threadId: widget.parentInfo['code']
                                                        as String,
                                                    messageCode: message.code,
                                                    quotedMessageId:
                                                        message.quotedMessageId,
                                                    onDeleteAttachment: (attachment) {
                                                      if (attachment.attachmentId != null) {
                                                        context.read<CommunicationCubit>().deleteAttachment(
                                                          widget.parentInfo['code'] as String,
                                                          attachment.attachmentId!,
                                                        );
                                                      }
                                                    },
                                                    currentUserCode:
                                                        _currentUserCode,
                                                    reactionsController:
                                                        _reactionsController,
                                                    isParentMessaging: true,
                                                    onReplyFromMenu: () {
                                                      setState(() {
                                                        _quotedMessageId =
                                                            message.id;
                                                        _quotedMessage =
                                                            message;
                                                      });
                                                    },
                                                    onCopy: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: MessageContentProcessor.stripHtmlTags(message.text),
                                                        ),
                                                      );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message copied',
                                                        isSuccess: true,
                                                      );
                                                    },
                                                    onEdit: () {
                                                      setState(() {
                                                        _editingMessage =
                                                            message;
                                                        _controller.text =
                                                            MessageContentProcessor.stripHtmlTags(message.text);
                                                        _inputFocusNode
                                                            .requestFocus();
                                                      });
                                                    },
                                                    onDelete: () {
                                                      context
                                                          .read<
                                                            CommunicationCubit
                                                          >()
                                                          .deleteMessage(
                                                            widget.parentInfo['code']
                                                                as String,
                                                            message.code,
                                                          );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message deleted',
                                                        isSuccess: true,
                                                      );
                                                    },
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
                                                      final myReaction =
                                                          message
                                                              .reactions[_currentUserCode ??
                                                              'me'];
                                                      if (myReaction == emoji) {
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
                                                      } else {
                                                        context
                                                            .read<
                                                              CommunicationCubit
                                                            >()
                                                            .addReaction(
                                                              widget.parentInfo['code']
                                                                  as String,
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
                                              visible: state is CommunicationLoaded &&
                                                  state.isLoadingOlderMessages,
                                            ),
                                          ),
                                          ],
                                        ),
                                      ]
                                    : [
                                        Stack(
                                          children: [
                                        ListView.builder(
                                          controller:
                                              _getActiveScrollController(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          reverse: true,
                                          itemCount: _messages.length,
                                          itemBuilder: (context, index) {
                                            final message =
                                                _messages[_messages.length -
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
                                                _messages.length - 2 - index;

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
                                            final prevMessage = prevListIndex >= 0
                                                ? _messages[prevListIndex]
                                                : null;
                                            final isGrouped =
                                                !showDateHeader &&
                                                _isSameSender(prevMessage, message);

                                            return AutoScrollTag(
                                              key: ValueKey(messageId),
                                              controller:
                                                  _getActiveScrollController(),
                                              index: index,
                                              highlightColor: Colors.green
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

                                                  ThreadMessageTile(
                                                    threadId: widget.parentInfo['code']
                                                        as String,
                                                    messageCode: message.code,
                                                    quotedMessageId:
                                                        message.quotedMessageId,
                                                    onDeleteAttachment: (attachment) {
                                                      if (attachment.attachmentId != null) {
                                                        context.read<CommunicationCubit>().deleteAttachment(
                                                          widget.parentInfo['code'] as String,
                                                          attachment.attachmentId!,
                                                        );
                                                      }
                                                    },
                                                    currentUserCode:
                                                        _currentUserCode,
                                                    reactionsController:
                                                        _reactionsController,
                                                    isParentMessaging: true,
                                                    onReplyFromMenu: () {
                                                      setState(() {
                                                        _quotedMessageId =
                                                            message.id;
                                                        _quotedMessage =
                                                            message;
                                                      });
                                                    },
                                                    onCopy: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: MessageContentProcessor.stripHtmlTags(message.text),
                                                        ),
                                                      );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message copied',
                                                        isSuccess: true,
                                                      );
                                                    },
                                                    onEdit: () {
                                                      setState(() {
                                                        _editingMessage =
                                                            message;
                                                        _controller.text =
                                                            MessageContentProcessor.stripHtmlTags(message.text);
                                                        _inputFocusNode
                                                            .requestFocus();
                                                      });
                                                    },
                                                    onDelete: () {
                                                      context
                                                          .read<
                                                            CommunicationCubit
                                                          >()
                                                          .deleteMessage(
                                                            widget.parentInfo['code']
                                                                as String,
                                                            message.code,
                                                          );
                                                      CoreUtils.showTopSnackBar(
                                                        context: context,
                                                        message:
                                                            'Message deleted',
                                                        isSuccess: true,
                                                      );
                                                    },
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
                                                      final myReaction =
                                                          message
                                                              .reactions[_currentUserCode ??
                                                              'me'];
                                                      if (myReaction == emoji) {
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
                                                      } else {
                                                        context
                                                            .read<
                                                              CommunicationCubit
                                                            >()
                                                            .addReaction(
                                                              widget.parentInfo['code']
                                                                  as String,
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
                                              visible: state is CommunicationLoaded &&
                                                  state.isLoadingOlderMessages,
                                            ),
                                          ),
                                          ],
                                        ),
                                      ],
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
        if (!widget.showOwnScaffold) return threadBody;
        return Scaffold(
          body: SafeArea(
            child: threadBody,
          ),
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
                      fontColor: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
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
      ),
    );
  }

  /// Shown when [CommunicationCubit] has no cached history to fall back on
  /// and the latest fetch failed — gives the user a way to retry instead of
  /// staring at a blank screen.
  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const CustomTextWidget(
              text: 'Unable to load messages',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 6),
            CustomTextWidget(
              text: message,
              fontSize: 13,
              fontColor: Colors.grey[600],
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
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
                child: const CustomTextWidget(
                  text: 'Retry',
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
    final raw = widget.parentInfo['participants'];
    if (raw is List) {
      return raw.whereType<ConversationParticipant>().toList();
    }
    return [];
  }


  List<ParticipantDisplayData> get _participantDisplayData =>
      _participants.map((p) {
        final roleStr = p.role.toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
        );
      }).toList();

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
        // Only one attachment may be pending at a time — a new pick
        // replaces whatever was previously staged.
        setState(() {
          _pendingAttachments = [attachments.first];
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
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
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
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          DocumentImageWidget(
            fileUuid: widget.parentInfo['avatar'] as String? ?? '',
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
          // Private mode toggle inline with the title row
          if (_privateModeEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Private Mode ON',
                child: Icon(
                  Icons.visibility_off,
                  size: 18,
                  color: Colors.red.shade400,
                ),
              ),
            ),
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
    );
  }

  Widget _buildDateChip(DateTime date) {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final schoolDate = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      date,
      schoolTz,
    );
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
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

    return CustomTextWidget(
      text: label,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      applyLetterSpacing: false,
    );
  }

  Widget _buildTab(String name) {
    final bool isPrivate = _privateModeEnabled && _isParentInPrivateMode(name);

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // did not use CustomTextWidget here cause it was overriding the label color property of the tab bar
            name,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isPrivate) ...[
            const SizedBox(width: 4),
            Icon(Icons.visibility_off, size: 16, color: Colors.red),
          ],
        ],
      ),
    );
  }

  void _showMessageStatusDialog(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(89, 120, 247, 0.1),
                Color.fromRGBO(156, 132, 255, 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomTextWidget(
                text: 'Message Info',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primaryColor),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.55,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomTextWidget(
                  text: 'Message Content',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    //color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor, width: 1),
                  ),
                  child: CustomTextWidget(
                    text: MessageContentProcessor.stripHtmlTags(message.text),
                    fontSize: 15,
                    unlimitedLines: true,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery & Read info
                _buildStatusSection(message),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const CustomTextWidget(
                text: 'Close',
                fontColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Message message) {
    final hasDelivery = message.isDelivered;
    final hasRead = message.isRead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDelivery || hasRead) ...[
          const CustomTextWidget(
            text: 'Status',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (hasDelivery)
                _buildRecipientList(
                  title: 'Delivered To',
                  icon: Icons.check_circle_outline,
                  recipients: message.deliveredTo,
                  fallbackTime: message.deliveredAt,
                  color: Colors.blueGrey,
                ),

              if (hasRead) ...[
                const SizedBox(height: 8),
                _buildRecipientList(
                  title: 'Read By',
                  icon: Icons.done_all,
                  recipients: message.readBy,
                  fallbackTime: message.readAt,
                  color: AppColors.primaryColor,
                ),
              ],
            ],
          ),
        ] else ...[
          const CustomTextWidget(
            text: 'Message is still sending...',
            fontSize: 14,
            fontColor: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildRecipientList({
    required String title,
    required IconData icon,
    required List<RecipientStatus> recipients,
    DateTime? fallbackTime,
    required Color color,
  }) {
    final count = recipients.length + (fallbackTime != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            CustomTextWidget(
              text: '$title ($count)',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (recipients.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: recipients
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: CustomTextWidget(
                              text: r.name.trim().isNotEmpty
                                  ? r.name
                                  : 'Participant',
                              fontSize: 13,
                            ),
                          ),
                          if (r.timestamp != null) ...[
                            const SizedBox(width: 10),
                            CustomTextWidget(
                              text: _formatTimeShort(r.timestamp!),
                              fontSize: 12,
                              fontColor: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        // if (recipients.isNotEmpty)
        //   ...recipients.map((r) => Padding(
        //     padding: const EdgeInsets.only(left: 32, bottom: 6),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Flexible(
        //           fit: FlexFit.loose,
        //           child: CustomTextWidget(
        //             text: r.name,
        //             fontSize: 13,
        //           ),
        //         ),
        //         if (r.timestamp != null) ...[
        //           const SizedBox(width: 4,),
        //           CustomTextWidget(
        //             text: _formatTimeShort(r.timestamp!),
        //             fontSize: 12,
        //             fontColor: Colors.grey.shade600,
        //           ),
        //         ]
        //
        //       ],
        //     ),
        //   ))
        else if (fallbackTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: CustomTextWidget(
              text: 'Recipient • ${_formatFullTime(fallbackTime)}',
              fontSize: 13,
              fontColor: Colors.grey.shade700,
            ),
          ),
      ],
    );
  }

  String _formatTimeShort(
    DateTime dt, {
    bool use24Hour = false,
    String separator = ':',
  }) {
    if (use24Hour) {
      return "${dt.hour.toString().padLeft(2, '0')}${separator}${dt.minute.toString().padLeft(2, '0')}";
    }

    final hour = dt.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$hour12$separator$minute $period';
  }

  String _formatFullTime(DateTime dt) {
    final now = DateTime.now();
    String dayPart =
        (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        ? 'Today'
        : (dt.day == now.day - 1
              ? 'Yesterday'
              : '${dt.day} ${_monthName(dt.month)} ${dt.year}');

    return '$dayPart, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  String _monthName(int month) => [
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
  ][month - 1];
}
