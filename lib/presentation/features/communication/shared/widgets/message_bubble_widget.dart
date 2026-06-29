import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_open_helper.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_url_resolver.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/link_preview_card.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/full_attachment_viewer.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

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
  final void Function(ChatAttachment attachment)? onDeleteAttachment;
  final void Function(String emoji)? onReactionAdded;
  final void Function(String emoji)? onRemoveReaction;
  final VoidCallback? onReactionTap;
  final bool isParentMessaging;
  final bool isInactive;
  final bool isDeleted;

  /// When true, the sender avatar and name header are hidden because this
  /// message is a continuation from the same sender as the one above it.
  final bool isGrouped;

  /// Whether THIS MESSAGE's sender is staff/admin/teacher/director (true) or
  /// guardian/parent (false). Null means "unknown/not applicable" — used by
  /// Staff Direct (1:1), which intentionally keeps the legacy "my message
  /// vs. their message" layout instead of the role-based one (see
  /// docs/messaging/06-ui-standards.md §6.2). Must be supplied together with
  /// [viewerIsGuardian] for the role-based layout to take effect.
  final bool? senderIsOrgSide;

  /// Whether the person currently viewing this thread is a guardian/parent.
  /// Null has the same "not applicable" meaning as [senderIsOrgSide] — both
  /// must be non-null together, or both are ignored.
  final bool? viewerIsGuardian;

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
    this.onDeleteAttachment,
    this.onReactionAdded,
    this.onRemoveReaction,
    this.onReactionTap,
    this.isParentMessaging = false,
    this.isInactive = false,
    this.isDeleted = false,
    this.isGrouped = false,
    this.senderIsOrgSide,
    this.viewerIsGuardian,
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
    if (oldWidget.message.reactions != widget.message.reactions ||
        oldWidget.message.id != widget.message.id ||
        oldWidget.message.code != widget.message.code) {
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
      final messageId = widget.message.code.isNotEmpty
          ? widget.message.code
          : widget.message.id;
      final reactions = widget.message.reactions.entries.map((e) {
        return Reaction(
          emoji: e.value,
          userId: e.key,
          timestamp: DateTime.now(),
        );
      }).toList();
      widget.reactionsController.loadReactions(messageId, reactions);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Swipe-to-reply is disabled for deleted or inactive messages.
    if (widget.onReply == null || widget.isDeleted || widget.isInactive) return;
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

  /// Drives every visual "which side/color does this bubble use" decision.
  ///
  /// When [MessageBubble.senderIsOrgSide] and [MessageBubble.viewerIsGuardian]
  /// are both supplied (Room Chat / Admin Chat), this implements the
  /// role-based rule: every staff/admin/teacher/director message shares one
  /// side+gradient regardless of which one of them sent it, and every
  /// guardian message shares the other side+gradient regardless of which
  /// guardian sent it.
  ///
  /// When either is null (Staff Direct, 1:1 — the one PRD-documented
  /// exception, see docs/messaging/06-ui-standards.md §6.2), falls back to
  /// the legacy "my message vs. their message" behavior driven by [_isMe].
  bool get _alignRight {
    final orgSide = widget.senderIsOrgSide;
    final guardianViewer = widget.viewerIsGuardian;
    if (orgSide == null || guardianViewer == null) return _isMe;
    return guardianViewer ? !orgSide : orgSide;
  }

  ChatReactionsConfig _buildReactionsConfig(bool isMe) {
    // Deleted messages: no Reply/Copy/Edit/Delete/Info regardless of who
    // sent it — there's no content left to act on. Reacting is still
    // allowed (matches WhatsApp/Telegram behavior for deleted messages).
    if (widget.isDeleted) {
      return const ChatReactionsConfig(
        availableReactions: ['👍', '❤️', '😂', '😮', '😢', '👏', '➕'],
        menuItems: [],
        enableLongPress: true,
        enableDoubleTap: false,
        showAddReactionButton: true,
        showContextMenu: false,
        enableHapticFeedback: true,
        reactionSize: 24,
      );
    }

    // Inactive messages: disable edits and deletes but allow reactions/reply
    if (widget.isInactive) {
      return ChatReactionsConfig(
        availableReactions: const ['👍', '❤️', '😂', '😮', '😢', '👏', '➕'],
        menuItems: const [
          MenuItem(label: 'Reply', icon: Icons.reply_rounded),
          MenuItem(label: 'Copy', icon: Icons.copy_outlined),
          MenuItem(label: 'Info', icon: Icons.info_outline),
        ],
        enableLongPress: true,
        enableDoubleTap: false,
        showAddReactionButton: true,
        showContextMenu: true,
        enableHapticFeedback: true,
        reactionSize: 24,
      );
    }

    return ChatReactionsConfig(
      availableReactions: const ['👍', '❤️', '😂', '😮', '😢', '👏', '➕'],
      menuItems: [
        if (isMe)
          const MenuItem(label: 'Edit', icon: Icons.edit_outlined),
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
        _showDeleteBottomSheet();
        break;
      case 'Info':
        widget.onInfo?.call();
        break;
    }
  }

  void _showDeleteBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF573353),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to delete this message?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(87, 51, 83, 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7175F4), Color(0xFF9287F4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF573353),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMe = _isMe;
    // Drives alignment/color (side this bubble renders on); `isMe` itself
    // stays reserved for identity-only decisions (the "You" label, the
    // Edit/Delete menu, and delivery/read ticks) that must never flip just
    // because two different people happen to share a side.
    final alignRight = _alignRight;
    final screenWidth = MediaQuery.of(context).size.width;
    // Resolve sender display name once before the widget tree.
    final senderLabel = isMe
        ? 'You'
        : MessageContentProcessor.senderDisplay(
            widget.message.senderName,
            widget.message.senderUserCode,
          );

    return GestureDetector(
      onHorizontalDragUpdate: (widget.onReply != null && !widget.isDeleted && !widget.isInactive) ? _onDragUpdate : null,
      onHorizontalDragEnd: (widget.onReply != null && !widget.isDeleted && !widget.isInactive) ? _onDragEnd : null,
      child: Padding(
        // Grouped messages get reduced top spacing — feels like a continuation.
        padding: EdgeInsets.only(
          top: widget.isGrouped ? 2.0 : 8.0,
          bottom: 8.0,
          left: 12.0,
          right: 12.0,
        ),
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
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
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
                alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: alignRight
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Avatar row (above bubble) — hidden when grouped
                      if (widget.isParentMessaging && !widget.isGrouped) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: alignRight
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

                      // Sender Name header — hidden when grouped
                      if (!widget.isGrouped)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            senderLabel,
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
                          // Edit/Delete menu visibility (inside
                          // _buildReactionsConfig) is gated on true identity
                          // (isMe), never alignRight — sharing a side with
                          // another staff member must not let you edit or
                          // delete their message.
                          config: _buildReactionsConfig(isMe),
                          alignment: alignRight
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          onReactionAdded: (emoji) {
                            final userCode = widget.currentUserCode ?? 'me';
                            final myReaction = widget.message.reactions[userCode];
                            if (myReaction != null && myReaction == emoji) {
                              widget.onRemoveReaction?.call(emoji);
                            } else {
                              widget.onReactionAdded?.call(emoji);
                            }
                          },
                          onMenuItemTapped: _handleMenuItemTap,
                          child: _buildBubble(alignRight, isMe),
                        ),
                      ),

                      // Stacked reactions badge below the bubble
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
                            padding: const EdgeInsets.only(top: 6),
                            child: GestureDetector(
                              onTap: widget.onReactionTap,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: StackedReactions(
                                  messageId: messageId,
                                  controller: widget.reactionsController,
                                  size: 24,
                                  stackedValue: 3,
                                  direction: alignRight
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

  Widget _buildBubble(bool alignRight, bool isMe) {
    final message = widget.message;
    final isDeleted = widget.isDeleted;
    final orgSide = widget.senderIsOrgSide;
    // Room/Admin Chat (orgSide non-null): BOTH sides are now colored
    // gradients — Staff Gradient for org-side senders, Pink Gradient for
    // guardian senders — so text/icon contrast must be light on either
    // side, not just on whichever side happens to be "isMe". Staff Direct
    // (orgSide null) keeps the legacy look: gradient (light text) only for
    // the viewer's own messages, flat light background (dark text) for the
    // other party's.
    final useLightText = orgSide != null ? true : isMe;
    final hasOnlyEmoji =
        message.text.trim().length <= 3 &&
        message.text.trim().runes.every(
          (r) =>
              (r >= 0x1F300 && r <= 0x1F9FF) || // Emojis
              (r >= 0x2600 && r <= 0x27BF) || // Emoji variations
              (r == 0x20),
        ); // Space

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(left: alignRight ? 60 : 0, right: alignRight ? 0 : 60),
        decoration: BoxDecoration(
          color: orgSide == null && !isMe
              ? const Color.fromRGBO(220, 230, 255, 1)
              : null,
          gradient: orgSide != null
              ? (orgSide
                    ? AppColors.buildStaffGradient()
                    : AppColors.buildPinkGradient())
              : (isMe ? AppColors.buildPrimaryGradient() : null),
          borderRadius: _buildBubbleBorderRadius(alignRight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: hasOnlyEmoji
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: isDeleted
              ? Text(
                  'This message has been deleted.',
                  style: TextStyle(
                    color: useLightText
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color.fromRGBO(87, 51, 83, 0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quoted preview
                      if (message.quotedMessageId != null &&
                          widget.quotedMessage != null)
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildQuotePreview(useLightText),
                        ),

                      // Attachments
                      if (message.hasAttachments) ...[
                        _buildAttachmentsPreview(),
                        if (message.text.trim().isNotEmpty)
                          const SizedBox(height: 8),
                      ],

                      // Message text — enriched HTML with auto-linked URLs/emails
                      if (message.text.trim().isNotEmpty)
                        Flexible(
                          fit: FlexFit.loose,
                          child: _StableHtml(
                            data: MessageContentProcessor.enrich(message.text),
                            linkColor: useLightText
                                ? Colors.white
                                : AppColors.primaryColor,
                            onLinkTap: MessageContentProcessor.launchLink,
                            style: {
                              'body': html.Style(
                                margin: html.Margins.zero,
                                padding: html.HtmlPaddings.zero,
                                fontSize: html.FontSize(15.5),
                                fontFamily: 'Manrope',
                                color: useLightText
                                    ? Colors.white
                                    : AppColors.primaryColor,
                              ),
                              'p': html.Style(
                                margin: html.Margins.zero,
                                padding: html.HtmlPaddings.zero,
                              ),
                            },
                          ),
                        ),

                      // Link preview card — shown for the first URL found in the
                      // message text. Only rendered for non-deleted messages that
                      // actually contain an http/https URL.
                      if (!isDeleted) ...[
                        Builder(
                          builder: (_) {
                            final previewUrl = extractFirstUrl(message.text);
                            if (previewUrl == null)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: LinkPreviewCard(
                                url: previewUrl,
                                isMe: useLightText,
                              ),
                            );
                          },
                        ),
                      ],

                      // Edited status check
                      if (message.editedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Edited',
                          style: TextStyle(
                            color: useLightText
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],

                      // Private message label chip (PRD AC7)
                      if (message.isPrivate) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 12,
                              color: useLightText
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFFD63031),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Private Message',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: useLightText
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFFD63031),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Time and delivery status at bottom of bubble
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: alignRight
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(widget.message.time),
                            style: TextStyle(
                              color: useLightText
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey[600],
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          // Read/delivery ticks are identity-only — only the
                          // literal sender (isMe) sees their own message's
                          // delivery status, regardless of which side it
                          // renders on.
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.message.isRead
                                  ? Icons.done_all
                                  : widget.message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: widget.message.isRead
                                  ? AppColors.primaryColor
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Build asymmetric border radius for WhatsApp-style tail effect.
  /// Sent (right): Large radius on top-left, bottom-left, top-right; small on bottom-right.
  /// Received (left): Large radius on top-right, bottom-right, top-left; small on bottom-left.
  BorderRadius _buildBubbleBorderRadius(bool isMe) {
    const double largeRadius = 18.0;
    const double tailRadius = 4.0;

    if (isMe) {
      return BorderRadius.only(
        topLeft: const Radius.circular(largeRadius),
        topRight: const Radius.circular(largeRadius),
        bottomLeft: const Radius.circular(largeRadius),
        bottomRight: const Radius.circular(tailRadius),
      );
    } else {
      return BorderRadius.only(
        topLeft: const Radius.circular(largeRadius),
        topRight: const Radius.circular(largeRadius),
        bottomRight: const Radius.circular(largeRadius),
        bottomLeft: const Radius.circular(tailRadius),
      );
    }
  }

  // ── Quoted message preview ────────────────────────────────────────────────

  Widget _buildQuotePreview(bool isMe) {
    final quoted = widget.quotedMessage!;
    return GestureDetector(
      onTap: () =>
          widget.onScrollToQuoted?.call(widget.message.quotedMessageId!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isMe ? 0.15 : 0.60),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.85)
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
              fontSize: html.FontSize(13.5),
              fontFamily: 'Manrope',
              color: isMe
                  ? Colors.white.withValues(alpha: 0.92)
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
            // A fixed-size icon (no in-box text/thumbnail rendering) — long
            // filenames are shown separately below and must never make this
            // box grow, or its parent RenderFlex overflows (seen with long
            // names like "WhatsApp Image 2026-06-16 at 10.21.27.jpeg").
            final iconData =
                Thumbnailer.getIconDataForMimeType(att.mimeType) ??
                FontAwesomeIcons.filePdf;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => AttachmentOpenHelper.open(context, att),
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
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FaIcon(
                              iconData,
                              size: 32,
                              color: Colors.redAccent,
                            ),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
            AttachmentUrlResolver(
              attachment: displayImages.first,
              builder: (context, resolvedUrl, isLoading, isProcessing) {
                final att = (resolvedUrl != null && resolvedUrl.isNotEmpty)
                    ? displayImages.first.copyWith(remoteUrl: resolvedUrl)
                    : displayImages.first;
                final hasSource = att.displaySource != null;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (hasSource) {
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
                        child: hasSource
                            ? Thumbnail(
                                mimeType: att.mimeType.isNotEmpty
                                    ? att.mimeType
                                    : 'image/jpeg',
                                dataResolver: () async {
                                  final src = att.displaySource!;
                                  // `displaySource` prefers `localPath` over
                                  // `remoteUrl` — checking `remoteUrl.isNotEmpty`
                                  // here was wrong whenever both were set
                                  // (e.g. right after upload), since it would
                                  // then try to HTTP-fetch what is actually a
                                  // local file path. Decide from `src` itself.
                                  final isRemote =
                                      src.startsWith('http://') ||
                                      src.startsWith('https://');
                                  if (isRemote) {
                                    try {
                                      final r = await http.get(Uri.parse(src));
                                      if (r.statusCode == 200)
                                        return r.bodyBytes;
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
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : isProcessing
                                      ? const _AttachmentProcessingPlaceholder()
                                      : const Icon(
                                          Icons.broken_image,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
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
                final rawAtt = displayImages[index];
                final isLast = index == displayImages.length - 1;
                final remaining = images.length - 4;

                return AttachmentUrlResolver(
                  attachment: rawAtt,
                  builder: (context, resolvedUrl, isLoading, isProcessing) {
                    final att = (resolvedUrl != null && resolvedUrl.isNotEmpty)
                        ? rawAtt.copyWith(remoteUrl: resolvedUrl)
                        : rawAtt;
                    final hasSource = att.displaySource != null;
                    return GestureDetector(
                      onTap: () {
                        if (hasMoreImages && isLast) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullAttachmentViewer(
                                attachments: attachments,
                              ),
                            ),
                          );
                        } else if (hasSource) {
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
                            child: hasSource
                                ? Thumbnail(
                                    mimeType: att.mimeType.isNotEmpty
                                        ? att.mimeType
                                        : 'image/jpeg',
                                    dataResolver: () async {
                                      final src = att.displaySource!;
                                      // See single-image branch above: decide
                                      // remote-vs-local from `src` itself, not
                                      // `remoteUrl.isNotEmpty` (wrong whenever
                                      // localPath is also set, which is what
                                      // `displaySource` actually returns).
                                      final isRemote =
                                          src.startsWith('http://') ||
                                          src.startsWith('https://');
                                      if (isRemote) {
                                        try {
                                          final r = await http.get(
                                            Uri.parse(src),
                                          );
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
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : isProcessing
                                          ? const _AttachmentProcessingPlaceholder(
                                              compact: true,
                                            )
                                          : const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                          ),
                          if (hasMoreImages && isLast)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
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
    final hhMM =
        '${schoolDateTime.hour.toString().padLeft(2, '0')}:${schoolDateTime.minute.toString().padLeft(2, '0')}';
    return MessageContentProcessor.smartBubbleTime(dt, hhMM);
  }
}

/// Shown instead of the broken-image icon when the backend has reported the
/// attachment's asset as still `PROCESSING` (no delivery URL yet) rather
/// than an outright failure — tells the user it's still on its way instead
/// of looking like a load error.
class _AttachmentProcessingPlaceholder extends StatelessWidget {
  const _AttachmentProcessingPlaceholder({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: const CircularProgressIndicator(strokeWidth: 2.5),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Processing…',
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
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

  /// Called when a link (`<a href>`) inside the HTML is tapped.
  final void Function(String? href)? onLinkTap;

  /// Color used for `<a>` tags. Defaults to [AppColors.primaryColor].
  final Color? linkColor;

  const _StableHtml({
    required this.data,
    required this.style,
    this.onLinkTap,
    this.linkColor,
  });

  @override
  State<_StableHtml> createState() => _StableHtmlState();
}

class _StableHtmlState extends State<_StableHtml> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final linkColor = widget.linkColor ?? AppColors.primaryColor;

    // Merge caller styles with the <a> tag style so links are always
    // visually distinguishable (underlined, same color as message text).
    final mergedStyle = {
      ...widget.style,
      'a': html.Style(
        color: linkColor,
        textDecoration: TextDecoration.underline,
        textDecorationColor: linkColor,
        fontWeight: FontWeight.w600,
      ),
    };

    // Wrap with decoration:none to prevent the dialog context's DefaultTextStyle
    // (no Material/Scaffold wrapper in HeroDialogRoute) from leaking yellow
    // underlines into flutter_html's text span rendering.
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: html.Html(
        anchorKey: _anchorKey,
        data: widget.data,
        style: mergedStyle,
        onLinkTap: widget.onLinkTap != null
            ? (url, _, __) => widget.onLinkTap!(url)
            : null,
      ),
    );
  }
}
