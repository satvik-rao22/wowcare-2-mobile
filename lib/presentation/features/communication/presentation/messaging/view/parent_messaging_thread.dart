import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_input_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
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
import '../widgets/chat_thread_shimmer.dart';
import '../widgets/message_bubble_widget.dart';

class ParentMessagingThread extends StatefulWidget {
  const ParentMessagingThread({super.key, required this.parentInfo});
  final Map<String, dynamic> parentInfo;

  @override
  State<ParentMessagingThread> createState() => _ParentMessagingThreadState();
}

class _ParentMessagingThreadState extends State<ParentMessagingThread>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  final AutoScrollController _groupController = AutoScrollController();
  final AutoScrollController _parent1Controller = AutoScrollController();
  final AutoScrollController _parent2Controller = AutoScrollController();
  TabController? _tabController;

  late final ReactionsController _reactionsController;
  Message? _quotedMessage = null;
  String? _quotedMessageId;
  List<ChatAttachment> _pendingAttachments = [];
  String? _currentUserCode;
  String? _currentSender;
  Message? _editingMessage;
  final FocusNode _inputFocusNode = FocusNode();

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
      final storedUserCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
      final authUserCode = authState is AuthLoaded
          ? authState.loginResponse.userCode
          : null;
      final currentUserId = (authUserCode?.isNotEmpty ?? false) ? authUserCode : (storedUserCode.isNotEmpty ? storedUserCode : null);
      if (!mounted) return;
      setState(() {
        _currentUserCode = currentUserId;
      });
      final convCode = widget.parentInfo['code'] as String;
      AppLogger.d(
        '[ParentThread] loading messages for $convCode '
        'currentUserId=$currentUserId',
      );
      context.read<CommunicationCubit>().loadMessages(
        convCode,
        currentUserId: currentUserId,
      );
    });
  }

  @override
  void dispose() {
    //_reactionsController.dispose();
    _controller.dispose();
    _groupController.dispose();
    _parent1Controller.dispose();
    _parent2Controller.dispose();
    _tabController?.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  AutoScrollController _getActiveScrollController() {
    if (!_privateModeEnabled) return _groupController;
    return _tabController?.index == 0 ? _parent1Controller : _parent2Controller;
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

    context.read<CommunicationCubit>().sendMessage(
      widget.parentInfo['code'] as String,
      text,
      attachments: List.from(_pendingAttachments),
      quotedMessageId: _quotedMessageId,
      senderName: senderName,
      receivers: receivers,
    );

    setState(() {
      _controller.clear();
      _pendingAttachments.clear();
      _quotedMessage = null;
      _quotedMessageId = null;
    });

    // setState(() {
    //   _messages.add(
    //     Message(
    //       text: _controller.text.trim(),
    //       isSentByMe: true,
    //       time: DateTime.now(),
    //       deliveredAt: null,
    //       readAt: null
    //     ),
    //   );
    // });

    //_controller.clear();
    final scrollController = _getActiveScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.scrollToIndex(
        0,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(milliseconds: 300),
      );
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

  void _showMessageOptions(
    BuildContext context,
    Message message,
    LongPressStartDetails details,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          details.globalPosition.dx,
          details.globalPosition.dy,
          40,
          40,
        ),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        if (message.isSentByMe) ...[
          const PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryColor),
              title: CustomTextWidget(
                text: 'Edit',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                applyLetterSpacing: false,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppColors.primaryColor,
              ),
              title: CustomTextWidget(
                text: 'Delete',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                applyLetterSpacing: false,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        const PopupMenuItem<String>(
          value: 'reply',
          child: ListTile(
            leading: Icon(Icons.reply, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Reply',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.copy, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Copy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'info',
          child: ListTile(
            leading: Icon(Icons.info, color: AppColors.primaryColor),
            title: CustomTextWidget(
              text: 'Info',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              applyLetterSpacing: false,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'react',
          child: ListTile(
            leading: Icon(Icons.emoji_emotions_outlined),
            title: Text('React'),
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ).then((value) {
      if (!mounted || value == null) return;

      switch (value) {
        case 'reply':
          setState(() {
            _quotedMessageId = message.id;
            _quotedMessage = message;
          });
          break;
        case 'copy':
          Clipboard.setData(ClipboardData(text: message.text));
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message copied successfully',
            isSuccess: true,
          );
          break;
        case 'info':
          _showMessageStatusDialog(context, message);
          break;
        case 'edit':
          _startEditing(message);
          break;

        case 'delete':
          context.read<CommunicationCubit>().deleteMessage(
                widget.parentInfo['code'] as String,
                message.code,
              );
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message deleted successfully',
            isSuccess: true,
          );
          break;
        case 'react':
          _showEmojiPicker(context, message);
          break;
      }
    });
  }

  void _showEmojiPicker(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 380 + MediaQuery.of(context).padding.bottom,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context); // close picker
              final myReaction = message.reactions[_currentUserCode ?? 'me'];
              if (myReaction == emoji.emoji) {
                context.read<CommunicationCubit>().removeReaction(
                      widget.parentInfo['code'] as String,
                      message.code,
                      emoji.emoji,
                    );
              } else {
                context.read<CommunicationCubit>().addReaction(
                      widget.parentInfo['code'] as String,
                      message.code,
                      emoji.emoji,
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
      _controller.text = message.text;
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

    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        final _messages = _activeMessages;
        if (state is CommunicationLoading && _messages.isEmpty) {
          return const GlobalScaffold(
            hasBackButton: true,
            body: ChatThreadShimmer(),
          );
        }
        return GlobalScaffold(
          hasBackButton: true,
          showCustomNavigationBar: !isLandscape,
          body: Padding(
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
                                          Message? quotedMessage;
                                          if (message.quotedMessageId != null) {
                                            quotedMessage = _messages
                                                .firstWhere(
                                                  (m) =>
                                                      m.id ==
                                                      message.quotedMessageId,
                                                ); // ?? null;
                                          }
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

                                                MessageBubble(
                                                  message: message,
                                                  currentUserCode: _currentUserCode,
                                                  reactionsController:
                                                      _reactionsController,
                                                  isParentMessaging: true,
                                                  quotedMessage: quotedMessage,
                                                  onReplyFromMenu: () {
                                                    setState(() {
                                                      _quotedMessageId =
                                                          message.id;
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
                                                  onEdit: () => _startEditing(
                                                    message,
                                                  ),
                                                  onDelete: () {
                                                    context.read<CommunicationCubit>().deleteMessage(
                                                          widget.parentInfo['code'] as String,
                                                          message.code,
                                                        );
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
                                                  onScrollToQuoted: (quoteId) {
                                                    _scrollToMessage(quoteId);
                                                  },
                                                  onReactionAdded: (emoji) {
                                                    final myReaction = message.reactions[_currentUserCode ?? 'me'];
                                                    if (myReaction == emoji) {
                                                      context.read<CommunicationCubit>().removeReaction(
                                                            widget.parentInfo['code'] as String,
                                                            message.code,
                                                            emoji,
                                                          );
                                                    } else {
                                                      context.read<CommunicationCubit>().addReaction(
                                                            widget.parentInfo['code'] as String,
                                                            message.code,
                                                            emoji,
                                                          );
                                                    }
                                                  },
                                                  onRemoveReaction: (emoji) {
                                                    context.read<CommunicationCubit>().removeReaction(
                                                          widget.parentInfo['code'] as String,
                                                          message.code,
                                                          emoji,
                                                        );
                                                  },
                                                  onReactionTap: () => _showEmojiPicker(
                                                    context,
                                                    message,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
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

                                          Message? quotedMessage;
                                          if (message.quotedMessageId != null) {
                                            quotedMessage = _messages
                                                .firstWhere(
                                                  (m) =>
                                                      m.id ==
                                                      message.quotedMessageId,
                                                ); // ?? null;
                                          }
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

                                                MessageBubble(
                                                  message: message,
                                                  currentUserCode: _currentUserCode,
                                                  reactionsController:
                                                      _reactionsController,
                                                  isParentMessaging: true,
                                                  quotedMessage: quotedMessage,
                                                  onReplyFromMenu: () {
                                                    setState(() {
                                                      _quotedMessageId =
                                                          message.id;
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
                                                  onEdit: () => _startEditing(
                                                    message,
                                                  ),
                                                  onDelete: () {
                                                    context.read<CommunicationCubit>().deleteMessage(
                                                          widget.parentInfo['code'] as String,
                                                          message.code,
                                                        );
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
                                                  onScrollToQuoted: (quoteId) {
                                                    _scrollToMessage(quoteId);
                                                  },
                                                  onReactionAdded: (emoji) {
                                                    final myReaction = message.reactions[_currentUserCode ?? 'me'];
                                                    if (myReaction == emoji) {
                                                      context.read<CommunicationCubit>().removeReaction(
                                                            widget.parentInfo['code'] as String,
                                                            message.code,
                                                            emoji,
                                                          );
                                                    } else {
                                                      context.read<CommunicationCubit>().addReaction(
                                                            widget.parentInfo['code'] as String,
                                                            message.code,
                                                            emoji,
                                                          );
                                                    }
                                                  },
                                                  onRemoveReaction: (emoji) {
                                                    context.read<CommunicationCubit>().removeReaction(
                                                          widget.parentInfo['code'] as String,
                                                          message.code,
                                                          emoji,
                                                        );
                                                  },
                                                  onReactionTap: () => _showEmojiPicker(
                                                    context,
                                                    message,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ]
                                  : [
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
                                          // Message? quotedMessage;
                                          // if (message.quotedMessageId != null) {
                                          //   quotedMessage = _messages
                                          //       .firstWhere(
                                          //         (m) =>
                                          //             m.id ==
                                          //             message.quotedMessageId,
                                          //       ); // ?? null;
                                          // }
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

                                                // MessageBubble(
                                                //   //key: key,
                                                //   //scrollKey: scrollKey,
                                                //   message: message,
                                                //   isParentMessaging: true,
                                                //   quotedMessage: quotedMessage,
                                                //   onLongPress:
                                                //       (
                                                //         LongPressStartDetails
                                                //         details,
                                                //       ) {
                                                //         _showMessageOptions(
                                                //           context,
                                                //           message,
                                                //           details,
                                                //         );
                                                //       },
                                                //   onScrollToQuoted: (quoteId) {
                                                //     _scrollToMessage(quoteId);
                                                //   },
                                                //   // onHeightMeasured: (id, height) {
                                                //   //   if (_bubbleHeights[id] != height) {
                                                //   //     setState(() {
                                                //   //       _bubbleHeights[id] = height;
                                                //   //     });
                                                //   //   }
                                                //   // },
                                                //   //onHeightMeasured:
                                                //   // onContextReady: (id, ctx) {
                                                //   //   if (_messageContexts[id] != ctx) {
                                                //   //     setState(() {
                                                //   //       _messageContexts[id] = ctx;
                                                //   //     });
                                                //   //   }
                                                //   // },
                                                // ),
                                              ],
                                            ),
                                          );
                                        },
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
                      CustomTextWidget(text: 'Messaging', fontSize: 16),
                      const SizedBox(height: 10),
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
                                              Message? quotedMessage;
                                              if (message.quotedMessageId !=
                                                  null) {
                                                quotedMessage = _messages
                                                    .firstWhere(
                                                      (m) =>
                                                          m.id ==
                                                          message
                                                              .quotedMessageId,
                                                    ); // ?? null;
                                              }
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
                                                          child: _buildDateChip(
                                                            message.time,
                                                          ),
                                                        ),
                                                      ),
                                                    if (showDateHeader)
                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                    MessageBubble(
                                                      message: message,
                                                      currentUserCode: _currentUserCode,
                                                      reactionsController:
                                                          _reactionsController,
                                                      isParentMessaging: true,
                                                      quotedMessage:
                                                          quotedMessage,
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
                                                            text: message.text,
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
                                                          _editingMessage = message;
                                                          _controller.text = message.text;
                                                          _inputFocusNode.requestFocus();
                                                        });
                                                      },
                                                      onDelete: () {
                                                        context.read<CommunicationCubit>().deleteMessage(
                                                              widget.parentInfo['code'] as String,
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
                                                        final myReaction = message.reactions[_currentUserCode ?? 'me'];
                                                        if (myReaction == emoji) {
                                                          context.read<CommunicationCubit>().removeReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        } else {
                                                          context.read<CommunicationCubit>().addReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        }
                                                      },
                                                      onRemoveReaction: (emoji) {
                                                        context.read<CommunicationCubit>().removeReaction(
                                                              widget.parentInfo['code'] as String,
                                                              message.code,
                                                              emoji,
                                                            );
                                                      },
                                                      onReactionTap: () => _showEmojiPicker(
                                                        context,
                                                        message,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
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
                                              Message? quotedMessage;
                                              if (message.quotedMessageId !=
                                                  null) {
                                                quotedMessage = _messages
                                                    .firstWhere(
                                                      (m) =>
                                                          m.id ==
                                                          message
                                                              .quotedMessageId,
                                                    ); // ?? null;
                                              }
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
                                                          child: _buildDateChip(
                                                            message.time,
                                                          ),
                                                        ),
                                                      ),
                                                    if (showDateHeader)
                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                    MessageBubble(
                                                      message: message,
                                                      currentUserCode: _currentUserCode,
                                                      reactionsController:
                                                          _reactionsController,
                                                      isParentMessaging: true,
                                                      quotedMessage:
                                                          quotedMessage,
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
                                                            text: message.text,
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
                                                          _editingMessage = message;
                                                          _controller.text = message.text;
                                                          _inputFocusNode.requestFocus();
                                                        });
                                                      },
                                                      onDelete: () {
                                                        context.read<CommunicationCubit>().deleteMessage(
                                                              widget.parentInfo['code'] as String,
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
                                                        final myReaction = message.reactions[_currentUserCode ?? 'me'];
                                                        if (myReaction == emoji) {
                                                          context.read<CommunicationCubit>().removeReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        } else {
                                                          context.read<CommunicationCubit>().addReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        }
                                                      },
                                                      onRemoveReaction: (emoji) {
                                                        context.read<CommunicationCubit>().removeReaction(
                                                              widget.parentInfo['code'] as String,
                                                              message.code,
                                                              emoji,
                                                            );
                                                      },
                                                      onReactionTap: () => _showEmojiPicker(
                                                        context,
                                                        message,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ]
                                      : [
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
                                              Message? quotedMessage;
                                              if (message.quotedMessageId !=
                                                  null) {
                                                quotedMessage = _messages
                                                    .firstWhere(
                                                      (m) =>
                                                          m.id ==
                                                          message
                                                              .quotedMessageId,
                                                    ); // ?? null;
                                              }
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
                                                          child: _buildDateChip(
                                                            message.time,
                                                          ),
                                                        ),
                                                      ),
                                                    if (showDateHeader)
                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                    MessageBubble(
                                                      message: message,
                                                      currentUserCode: _currentUserCode,
                                                      reactionsController:
                                                          _reactionsController,
                                                      isParentMessaging: true,
                                                      quotedMessage:
                                                          quotedMessage,
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
                                                            text: message.text,
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
                                                          _editingMessage = message;
                                                          _controller.text = message.text;
                                                          _inputFocusNode.requestFocus();
                                                        });
                                                      },
                                                      onDelete: () {
                                                        context.read<CommunicationCubit>().deleteMessage(
                                                              widget.parentInfo['code'] as String,
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
                                                        final myReaction = message.reactions[_currentUserCode ?? 'me'];
                                                        if (myReaction == emoji) {
                                                          context.read<CommunicationCubit>().removeReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        } else {
                                                          context.read<CommunicationCubit>().addReaction(
                                                                widget.parentInfo['code'] as String,
                                                                message.code,
                                                                emoji,
                                                              );
                                                        }
                                                      },
                                                      onRemoveReaction: (emoji) {
                                                        context.read<CommunicationCubit>().removeReaction(
                                                              widget.parentInfo['code'] as String,
                                                              message.code,
                                                              emoji,
                                                            );
                                                      },
                                                      onReactionTap: () => _showEmojiPicker(
                                                        context,
                                                        message,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                    ],
                  ),
          ),
        );
      },
    );
  }

  List<ConversationParticipant> get _participants {
    final raw = widget.parentInfo['participants'];
    if (raw is List) {
      return raw.whereType<ConversationParticipant>().toList();
    }
    return [];
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
        setState(() {
          _pendingAttachments.addAll(attachments);
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
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────
          Row(
            children: [
              DocumentImageWidget(
                fileUuid: widget.parentInfo['avatar'] as String? ?? '',
                name: title,
                size: 36,
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
              Tooltip(
                message: 'View Participants',
                child: IconButton(
                  icon: const Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryColor),
                  onPressed: _showParticipantsDialog,
                ),
              ),
            ],
          ),

          // ── Participant chips ───────────────────────────────────────
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: participants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final roleColor = _roleColor(p.role);
                  final initial = p.userName.isNotEmpty
                      ? p.userName[0].toUpperCase()
                      : '?';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: roleColor.withValues(alpha: 0.25),
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.userName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.role,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
          constraints: const BoxConstraints(maxHeight: 320),
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
                    text: message.text,
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
