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
import '../util/message_content_processor.dart';
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
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_thread_shimmer.dart';
import '../widgets/message_attachment_bottom_sheet.dart';
import '../widgets/message_bubble_widget.dart';

class StaffMessagingThread extends StatefulWidget {
  const StaffMessagingThread({super.key, required this.staffInfo});
  final Map<String, dynamic> staffInfo;

  @override
  State<StaffMessagingThread> createState() => _StaffMessagingThreadState();
}

class _StaffMessagingThreadState extends State<StaffMessagingThread> {
  //final ScrollController _scrollController = ScrollController();
  final AutoScrollController _scrollController = AutoScrollController();
  final TextEditingController _controller = TextEditingController();

  String? _currentUserCode;

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

    // Primary source: auth cubit state (already in memory after login).
    final authState = context.read<AuthCubit>().state;
    final userCodeFromAuth = authState is AuthLoaded
        ? authState.loginResponse.userCode.trim()
        : '';

    _currentUserCode = userCodeFromAuth.isNotEmpty ? userCodeFromAuth : null;

    _reactionsController = ReactionsController(
      currentUserId: _currentUserCode ?? 'me',
    );

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

      AppLogger.d(
        '[CHAT OWNERSHIP] initState identity resolution:\n'
        '  loginResponse.userCode → "$userCodeFromAuth"\n'
        '  storage.userCode       → "$storedUserCode"\n'
        '  resolved               → "$_currentUserCode"\n'
        '  threadId               → "${widget.staffInfo['code']}"',
      );

