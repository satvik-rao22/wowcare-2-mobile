import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart' as open_filex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';
import 'full_attachment_viewer.dart';
import '../../../../../../domain/features/communication/entities/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Message? quotedMessage;
  final String? currentUserCode;
  final ReactionsController reactionsController;
  final void Function(String quotedId)? onScrollToQuoted;
  // Swipe-to-reply
  final VoidCallback? onReply;
  // Menu item callbacks (from ChatMessageWrapper context menu)
  final VoidCallback? onReplyFromMenu;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInfo;
  final void Function(String emoji)? onReactionAdded;
  final void Function(String emoji)? onRemoveReaction;
  final VoidCallback? onReactionTap;
  final bool isParentMessaging;
  final bool isInactive;
  final bool isDeleted;

  const MessageBubble({
    required this.message,
    required this.reactionsController,
    this.quotedMessage,
    this.currentUserCode,
    this.onScrollToQuoted,
    this.onReply,
    this.onReplyFromMenu,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onInfo,
    this.onReactionAdded,
    this.onRemoveReaction,
    this.onReactionTap,
    this.isParentMessaging = false,
    this.isInactive = false,
    this.isDeleted = false,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  // ── Swipe-to-reply ────────────────────────────────────────────────────────
  double _dragOffset = 0;
  double _snapStartOffset = 0;
  bool _replyTriggered = false;
  late final AnimationController _snapController;

  static const double _swipeThreshold = 65.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapController.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = _snapStartOffset * (1 - _snapController.value);
        });
      }
    });
    _syncReactionsToController();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.reactions != widget.message.reactions) {
      _syncReactionsToController();
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  /// Seed the [ReactionsController] with current message reactions so
  /// [StackedReactions] always reflects the latest API state.
  /// Deferred to post-frame to avoid notifyListeners() during build.
  void _syncReactionsToController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reactions = widget.message.reactions.entries.map((e) {
        return Reaction(
          emoji: e.value,
          userId: e.key,
          timestamp: DateTime.now(),
        );
      }).toList();
      widget.reactionsController.loadReactions(widget.message.code, reactions);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        0.0,
        _swipeThreshold + 15,
      );
    });
    if (!_replyTriggered && _dragOffset >= _swipeThreshold) {
      _replyTriggered = true;
      HapticFeedback.mediumImpact();
      widget.onReply!();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _snapStartOffset = _dragOffset;
    _replyTriggered = false;
    _snapController.forward(from: 0);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isMe =>
      widget.message.isSentByMe ||
      (widget.currentUserCode != null &&
          widget.currentUserCode == widget.message.senderUserCode);

  ChatReactionsConfig _buildReactionsConfig(bool isMe) {
    return ChatReactionsConfig(
      availableReactions: const ['👍', '❤️', '😂', '😮', '😢', '😡', '➕'],
      menuItems: [
        if (isMe) const MenuItem(label: 'Edit', icon: Icons.edit_outlined),
        if (isMe)
          const MenuItem(
            label: 'Delete',
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        const MenuItem(label: 'Reply', icon: Icons.reply_rounded),
        const MenuItem(label: 'Copy', icon: Icons.copy_outlined),
        const MenuItem(label: 'Info', icon: Icons.info_outline),
      ],
      enableLongPress: true,
      enableDoubleTap: false,
      showAddReactionButton: true,
      showContextMenu: true,
      enableHapticFeedback: true,
      reactionSize: 24,
    );
  }

  void _handleMenuItemTap(MenuItem item) {
    switch (item.label) {
      case 'Reply':
        widget.onReplyFromMenu?.call();
        break;
      case 'Copy':
        widget.onCopy?.call();
        break;
      case 'Edit':
        widget.onEdit?.call();
        break;
      case 'Delete':
        widget.onDelete?.call();
        break;
      case 'Info':
        widget.onInfo?.call();
        break;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMe = _isMe;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onHorizontalDragUpdate: widget.onReply != null ? _onDragUpdate : null,
      onHorizontalDragEnd: widget.onReply != null ? _onDragEnd : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Reply swipe icon (left side, appears on drag)
              if (widget.onReply != null)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (_dragOffset / _swipeThreshold).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

              // Bubble content
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Avatar row (above bubble)
                      if (widget.isParentMessaging) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            DocumentImageWidget(
                              fileUuid: widget.message.senderName ?? '',
                              name: widget.message.senderName ?? '',
                              size: 20,
                              fontSize: 10,
                            ),
                            const SizedBox(width: 8.0),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                      ],

                      // Sender Name header (above bubble)
                      if (widget.message.senderName != null &&
                          widget.message.senderName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            isMe ? 'You' : widget.message.senderName!,
                            style: const TextStyle(
                              color: Color.fromRGBO(87, 51, 83, 0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Bubble wrapped with ChatMessageWrapper
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.72,
                        ),
                        child: ChatMessageWrapper(
                          messageId: widget.message.code.isNotEmpty
                              ? widget.message.code
                              : widget.message.id,
                          controller: widget.reactionsController,
                          config: _buildReactionsConfig(isMe),
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          onReactionAdded: (emoji) {
                            final myReaction = widget.message.reactions[widget.currentUserCode ?? 'me'];
                            if (myReaction == emoji) {
                              widget.onRemoveReaction?.call(emoji);
                            } else {
                              widget.onReactionAdded?.call(emoji);
                            }
                          },
                          onMenuItemTapped: _handleMenuItemTap,
                          child: _buildBubble(isMe),
                        ),
                      ),

                      // Time + delivery status row below bubble (MessageBox style)
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(widget.message.time),
                            style: const TextStyle(
                              color: Color.fromRGBO(65, 65, 78, 0.5),
                              fontSize: 15.0,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.message.isRead
                                  ? Icons.done_all
                                  : widget.message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: widget.message.isRead
                                  ? Colors.blue
                                  : widget.message.isDelivered
                                  ? Colors.grey
                                  : const Color.fromRGBO(65, 65, 78, 0.5),
                            ),
                          ],
                          if (widget.message.isPrivate) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.visibility_off,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                          if (isMe &&
                              widget.onDelete != null &&
                              !widget.isInactive &&
                              !(widget.isDeleted ||
                                  widget.message.text.contains(
                                    'This Message Has Been Deleted',
                                  ))) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 24,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF2F2FF),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Delete Message',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF573353),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Color(0xFF573353),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Are you sure you want to delete this message?',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFF573353),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 24),
                                                GestureDetector(
                                                  onTap: () {
                                                    widget.onDelete?.call();
                                                    Navigator.pop(context);
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFF7175F4),
                                                              Color(0xFF9287F4),
                                                            ],
                                                            begin: Alignment
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                GestureDetector(
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF573353,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Stacked reactions badge below the bubble/time
                      AnimatedBuilder(
                        animation: widget.reactionsController,
                        builder: (context, _) {
                          final messageId = widget.message.code.isNotEmpty
                              ? widget.message.code
                              : widget.message.id;
                          final counts = widget.reactionsController
                              .getReactionCounts(messageId);
                          if (counts.isEmpty) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: GestureDetector(
                              onTap: widget.onReactionTap,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: StackedReactions(
                                  messageId: messageId,
                                  controller: widget.reactionsController,
                                  size: 22,
                                  stackedValue: 3,
                                  direction: isMe
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  reactionBackgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bubble body ───────────────────────────────────────────────────────────

  Widget _buildBubble(bool isMe) {
    final message = widget.message;
    final isDeleted =
        widget.isDeleted ||
        message.text.contains('This Message Has Been Deleted');

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        margin: EdgeInsets.only(left: isMe ? 60 : 0, right: isMe ? 0 : 60),
        decoration: BoxDecoration(
          color: isMe ? null : const Color.fromRGBO(220, 230, 255, 1),
          gradient: isMe ? AppColors.buildPrimaryGradient() : null,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(isMe ? 70 : 50),
            topLeft: Radius.circular(isMe ? 50 : 70),
            bottomLeft: Radius.circular(isMe ? 50 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 50),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: isDeleted
              ? const Text(
                  '🚫 This Message Has Been Deleted',
                  style: TextStyle(
                    color: Color.fromRGBO(87, 51, 83, 1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quoted preview
                    if (message.quotedMessageId != null &&
                        widget.quotedMessage != null)
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildQuotePreview(isMe),
                      ),

                    // Attachments
                    if (message.hasAttachments) ...[
                      _buildAttachmentsPreview(),
                      if (message.text.trim().isNotEmpty)
                        const SizedBox(height: 6),
                    ],

                    // Message text
                    if (message.text.trim().isNotEmpty)
                      Flexible(
                        fit: FlexFit.loose,
                        child: _StableHtml(
                          data: message.text,
                          style: {
                            'body': html.Style(
                              margin: html.Margins.zero,
                              padding: html.HtmlPaddings.zero,
                              fontSize: html.FontSize(15.5),
                              fontFamily: 'Manrope',
                              color: isMe ? Colors.white : AppColors.primaryColor,
                            ),
                            'p': html.Style(
                              margin: html.Margins.zero,
                              padding: html.HtmlPaddings.zero,
                            ),
                          },
                        ),
                      ),

                    // Edited status check
                    if (message.editedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Edited',
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ── Quoted message preview ────────────────────────────────────────────────

  Widget _buildQuotePreview(bool isMe) {
    final quoted = widget.quotedMessage!;
    return GestureDetector(
      onTap: () =>
          widget.onScrollToQuoted?.call(widget.message.quotedMessageId!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isMe ? 0.18 : 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isMe
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.primaryColor,
              width: 3,
            ),
          ),
        ),
        child: _StableHtml(
          data: quoted.text.length > 120
              ? '${quoted.text.substring(0, 120)}…'
              : quoted.text,
          style: {
            'body': html.Style(
              margin: html.Margins.zero,
              padding: html.HtmlPaddings.zero,
              fontSize: html.FontSize(13),
              fontFamily: 'Manrope',
              color: isMe
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.primaryColor,
            ),
            'p': html.Style(
              margin: html.Margins.zero,
              padding: html.HtmlPaddings.zero,
            ),
          },
        ),
      ),
    );
  }

  // ── Attachments ───────────────────────────────────────────────────────────

  Widget _buildAttachmentsPreview() {
    final attachments = widget.message.attachments;
    if (attachments.isEmpty) return const SizedBox.shrink();

    final images = attachments.where((a) => a.isImage).toList();
    final documents = attachments.where((a) => !a.isImage).toList();

    final imageCount = images.length;
    final hasMoreImages = imageCount > 4;
    final displayImages = hasMoreImages ? images.take(4).toList() : images;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = screenWidth * 0.70;
    final singleImageWidth = maxBubbleWidth * 0.9;
    final multiImageWidth = maxBubbleWidth * 0.48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (documents.isNotEmpty) ...[
          ...documents.map((att) {
            final source = att.displaySource;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  if (source == null) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'No file available to open',
                      isError: true,
                    );
                    return;
                  }
                  if (att.localPath != null) {
                    try {
                      await open_filex.OpenFilex.open(att.localPath!);
                    } catch (e) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Cannot open file: $e',
                        isError: true,
                      );
                    }
                  } else if (att.remoteUrl.isNotEmpty) {
                    try {
                      final response = await http.get(Uri.parse(att.remoteUrl));
                      if (response.statusCode == 200) {
                        final tempDir = await getTemporaryDirectory();
                        final tempFile = File('${tempDir.path}/${att.name}');
                        await tempFile.writeAsBytes(response.bodyBytes);
                        try {
                          await open_filex.OpenFilex.open(tempFile.path);
                        } catch (e) {
                          CoreUtils.showTopSnackBar(
                            context: context,
                            message: 'Cannot open: $e',
                            isError: true,
                          );
                        }
                      } else {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: 'Failed to download the file',
                          isError: true,
                        );
                      }
                    } catch (e) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Error: $e',
                        isError: true,
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: multiImageWidth * 0.35,
                        height: multiImageWidth * 0.45,
                        child: source != null
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                child: Thumbnail(
                                  mimeType: att.mimeType ?? 'application/pdf',
                                  dataResolver: () async {
                                    if (att.remoteUrl.isNotEmpty) {
                                      try {
                                        final r = await http.get(
                                          Uri.parse(source),
                                        );
                                        if (r.statusCode == 200)
                                          return r.bodyBytes;
                                      } catch (_) {}
                                      return Uint8List(0);
                                    }
                                    return await File(source).readAsBytes();
                                  },
                                  widgetSize: multiImageWidth * 0.4,
                                  decoration: WidgetDecoration(
                                    backgroundColor: Colors.white,
                                    iconColor: Colors.redAccent,
                                  ),
                                  errorBuilder: (context, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          size: 40,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  size: 40,
                                  color: Colors.redAccent,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextWidget(
                              text: att.name,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 4),
                            CustomTextWidget(
                              text:
                                  '${(att.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB • ${att.type.toUpperCase()}',
                              fontSize: 13,
                              fontColor: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (images.isNotEmpty) const SizedBox(height: 16),
        ],

        if (images.isNotEmpty) ...[
          if (imageCount == 1)
            GestureDetector(
              onTap: () {
                final att = displayImages.first;
                if (att.displaySource != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowFullScreenMediaView(
                        imageUrl: att.remoteUrl,
                        imageFile: att.localPath != null
                            ? File(att.localPath!)
                            : null,
                        title: att.name,
                      ),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: displayImages.first.displaySource != null
                    ? Thumbnail(
                        mimeType: displayImages.first.mimeType ?? 'image/jpeg',
                        dataResolver: () async {
                          final src = displayImages.first.displaySource!;
                          if (displayImages.first.remoteUrl.isNotEmpty) {
                            try {
                              final r = await http.get(Uri.parse(src));
                              if (r.statusCode == 200) return r.bodyBytes;
                            } catch (_) {}
                            return Uint8List(0);
                          }
                          return await File(src).readAsBytes();
                        },
                        widgetSize: singleImageWidth,
                        decoration: WidgetDecoration(
                          backgroundColor: Colors.white,
                          iconColor: Colors.green,
                        ),
                        errorBuilder: (context, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        height: singleImageWidth * 0.6,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                final att = displayImages[index];
                final isLast = index == displayImages.length - 1;
                final remaining = images.length - 4;

                return GestureDetector(
                  onTap: () {
                    if (hasMoreImages && isLast) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullAttachmentViewer(attachments: attachments),
                        ),
                      );
                    } else if (att.displaySource != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFullScreenMediaView(
                            imageUrl: att.remoteUrl,
                            imageFile: att.localPath != null
                                ? File(att.localPath!)
                                : null,
                            title: att.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: att.displaySource != null
                            ? Thumbnail(
                                mimeType: att.mimeType ?? 'image/jpeg',
                                dataResolver: () async {
                                  final src = att.displaySource!;
                                  if (att.remoteUrl.isNotEmpty) {
                                    try {
                                      final r = await http.get(Uri.parse(src));
                                      if (r.statusCode == 200)
                                        return r.bodyBytes;
                                    } catch (_) {}
                                    return Uint8List(0);
                                  }
                                  return await File(src).readAsBytes();
                                },
                                widgetSize: multiImageWidth,
                                decoration: WidgetDecoration(
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.green,
                                ),
                                errorBuilder: (context, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      if (hasMoreImages && isLast)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CustomTextWidget(
                              text: '+$remaining',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  // ── Time formatter ────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final schoolDateTime = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      dt,
      schoolTz,
    );
    return '${schoolDateTime.hour.toString().padLeft(2, '0')}:${schoolDateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Wraps html.Html so each mounted instance owns its own _anchorKey GlobalKey.
// flutter_html creates a HtmlParser(key: _anchorKey) inside _HtmlState.build().
// If _anchorKey is shared (e.g. via MessageBubble State fields) and the same
// widget tree is mounted in two places simultaneously (original bubble + the
// reactions-dialog preview), two HtmlParser widgets get the same GlobalKey →
// crash. Owning the key in THIS State means each placement gets its own key.
class _StableHtml extends StatefulWidget {
  final String data;
  final Map<String, html.Style> style;

  const _StableHtml({required this.data, required this.style});

  @override
  State<_StableHtml> createState() => _StableHtmlState();
}

class _StableHtmlState extends State<_StableHtml> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Wrap with decoration:none to prevent the dialog context's DefaultTextStyle
    // (no Material/Scaffold wrapper in HeroDialogRoute) from leaking yellow
    // underlines into flutter_html's text span rendering.
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: html.Html(
        anchorKey: _anchorKey,
        data: widget.data,
        style: widget.style,
      ),
    );
  }
}
