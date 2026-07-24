import 'dart:io';
import 'package:wowcare/core/util/app_time.dart';
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
import 'package:wowcare/presentation/features/communication/shared/utils/messaging_time_formatter.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/full_attachment_viewer.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Message? quotedMessage;
  final String? currentUserCode;

  /// Conversation participants — used to resolve the sender's real avatar
  /// (imageUrl/staffCode) for the Parent Messaging sender header. Without
  /// this, the header row has only [Message.senderName], which
  /// [DocumentImageWidget] cannot resolve a photo from, so it always fell
  /// back to initials even when the sender has a real profile photo.
  final List<ConversationParticipant>? participants;
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
  /// vs. their message" two-tone look instead of the role-colored one (see
  /// docs/messaging/06-ui-standards.md §6.2). When non-null (Room Chat /
  /// Admin Chat), it drives bubble *color* for messages that aren't mine —
  /// it never drives alignment, which is always identity-based (see
  /// [_alignRight]).
  final bool? senderIsOrgSide;

  const MessageBubble({
    required this.message,
    required this.reactionsController,
    this.quotedMessage,
    this.currentUserCode,
    this.participants,
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
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  // ── Swipe-to-reply ────────────────────────────────────────────────────────
  double _dragOffset = 0;
  double _snapStartOffset = 0;
  bool _replyTriggered = false;
  late final AnimationController _snapController;

  // One-shot scale+fade entrance played when an emoji-only message first mounts.
  late final AnimationController _emojiEntranceController;
  // Curved version of the entrance animation — created once, not per-frame.
  late final CurvedAnimation _emojiScaleCurve;

  // Tracks message IDs that have already played their entrance animation so
  // the animation does not replay when the conversation is reopened.
  static final Set<String> _animatedMessageIds = {};

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

    _emojiEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _emojiScaleCurve = CurvedAnimation(
      parent: _emojiEntranceController,
      curve: Curves.elasticOut,
    );
    // Only animate for emoji-only messages. For all others set value = 1 so
    // the AnimatedBuilder renders at full scale immediately with zero overhead.
    final msg = widget.message;
    final isEmojiMsg =
        !widget.isDeleted &&
        !msg.hasAttachments &&
        msg.quotedMessageId == null &&
        _analyzeEmojiText(msg.text).isOnly;
    final messageId = msg.code.isNotEmpty ? msg.code : widget.message.id;
    if (isEmojiMsg && !_animatedMessageIds.contains(messageId)) {
      _animatedMessageIds.add(messageId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emojiEntranceController.forward();
      });
    } else {
      _emojiEntranceController.value = 1.0;
    }

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
    _emojiScaleCurve.dispose();
    _emojiEntranceController.dispose();
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
      final reactions = widget.message.reactions.map((r) {
        return Reaction(
          emoji: r.emoji,
          userId: r.userCode,
          timestamp: AppTime.now(),
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

  /// Which side this bubble renders on. Role ([MessageBubble.senderIsOrgSide])
  /// dictates alignment for Room Chat (org side on right, parent on left).
  /// Falls back to identity (_isMe) for Staff Direct.
  bool get _alignRight {
    // If the current user is a guardian/parent (indicated by isParentMessaging)
    if (widget.isParentMessaging) {
      // Their own messages go right, all others (staff or other parents) go left.
      return _isMe;
    } else {
      // For other user roles (e.g., staff, admin), the existing logic applies.
      if (widget.senderIsOrgSide != null) {
        return widget.senderIsOrgSide!;
      }
      return _isMe;
    }
  }

  ChatReactionsConfig _buildReactionsConfig(bool isMe) {
    // Deleted messages: no Reply/Copy/Edit/Delete/Info and no reactions — there's no
    // content left to act on, and we don't show reaction pills on a deleted message, so
    // reacting is disabled entirely (no long-press picker / double-tap) to stay consistent.
    if (widget.isDeleted) {
      return const ChatReactionsConfig(
        availableReactions: [],
        menuItems: [],
        enableLongPress: false,
        enableDoubleTap: false,
        showAddReactionButton: false,
        showContextMenu: false,
        enableHapticFeedback: false,
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
        enableDoubleTap: true,
        showAddReactionButton: false,
        showContextMenu: true,
        enableHapticFeedback: true,
        reactionSize: 24,
      );
    }

    return ChatReactionsConfig(
      availableReactions: const ['👍', '❤️', '😂', '😮', '😢', '👏', '➕'],
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
      enableDoubleTap: true,
      showAddReactionButton: false,
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

  /// The emoji the current user has already reacted with on this message, or
  /// null. Reactions are keyed by the backend `userCode`; match it against the
  /// current user's code case-insensitively so a casing/format difference never
  /// makes the toggle miss and re-add instead of removing.
  String? _myReactionEmoji() {
    final mine = widget.message.reactionsOf(widget.currentUserCode ?? '');
    return mine.isEmpty ? null : mine.first;
  }

  /// Whether the current user has already reacted with [emoji] on this message.
  bool _iHaveReaction(String emoji) =>
      widget.message.userHasReaction(widget.currentUserCode ?? '', emoji);

  /// Tapping a specific reaction chip toggles just THAT emoji for the current
  /// user: remove it if I already reacted with it, otherwise join with it.
  /// This satisfies "click on an existing reaction should get it deleted"
  /// without disturbing the user's other emojis.
  void _handleEmojiChipTap(String emoji) {
    if (_iHaveReaction(emoji)) {
      widget.onRemoveReaction?.call(emoji);
    } else {
      widget.onReactionAdded?.call(emoji);
    }
    HapticFeedback.selectionClick();
  }

  void _handleDoubleTapReaction() {
    if (widget.isDeleted) return;

    const emoji = '❤️';
    // Double-tap toggles ONLY the heart for the current user, independent of
    // any other emojis they may have placed.
    if (_iHaveReaction(emoji)) {
      widget.onRemoveReaction?.call(emoji);
    } else {
      widget.onReactionAdded?.call(emoji);
      _showHeartOverlay();
    }

    HapticFeedback.mediumImpact();
  }

  /// Tapping the existing reaction badge removes YOUR reaction (toggle off). If
  /// you haven't reacted, fall back to the old behaviour (focus the input).
  void _handleExistingReactionTap() {
    final mine = _myReactionEmoji();
    if (mine != null) {
      widget.onRemoveReaction?.call(mine);
      HapticFeedback.selectionClick();
    } else {
      widget.onReactionTap?.call();
    }
  }

  // ── Heart floating-overlay animation ─────────────────────────────────────

  void _showHeartOverlay() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final center = Offset(
      offset.dx + size.width / 2,
      offset.dy + size.height / 2,
    );

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    OverlayEntry? entry;
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        entry?.remove();
        entry = null;
        ctrl.dispose();
      }
    });

    entry = OverlayEntry(
      builder: (_) => _HeartFloatOverlay(center: center, controller: ctrl),
    );

    Overlay.of(context, rootOverlay: true).insert(entry!);
    ctrl.forward();
  }

  void _showPrivateMessageToast() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'This is a private message.',
    );
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

  // ── Emoji analysis ────────────────────────────────────────────────────────

  /// Returns `(isOnly: true, count: N)` when [text] contains 1–3 emoji and
  /// nothing else (whitespace, ZWJ, variation-selectors, and skin-tone
  /// modifiers are ignored). Returns `(isOnly: false, count: 0)` otherwise.
  ///
  /// Uses code-point ranges rather than the `characters` package so no extra
  /// dependency is needed. The check deliberately covers the most common emoji
  /// blocks; obscure symbols that look like emoji but live outside those blocks
  /// fall back to the normal bubble renderer, which is acceptable.
  static ({bool isOnly, int count}) _analyzeEmojiText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return (isOnly: false, count: 0);

    final runes = trimmed.runes.toList();
    int baseCount = 0;

    for (final r in runes) {
      // ── Skip non-visible modifiers ─────────────────────────────────────
      if (r == 0x20 || r == 0x09 || r == 0x0A || r == 0x0D) continue; // WS
      if (r == 0x200D) continue; // ZWJ (Zero Width Joiner)
      if (r == 0xFE0E || r == 0xFE0F) continue; // Variation selectors 15 & 16
      if (r >= 0x1F3FB && r <= 0x1F3FF) continue; // Fitzpatrick skin-tone
      if (r == 0x20E3) continue; // Combining Enclosing Keycap
      if (r >= 0xE0020 && r <= 0xE007F) continue; // Tags (subdivision flags)

      if (_isBaseEmojiCodePoint(r)) {
        baseCount++;
      } else {
        return (isOnly: false, count: 0);
      }
    }

    final valid = baseCount > 0 && baseCount <= 3;
    return (isOnly: valid, count: valid ? baseCount : 0);
  }

  static bool _isBaseEmojiCodePoint(int r) {
    // Primary emoji range: emoticons, misc symbols & pictographs (😀 … 🧿)
    if (r >= 0x1F300 && r <= 0x1F9FF) return true;
    // Extended symbols & pictographs (🤀 … 🫿)
    if (r >= 0x1FA00 && r <= 0x1FAFF) return true;
    // Regional indicators – used as two-letter flag pairs
    if (r >= 0x1F1E0 && r <= 0x1F1FF) return true;
    // Mahjong tiles / playing cards
    if (r >= 0x1F000 && r <= 0x1F0FF) return true;
    // Enclosed alphanumeric supplement (Ⓜ️ etc.)
    if (r >= 0x1F100 && r <= 0x1F2FF) return true;
    // Misc symbols & dingbats (☀ … ✿) — the block containing ❤️, ☎, ✈ etc.
    if (r >= 0x2600 && r <= 0x27BF) return true;
    // Common 2-byte BMP emoji that appear outside the above blocks
    if (r >= 0x231A && r <= 0x231B) return true; // ⌚⌛
    if (r >= 0x23E9 && r <= 0x23F3) return true; // ⏩–⏳
    if (r >= 0x23F8 && r <= 0x23FA) return true; // ⏸⏹⏺
    if (r == 0x24C2) return true; // Ⓜ
    if (r >= 0x25AA && r <= 0x25AB) return true; // ▪▫
    if (r == 0x25B6 || r == 0x25C0) return true; // ▶◀
    if (r >= 0x25FB && r <= 0x25FE) return true; // ◻◼◽◾
    if (r >= 0x2614 && r <= 0x2615) return true; // ☔☕
    if (r >= 0x2648 && r <= 0x2653) return true; // ♈–♓
    if (r == 0x267F || r == 0x2693) return true; // ♿⚓
    if (r == 0x26A1) return true; // ⚡
    if (r >= 0x26AA && r <= 0x26AB) return true; // ⚪⚫
    if (r == 0x26BD || r == 0x26BE) return true; // ⚽⚾
    if (r >= 0x26C4 && r <= 0x26C5) return true; // ⛄⛅
    if (r == 0x2702) return true; // ✂
    if (r == 0x2705) return true; // ✅
    if (r >= 0x2708 && r <= 0x270D) return true; // ✈–✍
    if (r == 0x270F || r == 0x2712) return true; // ✏✒
    if (r == 0x2714 || r == 0x2716) return true; // ✔✖
    if (r == 0x2728) return true; // ✨
    if (r == 0x274C || r == 0x274E) return true; // ❌❎
    if (r >= 0x2753 && r <= 0x2757) return true; // ❓❔❕❗
    if (r >= 0x2763 && r <= 0x2764) return true; // ❣❤
    if (r >= 0x2795 && r <= 0x2797) return true; // ➕➖➗
    if (r == 0x27A1) return true; // ➡
    if (r == 0x27B0 || r == 0x27BF) return true; // ➰➿
    if (r >= 0x2934 && r <= 0x2935) return true; // ⤴⤵
    if (r >= 0x2B05 && r <= 0x2B07) return true; // ⬅⬆⬇
    if (r >= 0x2B1B && r <= 0x2B1C) return true; // ⬛⬜
    if (r == 0x2B50 || r == 0x2B55) return true; // ⭐⭕
    if (r == 0x3030 || r == 0x303D) return true; // 〰〽
    if (r == 0x3297 || r == 0x3299) return true; // ㊗㊙
    return false;
  }

  /// Looks up the sender's participant record (for [avatarUrl]/[staffCode])
  /// by matching [Message.senderUserCode] — the message itself carries no
  /// avatar data, only a name.
  ConversationParticipant? _senderParticipant() {
    final code = widget.message.senderUserCode;
    if (code == null || code.isEmpty) return null;
    for (final p in widget.participants ?? const <ConversationParticipant>[]) {
      if (p.userCode == code) return p;
    }
    return null;
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
      onHorizontalDragUpdate:
          (widget.onReply != null && !widget.isDeleted && !widget.isInactive)
          ? _onDragUpdate
          : null,
      onHorizontalDragEnd:
          (widget.onReply != null && !widget.isDeleted && !widget.isInactive)
          ? _onDragEnd
          : null,
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
                alignment: alignRight
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: alignRight
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Sender header row (avatar + name) — hidden when grouped.
                      // Parent Messaging shows avatar + name side-by-side;
                      // Staff Direct shows name only (no avatar on the message).
                      if (!widget.isGrouped)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            // Mirror the header on right-aligned bubbles so the avatar sits on
                            // the outer edge (the bubble's side), matching the web chat.
                            textDirection: alignRight
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              // Show the sender's avatar for everyone EXCEPT the viewer's own
                              // messages (no avatar for "You"). Parent Messaging keeps its avatar;
                              // Room/Admin now show it too, on both sides.
                              if (widget.isParentMessaging || !isMe) ...[
                                Builder(
                                  builder: (_) {
                                    final sender = _senderParticipant();
                                    final avatarUrl =
                                        sender?.avatarUrl?.trim() ?? '';
                                    return DocumentImageWidget(
                                      fileUuid: '',
                                      imageUrl: avatarUrl.startsWith('http')
                                          ? avatarUrl
                                          : null,
                                      mediaAssetCode:
                                          avatarUrl.isNotEmpty &&
                                              !avatarUrl.startsWith('http')
                                          ? avatarUrl
                                          : null,
                                      staffCode: sender?.staffCode,
                                      name: widget.message.senderName ?? '',
                                      size: 20,
                                      fontSize: 10,
                                    );
                                  },
                                ),
                                const SizedBox(width: 6.0),
                              ],
                              Text(
                                senderLabel,
                                style: const TextStyle(
                                  color: Color.fromRGBO(87, 51, 83, 0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Bubble wrapped with ChatMessageWrapper
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.72,
                        ),
                        child: RepaintBoundary(
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
                              // ➕ focuses the chat input (Task 4) rather than
                              // adding a literal ➕ emoji reaction or opening
                              // a third-party emoji picker.
                              if (emoji == '➕') {
                                widget.onReactionTap?.call();
                                return;
                              }
                              // Picking an emoji you already applied toggles it
                              // off; picking a NEW one joins it (Slack-style) —
                              // a user may hold multiple distinct emojis, so
                              // adding one must not remove the others.
                              if (_iHaveReaction(emoji)) {
                                widget.onRemoveReaction?.call(emoji);
                              } else {
                                widget.onReactionAdded?.call(emoji);
                              }
                            },
                            onMenuItemTapped: _handleMenuItemTap,
                            child: GestureDetector(
                              onDoubleTap: _handleDoubleTapReaction,
                              child: _buildBubble(alignRight, isMe),
                            ),
                          ),
                        ),
                      ),

                      // Telegram-style animated reaction badge — overlaps the
                      // bubble's bottom edge by 6 px via Transform.translate.
                      // _AnimatedReactionBadge preserves its own state across
                      // AnimatedBuilder rebuilds so per-emoji spring animations
                      // fire only for newly added/removed reactions.
                      // Deleted messages show no reaction pills.
                      if (!widget.isDeleted)
                      AnimatedBuilder(
                        animation: widget.reactionsController,
                        builder: (context, _) {
                          final messageId = widget.message.code.isNotEmpty
                              ? widget.message.code
                              : widget.message.id;
                          final counts = widget.reactionsController
                              .getReactionCounts(messageId);
                          return Transform.translate(
                            offset: const Offset(0, -6),
                            child: _AnimatedReactionBadge(
                              counts: counts,
                              // Per-chip toggle: tapping a specific emoji
                              // adds/removes just that emoji for the current
                              // user. Whole-badge onTap kept as a fallback.
                              onEmojiTap: _handleEmojiChipTap,
                              onTap: _handleExistingReactionTap,
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
    // Room/Admin Chat (orgSide non-null): "my" message always keeps the
    // current sender gradient (light text) no matter which side of the
    // conversation I'm on. A message that isn't mine is colored by the
    // *sender's* role instead: an org-side (staff/admin/teacher/director)
    // sender gets a flat white bubble with primary-colored text, a
    // guardian sender keeps the pink gradient (light text). Staff Direct
    // (orgSide null) keeps the legacy look: gradient (light text) only for
    // the viewer's own messages, flat light background (dark text) for the
    // other party's.
    final useLightText = orgSide == null ? isMe : !(orgSide && !isMe);

    // Emoji-only analysis — skip for deleted / attached / quoted messages so
    // those always render through the normal bubble with full metadata.
    final emojiAnalysis =
        !isDeleted && !message.hasAttachments && message.quotedMessageId == null
        ? _analyzeEmojiText(message.text)
        : (isOnly: false, count: 0);
    final hasOnlyEmoji = emojiAnalysis.isOnly;
    final emojiCount = emojiAnalysis.count;

    // ── WhatsApp-style large emoji rendering ───────────────────────────────
    // Emoji-only messages (1–3 emoji, no attachments, no quoted reply, not
    // deleted) bypass the normal bubble container entirely: they render at a
    // larger font size on a transparent background, exactly like WhatsApp.
    if (hasOnlyEmoji && emojiCount > 0) {
      return _buildEmojiOnlyBubble(alignRight, isMe, emojiCount);
    }

    Color? bubbleColor;
    LinearGradient? bubbleGradient;
    if (orgSide == null) {
      // Staff Direct (1:1) — legacy "my message vs. their message" look.
      bubbleColor = isMe ? null : const Color.fromRGBO(220, 230, 255, 1);
      bubbleGradient = isMe ? AppColors.buildPrimaryGradient() : null;
    } else if (isMe) {
      bubbleGradient = AppColors.buildPrimaryGradient();
    } else if (orgSide) {
      bubbleColor = Colors.white;
    } else {
      bubbleGradient = AppColors.buildPinkGradient();
    }

    return Material(
      color: Colors.transparent,
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            gradient: bubbleGradient,
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
                : Column(
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

                      // Message text — plain text uses the native Text widget so
                      // the bubble shrinks tightly around its content (WhatsApp-
                      // style). HTML-formatted or link-containing text falls back
                      // to the full HTML renderer which fills available width —
                      // acceptable because such messages tend to be longer.
                      if (message.text.trim().isNotEmpty)
                        _buildMessageText(message.text, useLightText),

                      // Link preview card — shown for the first URL found in the
                      // message text. Only rendered for non-deleted messages that
                      // actually contain an http/https URL.
                      if (!isDeleted) ...[
                        Builder(
                          builder: (_) {
                            final preview =
                                MessageContentProcessor.detectFirstPreview(
                                  message.text,
                                );
                            if (preview == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: PreviewCard(
                                preview: preview,
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
                          if (message.isPrivate &&
                              widget.senderIsOrgSide != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _showPrivateMessageToast,
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: useLightText
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFFD63031),
                              ),
                            ),
                          ],
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

  // ── WhatsApp-style emoji-only bubble ─────────────────────────────────────

  /// Renders 1–3 emoji at WhatsApp-scale on a transparent background (no
  /// bubble chrome). Font size: 52 px (1 emoji) → 42 px (2) → 34 px (3).
  /// Wrapped in the one-shot [_emojiEntranceController] spring animation.
  Widget _buildEmojiOnlyBubble(bool alignRight, bool isMe, int emojiCount) {
    final message = widget.message;
    final fontSize = emojiCount == 1
        ? 52.0
        : emojiCount == 2
        ? 42.0
        : 34.0;

    final emojiWidget = AnimatedBuilder(
      animation: _emojiEntranceController,
      builder: (context, child) {
        // ElasticOut gives a soft spring overshoot — identical to WhatsApp's
        // single-emoji bounce. _emojiScaleCurve is created once in initState
        // so no allocation happens per frame. The controller's raw value
        // drives opacity to fade in alongside the scale.
        final scale = (0.25 + 0.75 * _emojiScaleCurve.value).clamp(0.0, 1.3);
        final opacity = _emojiEntranceController.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Text(
        message.text.trim(),
        style: TextStyle(
          fontSize: fontSize,
          height: 1.15,
          // Explicit colour + decoration prevent DefaultTextStyle leakage
          // from dialog or Overlay contexts (same issue _StableHtml solves).
          color: Colors.black,
          decoration: TextDecoration.none,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          emojiWidget,
          const SizedBox(height: 2),
          // Timestamp + ticks row — same semantics as the normal bubble.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(widget.message.time),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
              if (message.isPrivate && widget.senderIsOrgSide != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showPrivateMessageToast,
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: Color(0xFFD63031),
                  ),
                ),
              ],
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.message.isRead
                      ? Icons.done_all
                      : widget.message.isDelivered
                      ? Icons.done_all
                      : Icons.done,
                  size: 13,
                  color: widget.message.isRead
                      ? AppColors.primaryColor
                      : Colors.grey.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Adaptive message-text renderer ───────────────────────────────────────

  Widget _buildMessageText(String rawText, bool useLightText) {
    final plain = rawText.trim();
    final textColor = useLightText ? Colors.white : AppColors.primaryColor;

    final isHtml = plain.contains('<');

    // Only use the HTML renderer for pre-formatted HTML or messages with actual
    // clickable URL links. Phone numbers and email addresses are intentionally
    // excluded: the phone-number regex (`_phonePattern`) matches dates, room
    // numbers, and other digit sequences, causing messages like "See you at 3"
    // to route through html.Html — a block element that always fills available
    // width regardless of content length, making every short bubble wide.
    // Phone/email remain tappable via PreviewCard below the bubble.
    final hasUrl =
        !isHtml &&
        MessageContentProcessor.detectFirstPreview(plain)?.kind ==
            PreviewKind.url;

    if (!isHtml && !hasUrl) {
      // Native Text: measures only its glyphs so the bubble Container shrinks
      // to exactly the text width (plus padding). Short messages get small
      // bubbles; long messages wrap and fill up to the 72% maxWidth constraint.
      return Text(
        plain,
        style: TextStyle(
          fontSize: 15.5,
          fontFamily: 'Manrope',
          height: 1.35,
          color: textColor,
          decoration: TextDecoration.none,
        ),
      );
    }

    return _StableHtml(
      data: MessageContentProcessor.enrich(rawText),
      linkColor: useLightText ? const Color(0xFF64B5F6) : Colors.blue,
      onLinkTap: MessageContentProcessor.launchLink,
      style: {
        'body': html.Style(
          margin: html.Margins.zero,
          padding: html.HtmlPaddings.zero,
          fontSize: html.FontSize(15.5),
          fontFamily: 'Manrope',
          color: textColor,
        ),
        'p': html.Style(
          margin: html.Margins.zero,
          padding: html.HtmlPaddings.zero,
        ),
      },
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
          linkColor: isMe ? const Color(0xFF64B5F6) : Colors.blue,
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

  String _formatTime(DateTime dt) => MessagingTimeFormatter.bubbleTime(dt);
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

// ── Double-tap heart floating overlay ────────────────────────────────────────

/// A ❤️ that floats at [center], springs to full size via [Curves.elasticOut],
/// holds briefly, then fades out. Lives in the root [Overlay] so it appears
/// on top of everything — no build-tree impact on [MessageBubble].
///
/// Lifecycle: the parent creates a fresh [AnimationController] per double-tap,
/// forwards it, and disposes it (plus removes the [OverlayEntry]) in the
/// controller's [AnimationStatus.completed] listener — zero leaks.
class _HeartFloatOverlay extends StatelessWidget {
  const _HeartFloatOverlay({required this.center, required this.controller});

  final Offset center;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // Phase 1 (0–65 %): spring scale 0.2 → 1.4 with elastic overshoot.
    // Phase 2 (65–75 %): settle back to 1.0.
    // Phase 3 (75–100 %): hold at 1.0 while fading out.
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.2,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    ]).animate(controller);

    final opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Positioned(
        // Centre the 60×60 emoji on the bubble's midpoint.
        left: center.dx - 30,
        top: center.dy - 30,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacityAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scaleAnim.value,
              child: const Text(
                '❤️',
                style: TextStyle(fontSize: 50, decoration: TextDecoration.none),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Telegram-style animated reaction badge ────────────────────────────────────

/// Compact emoji-reaction pill that animates each emoji independently:
///  • Added emoji  → spring scale 0.6 → 1.15 → 1.0  +  fade-in  (~300 ms)
///  • Removed emoji → shrink to 0.8  +  fade-out               (~200 ms)
///  • Existing emojis stay stable — no unnecessary rebuilds.
///
/// Flutter preserves widget State across [AnimatedBuilder] rebuilds (same
/// runtimeType + position in tree), so [didUpdateWidget] fires whenever the
/// parent passes new [counts], allowing per-emoji diff and targeted animation.
class _AnimatedReactionBadge extends StatefulWidget {
  const _AnimatedReactionBadge({
    required this.counts,
    this.onTap,
    this.onEmojiTap,
  });

  final Map<String, int> counts;

  /// Fallback tap on the whole badge (used only when [onEmojiTap] is null).
  final VoidCallback? onTap;

  /// Per-chip tap — called with the specific emoji whose chip was tapped so the
  /// bubble can toggle just that emoji for the current user.
  final ValueChanged<String>? onEmojiTap;

  @override
  State<_AnimatedReactionBadge> createState() => _AnimatedReactionBadgeState();
}

class _AnimatedReactionBadgeState extends State<_AnimatedReactionBadge>
    with TickerProviderStateMixin {
  // Per-emoji animation controllers (scale + opacity share the same timeline).
  final Map<String, AnimationController> _controllers = {};

  // The counts currently rendered, which may include emojis still fading out.
  late Map<String, int> _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = Map.from(widget.counts);
    for (final emoji in widget.counts.keys) {
      _ensureController(emoji, animate: false);
    }
  }

  @override
  void didUpdateWidget(_AnimatedReactionBadge old) {
    super.didUpdateWidget(old);
    final prev = old.counts.keys.toSet();
    final next = widget.counts.keys.toSet();

    // Newly added emojis — spring in.
    for (final emoji in next.difference(prev)) {
      _ensureController(emoji, animate: true);
      setState(() => _displayed[emoji] = widget.counts[emoji]!);
    }

    // Removed emojis — shrink + fade out, then remove from display.
    for (final emoji in prev.difference(next)) {
      _animateOut(emoji);
    }

    // Count changes on existing emojis — update display immediately.
    for (final emoji in next.intersection(prev)) {
      if (old.counts[emoji] != widget.counts[emoji]) {
        setState(() => _displayed[emoji] = widget.counts[emoji]!);
      }
    }
  }

  void _ensureController(String emoji, {required bool animate}) {
    _controllers[emoji]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controllers[emoji] = ctrl;
    if (animate) {
      ctrl.forward();
    } else {
      ctrl.value = 1.0;
    }
  }

  void _animateOut(String emoji) {
    final ctrl = _controllers[emoji];
    if (ctrl == null) {
      if (mounted) setState(() => _displayed.remove(emoji));
      return;
    }
    ctrl.duration = const Duration(milliseconds: 200);
    ctrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _displayed.remove(emoji);
          _controllers.remove(emoji)?.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayed.isEmpty) return const SizedBox.shrink();

    // Prefer per-chip taps; fall back to the whole-badge tap only when no
    // per-emoji handler is wired.
    final perChip = widget.onEmojiTap != null;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _displayed.entries.take(3)) ...[
            perChip
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onEmojiTap!(entry.key),
                    child: _buildAnimatedEmoji(entry.key, entry.value),
                  )
                : _buildAnimatedEmoji(entry.key, entry.value),
            const SizedBox(width: 3),
          ],
        ],
      ),
    );

    if (perChip) return badge;

    return GestureDetector(onTap: widget.onTap, child: badge);
  }

  Widget _buildAnimatedEmoji(String emoji, int count) {
    final ctrl = _controllers[emoji];
    final chip = _EmojiChip(emoji: emoji, count: count);
    if (ctrl == null) return chip;

    // Add animation: spring 0.6 → 1.15 → 1.0 + fade-in.
    // Remove animation (ctrl reversed): same tween runs backward → shrink + fade.
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(ctrl);

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) => Opacity(
        opacity: ctrl.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: scaleAnim.value, child: child),
      ),
      child: chip,
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(
            fontSize: 14,
            decoration: TextDecoration.none,
            height: 1.2,
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A5568),
              decoration: TextDecoration.none,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