      if (mounted) {
        context.read<CommunicationCubit>().loadMessages(
          widget.staffInfo['code'] as String,
          currentUserId: _currentUserCode,
        );
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _reactionsController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;
    final hasAttachments = _pendingAttachments.isNotEmpty;

    if (!hasText && !hasAttachments) return;

    final authState = context.read<AuthCubit>().state;
    final senderName = authState is AuthLoaded
        ? authState.loginResponse.displayName
        : 'Me';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  void _showEditDialog(BuildContext context, Message message) {
    final TextEditingController editingController = TextEditingController(
      text: MessageContentProcessor.stripHtmlTags(message.text),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        backgroundColor: Colors.white,

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
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
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
              style: TextButton.styleFrom(overlayColor: Colors.transparent),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
        // Auto-scroll to bottom whenever messages finish loading (cache or API)
        if (state is CommunicationLoaded) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final bool isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        if (state is CommunicationLoading && _messages.isEmpty) {
          return Scaffold(body: const ChatThreadShimmer());
        }

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
                                Message? quotedMessage;
                                if (message.quotedMessageId != null) {
                                  final matches = _messages.where(
                                    (m) => m.id == message.quotedMessageId,
                                  );
                                  quotedMessage = matches.isNotEmpty
                                      ? matches.first
                                      : null;
                                }
                                bool showDateHeader = false;
                                final prevMessageIndex = index - 1;

                                if (prevMessageIndex >= 0) {
                                  final prevMessage =
                                      _messages[prevMessageIndex];
                                  final schoolTz =
                                      SchoolTimezoneResolver.lastKnownTimeZone;
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
                                      currentDate.year != prevDate.year ||
                                      currentDate.month != prevDate.month ||
                                      currentDate.day != prevDate.day;
                                } else {
                                  showDateHeader = true;
                                }
                                final prevMessage = prevMessageIndex >= 0
                                    ? _messages[prevMessageIndex]
                                    : null;
                                final isGrouped =
                                    !showDateHeader &&
                                    _isSameSender(prevMessage, message);

                                return AutoScrollTag(
                                  key: ValueKey(messageId),
                                  controller: _scrollController,
                                  index: index,
                                  highlightColor: Colors.green.withValues(
                                    alpha: 0.7,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showDateHeader)
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: _buildDateChip(message.time),
                                          ),
                                        ),
                                      if (showDateHeader)
                                        const SizedBox(height: 10),
                                      // Spacing: compact for grouped, normal for new group
                                      SizedBox(height: isGrouped ? 2.0 : 8.0),
                                      MessageBubble(
                                        message: message,
                                        quotedMessage: quotedMessage,
                                        currentUserCode: _currentUserCode,
                                        reactionsController:
                                            _reactionsController,
                                        onScrollToQuoted: (quoteId) {
                                          _scrollToMessage(quoteId);
                                        },
                                        onReply: () {
                                          setState(() {
                                            _quotedMessageCode = message.code;
                                            _quotedMessage = message;
                                          });
                                        },
                                        onReplyFromMenu: () {
                                          setState(() {
                                            _quotedMessageCode = message.code;
                                            _quotedMessage = message;
                                          });
                                        },
                                        onCopy: () {
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
                                        onEdit: () =>
                                            _showEditDialog(context, message),
                                        onDelete: () {
                                          setState(() {
                                            _messages.removeWhere(
                                              (m) => m.id == message.id,
                                            );
                                          });
                                          CoreUtils.showTopSnackBar(
                                            context: context,
                                            message:
                                                'Message deleted successfully',
                                            isSuccess: true,
                                          );
                                        },
                                        onInfo: () => _showMessageStatusDialog(
                                          context,
                                          message,
                                        ),
                                        onReactionAdded: (emoji) =>
                                            _onReactionAdded(message, emoji),
                                        onReactionTap: () =>
                                            _showEmojiPicker(context, message),
                                        isGrouped: isGrouped,
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: _buildMessageInput(),
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
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.1),
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
                                              fileUuid:
                                                  widget.staffInfo['avatar'],
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
                                                  color:
                                                      (widget.staffInfo['isSigned'] ??
                                                          false)
                                                      ? const Color.fromRGBO(
                                                          0,
                                                          177,
                                                          21,
                                                          1,
                                                        )
                                                      : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        (widget.staffInfo['isSigned'] ??
                                                            false)
                                                        ? Colors.white
                                                        : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: CustomTextWidget(
                                                  text:
                                                      widget.staffInfo['name'],
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
                                                        text: widget
                                                            .staffInfo['name'],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 18,
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (widget
                                                                  .staffInfo['code'] !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 4,
                                                                  ),
                                                              child: RichText(
                                                                text: TextSpan(
                                                                  children: [
                                                                    const TextSpan(
                                                                      text:
                                                                          'Code: ',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text: widget
                                                                          .staffInfo['code']
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          if (widget
                                                                  .staffInfo['designation'] !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 4,
                                                                  ),
                                                              child: RichText(
                                                                text: TextSpan(
                                                                  children: [
                                                                    const TextSpan(
                                                                      text:
                                                                          'Designation: ',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text: widget
                                                                          .staffInfo['designation']
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .black54,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          if (widget
                                                                  .staffInfo['email'] !=
                                                              null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 4,
                                                                  ),
                                                              child: RichText(
                                                                text: TextSpan(
                                                                  children: [
                                                                    const TextSpan(
                                                                      text:
                                                                          'Email: ',
                                                                      style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text: widget
                                                                          .staffInfo['email']
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .black54,
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
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                          child: const Text(
                                                            'Close',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 18,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Flexible(
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
                                      Message? quotedMessage;
                                      if (message.quotedMessageId != null) {
                                        final matches = _messages.where(
                                          (m) =>
                                              m.id == message.quotedMessageId,
                                        );
                                        quotedMessage = matches.isNotEmpty
                                            ? matches.first
                                            : null;
                                      }
                                      bool showDateHeader = false;
                                      final prevMessageIndex = index - 1;

                                      if (prevMessageIndex >= 0) {
                                        final prevMessage =
                                            _messages[prevMessageIndex];
                                        final schoolTz = SchoolTimezoneResolver
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
                                            currentDate.year != prevDate.year ||
                                            currentDate.month !=
                                                prevDate.month ||
                                            currentDate.day != prevDate.day;
                                      } else {
                                        showDateHeader = true;
                                      }
                                      final prevMessage = prevMessageIndex >= 0
                                          ? _messages[prevMessageIndex]
                                          : null;
                                      final isGrouped =
                                          !showDateHeader &&
                                          _isSameSender(prevMessage, message);

                                      return AutoScrollTag(
                                        key: ValueKey(messageId),
                                        controller: _scrollController,
                                        index: index,
                                        highlightColor: Colors.green.withValues(
                                          alpha: 0.7,
                                        ),
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

                                            MessageBubble(
                                              message: message,
                                              quotedMessage: quotedMessage,
                                              currentUserCode: _currentUserCode,
                                              reactionsController:
                                                  _reactionsController,
                                              onScrollToQuoted: (quoteId) {
                                                _scrollToMessage(quoteId);
                                              },
                                              onReply: () {
                                                setState(() {
                                                  _quotedMessageCode =
                                                      message.code;
                                                  _quotedMessage = message;
                                                });
                                              },
                                              onReplyFromMenu: () {
                                                setState(() {
                                                  _quotedMessageCode =
                                                      message.code;
                                                  _quotedMessage = message;
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
                                              onEdit: () => _showEditDialog(
                                                context,
                                                message,
                                              ),
                                              onDelete: () {
                                                setState(() {
                                                  _messages.removeWhere(
                                                    (m) => m.id == message.id,
                                                  );
                                                });
                                                CoreUtils.showTopSnackBar(
                                                  context: context,
                                                  message:
                                                      'Message deleted successfully',
                                                  isSuccess: true,
                                                );
                                              },
                                              onInfo: () =>
                                                  _showMessageStatusDialog(
                                                    context,
                                                    message,
                                                  ),
                                              onReactionAdded: (emoji) =>
                                                  _onReactionAdded(
                                                    message,
                                                    emoji,
                                                  ),
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            child: _buildMessageInput(),
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

  Widget _buildMessageInput() {
    return SafeArea(
      child: ChatInputBar(
        controller: _controller,
        onSend: _sendMessage,
        onAttachmentTap: _showAttachmentPicker,
        isSending: false,
        pendingAttachments: _pendingAttachments,
        quotedMessage: _quotedMessage,
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
          setState(() => _pendingAttachments.addAll(attachments));
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
      DateTime.now().toUtc(),
      schoolTz,
    );

    String label;
    if (schoolDate.year == schoolNow.year &&
        schoolDate.month == schoolNow.month &&
        schoolDate.day == schoolNow.day) {
      final monthNames = [
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
      label =
          "Today, ${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    } else if (schoolDate.year == schoolNow.year &&
        schoolDate.month == schoolNow.month &&
        schoolDate.day == schoolNow.day - 1) {
      final monthNames = [
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
      label =
          "Yesterday, ${schoolDate.day} ${monthNames[schoolDate.month - 1]} ${schoolDate.year}";
    } else {
      final monthNames = [
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
                            child: CustomTextWidget(text: r.name, fontSize: 13),
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
  // String _formatTimeShort(DateTime dt) {
  //   return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  // }

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
