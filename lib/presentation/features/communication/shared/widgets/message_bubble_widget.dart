import 'dart:io';
import 'dart:ui' as ui;
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thumbnailer/thumbnailer.dart' show Thumbnailer;
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_open_helper.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_url_resolver.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/link_preview_card.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:wowcare/presentation/features/communication/shared/utils/messaging_time_formatter.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
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

  /// Long-press on the reaction badge — shows who reacted (grouped by
  /// emoji), mirroring [onInfo]'s "Message Info" dialog.
  final VoidCallback? onReactionsInfoTap;

  /// Retries a message that failed to send, or (when it sent fine but an
  /// attachment is still stuck on "Processing") re-polls for the resolved
  /// delivery URL. Shown only for [Message.isSentByMe] messages that are
  /// [Message.isFailed] or [Message.hasProcessingAttachments].
  final VoidCallback? onRetry;
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
  /// Admin Chat), it drives bubble *color* for messages that aren't mine,
  /// AND (together with [viewerIsOrgSide]) which SIDE the bubble renders on
  /// — see [_alignRight].
  final bool? senderIsOrgSide;

  /// Whether the CURRENT VIEWER (not the sender) is staff/admin/teacher/
  /// director (true) or guardian/parent (false). Null for Staff Direct
  /// (matches [senderIsOrgSide]'s nullability). Used to tell "a guardian's
  /// message, seen by the opposite role" (pink highlight) apart from "a
  /// guardian's message, seen by a fellow guardian" (plain white) — see the
  /// `isOppositeRoleGuardian` check in [_buildBubble] — and, together with
  /// [senderIsOrgSide], which side the bubble renders on (see
  /// [_alignRight]): a message from the viewer's own "team" (same org-side-
  /// ness as the viewer) renders right, the opposite team's renders left,
  /// regardless of whether the viewer personally sent it.
  final bool? viewerIsOrgSide;

  /// School's `communication-settings.adminCanDeleteAny` — when true AND the
  /// current viewer is an admin, the Delete menu item shows on every message
  /// (not just ones [currentUserCode] sent), bypassing [deleteTimeLimitMinutes].
  final bool isAdminCanDeleteAny;

  /// School's `communication-settings.deleteTimeLimitMinutes` — once this
  /// many minutes have passed since [Message.time], the sender's own Delete
  /// option is hidden (server enforces the same window; this just avoids
  /// showing an option that would fail). Null/non-positive means no limit.
  final int? deleteTimeLimitMinutes;

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
    this.onReactionsInfoTap,
    this.onRetry,
    this.isParentMessaging = false,
    this.isInactive = false,
    this.isDeleted = false,
    this.isGrouped = false,
    this.senderIsOrgSide,
    this.viewerIsOrgSide,
    this.isAdminCanDeleteAny = false,
    this.deleteTimeLimitMinutes,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  // ── Swipe-to-reply ────────────────────────────────────────────────────────
  // Swipe-to-reply horizontal offset. A ValueNotifier (not setState) so the
  // per-frame drag/snap-back updates rebuild ONLY the Transform/Opacity via
  // ValueListenableBuilder with a build-once `child:` — not the whole (~1100
  // line) bubble body (Mandate 2: the child: optimisation).
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
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
      // Mandate 2: the snap-back animation updates the drag-offset notifier;
      // only the Transform/Opacity (ValueListenableBuilder) rebuild, not the
      // whole bubble.
      if (mounted) {
        _dragOffset.value = _snapStartOffset * (1 - _snapController.value);
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
    _dragOffset.dispose();
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
    // Mandate 2: per-frame drag offset updates the notifier (see build) — no
    // whole-bubble rebuild.
    _dragOffset.value = (_dragOffset.value + details.delta.dx).clamp(
      0.0,
      _swipeThreshold + 15,
    );
    if (!_replyTriggered && _dragOffset.value >= _swipeThreshold) {
      _replyTriggered = true;
      HapticFeedback.mediumImpact();
      widget.onReply!();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _snapStartOffset = _dragOffset.value;
    _replyTriggered = false;
    _snapController.forward(from: 0);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// [Message.isSentByMe] is already the fully-informed answer by the time
  /// it reaches this widget: computed from raw code-matching upstream, AND
  /// (for screens where persona ambiguity is possible — see
  /// `ThreadMessageTile.isGuardian`/`withRoleAwareOwnership`) narrowed to
  /// `false` when [Message.senderRole] says this specific message was sent
  /// under a DIFFERENT persona of the same account. The raw
  /// `currentUserCode == senderUserCode` fallback below must therefore only
  /// fire when there's no [Message.senderRole] to have reasoned about at
  /// all — otherwise it silently re-derives "mine" from the account code
  /// alone and undoes that narrowing for a dual-role account's message sent
  /// under its other persona (exactly the bug this getter was fixing before
  /// senderRole existed: a message the client can verify is the current
  /// user's own account always rendering on their side, regardless of a
  /// separately-unreliable role signal — [senderIsOrgSide] here, which is
  /// still trusted for bubble *colour* on messages that aren't mine, per
  /// its own doc comment. `senderRole` is a different, per-message-accurate
  /// field from that older `senderIsOrgSide` problem).
  bool get _isMe {
    if (widget.message.isSentByMe) return true;
    final role = widget.message.senderRole;
    if (role != null && role.isNotEmpty) return false;
    return widget.currentUserCode != null &&
        widget.currentUserCode == widget.message.senderUserCode;
  }

  /// Which side this bubble renders on.
  ///
  /// Room Chat / Admin Chat (both [senderIsOrgSide] and [viewerIsOrgSide]
  /// known): role-based, per the messaging PRD's AC11/AC12 — the message's
  /// side depends on whether its SENDER is on the same "team" (guardian vs.
  /// org-side) as the CURRENT VIEWER, not on whether the viewer personally
  /// sent it. A guardian viewer sees every guardian's message (their own
  /// included) on the right and every org-side message on the left; an
  /// org-side viewer sees the mirror image. [_isMe] still gates identity-only
  /// affordances (Edit/Delete/Info menu items, the "You" label) — those stay
  /// tied to genuine authorship regardless of which side the bubble lands on.
  ///
  /// Staff Direct (both null): falls back to identity-based ([_isMe]) — this
  /// 1:1 surface intentionally keeps the plain "my message vs. their
  /// message" two-tone look instead of a team split.
  bool get _alignRight {
    final sender = widget.senderIsOrgSide;
    final viewer = widget.viewerIsOrgSide;
    if (sender != null && viewer != null) return sender == viewer;
    return _isMe;
  }

  /// `communication-settings`-driven Delete visibility: an admin persona
  /// with [MessageBubble.isAdminCanDeleteAny] set can delete ANY message,
  /// bypassing the time limit entirely. Otherwise only the sender can
  /// delete their own message, and only within
  /// [MessageBubble.deleteTimeLimitMinutes] of when it was sent (no limit
  /// configured means the sender can always delete their own message, same
  /// as before this setting existed).
  bool _canDelete(bool isMe) {
    if (widget.isAdminCanDeleteAny) return true;
    if (!isMe) return false;
    final limit = widget.deleteTimeLimitMinutes;
    if (limit == null || limit <= 0) return true;
    return DateTime.now().difference(widget.message.time).inMinutes < limit;
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
        menuItems: [
          const MenuItem(label: AppStrings.menuReply, icon: Icons.reply_rounded),
          const MenuItem(label: AppStrings.menuCopy, icon: Icons.copy_outlined),
          // Delivered/read info only makes sense for a message THIS user
          // sent — never shown on a received (left-side) bubble.
          if (isMe) const MenuItem(label: AppStrings.menuInfo, icon: Icons.info_outline),
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
        if (isMe) const MenuItem(label: AppStrings.menuEdit, icon: Icons.edit_outlined),
        if (_canDelete(isMe))
          const MenuItem(
            label: AppStrings.menuDelete,
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        const MenuItem(label: AppStrings.menuReply, icon: Icons.reply_rounded),
        const MenuItem(label: AppStrings.menuCopy, icon: Icons.copy_outlined),
        // Delivered/read info only makes sense for a message THIS user sent
        // — never shown on a received (left-side) bubble.
        if (isMe) const MenuItem(label: AppStrings.menuInfo, icon: Icons.info_outline),
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
      case AppStrings.menuReply:
        widget.onReplyFromMenu?.call();
        break;
      case AppStrings.menuCopy:
        widget.onCopy?.call();
        break;
      case AppStrings.menuEdit:
        widget.onEdit?.call();
        break;
      case AppStrings.menuDelete:
        _showDeleteBottomSheet();
        break;
      case AppStrings.menuInfo:
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

  /// Long-pressing the reaction badge removes YOUR reaction (toggle off). If
  /// you haven't reacted, opens the reaction line (see [onReactionTap]).
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
      message: AppStrings.privateMessageToast,
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
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xl, horizontal: AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.deleteMessageTitle,
                style: AppTextStyles.heading18.copyWith(
                  color: AppColors.messagingHeadingPlum,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.deleteMessageConfirm,
                style: AppTextStyles.size14.copyWith(
                  color: AppColors.messagingHeadingPlum.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.messagingConfirmGradientStart,
                        AppColors.messagingConfirmGradientEnd,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.delete,
                    style: AppTextStyles.size16.copyWith(
                      color: AppColors.messagingOnAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.messagingSurfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.cancel,
                    style: AppTextStyles.size16.copyWith(
                      color: AppColors.messagingHeadingPlum,
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
                    child: ValueListenableBuilder<double>(
                      valueListenable: _dragOffset,
                      builder: (context, dragOffset, iconChild) => Opacity(
                        opacity: (dragOffset / _swipeThreshold).clamp(0.0, 1.0),
                        child: iconChild,
                      ),
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
                child: ValueListenableBuilder<double>(
                  valueListenable: _dragOffset,
                  builder: (context, dragOffset, bubbleChild) =>
                      Transform.translate(
                        offset: Offset(dragOffset, 0),
                        child: bubbleChild,
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: alignRight
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Sender header row (avatar + name). Grouping (consecutive
                      // messages from the same sender within a few minutes) only
                      // hides this for the VIEWER'S OWN messages — a repeated "You"
                      // label is redundant. A received (left-side) message always
                      // shows its sender's name, grouped or not: in a group chat
                      // with many participants, the whole point of the identity-
                      // based alignment fix is that different senders share the
                      // left side, so suppressing the name there would make it
                      // impossible to tell who sent what.
                      // Parent Messaging shows avatar + name side-by-side;
                      // Staff Direct shows name only (no avatar on the message).
                      if (!widget.isGrouped || !isMe)
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
                                      disableAttendanceStatusLookup: true,
                                      // Scoped to this specific message so a
                                      // list rebuild (pagination merge,
                                      // pull-to-refresh) can never let this
                                      // element get reused for a different
                                      // message's sender and momentarily
                                      // show/keep the wrong person's avatar.
                                      key: ValueKey(
                                        'msg-sender-avatar-${widget.message.code}',
                                      ),
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
                                style: AppTextStyles.size14.copyWith(
                                  color: AppColors.messagingHeadingPlum
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
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
                                // WhatsApp-style: a single tap shows who
                                // reacted; a long-press opens the reaction
                                // line to add/change/remove your own.
                                onTap: widget.onReactionsInfoTap,
                                onLongPress: _handleExistingReactionTap,
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
    // current sender gradient (light text). Staff Direct (orgSide null)
    // keeps the legacy look: gradient (light text) only for the viewer's
    // own messages, flat light background (dark text) for the other
    // party's.
    //
    // AC11/AC12: pink is a highlight reserved for a guardian's message when
    // read by the OPPOSITE role (staff/admin) — never for a fellow parent
    // reading another parent's message (that's a same-role peer, plain
    // white, per AC12's "other parent's messages ... white background").
    final viewerOrg = widget.viewerIsOrgSide;
    final isOppositeRoleGuardian =
        orgSide == false && (viewerOrg == null || viewerOrg == true);
    final useLightText = orgSide == null
        ? isMe
        : (isMe || isOppositeRoleGuardian);

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
      bubbleColor = isMe ? null : AppColors.messagingBubbleIncomingLegacy;
      bubbleGradient = isMe ? AppColors.buildPrimaryGradient() : null;
    } else if (isMe) {
      bubbleGradient = AppColors.buildPrimaryGradient();
    } else if (isOppositeRoleGuardian) {
      bubbleGradient = AppColors.buildPinkGradient();
    } else {
      bubbleColor = AppColors.messagingBubbleReceived;
    }

    return Material(
      color: AppColors.transparentColor,
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            gradient: bubbleGradient,
            borderRadius: _buildBubbleBorderRadius(alignRight),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: hasOnlyEmoji
                ? const EdgeInsets.symmetric(
                    horizontal: AppSizes.xs,
                    vertical: AppSizes.xxs,
                  )
                : const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
            child: isDeleted
                ? Text(
                    AppStrings.messageDeleted,
                    style: AppTextStyles.size14.copyWith(
                      color: useLightText
                          ? AppColors.messagingOnAccent.withValues(alpha: 0.75)
                          : AppColors.messagingHeadingPlum.withValues(
                              alpha: 0.6,
                            ),
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
                          const SizedBox(height: AppSizes.xs),
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
                              padding: const EdgeInsets.only(top: AppSizes.xs),
                              child: PreviewCard(
                                // Stable key so the preview (esp. the async
                                // AnyLinkPreview for URLs) is preserved across the
                                // frequent live-sync rebuilds instead of being torn
                                // down + rebuilt mid-frame. Key by the MESSAGE code
                                // (unique) — keying by preview.value would collide
                                // when two messages share the same link → duplicate
                                // key crash (whole-screen red).
                                key: ValueKey('preview_${widget.message.code}'),
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
                          AppStrings.edited,
                          style: AppTextStyles.size14.copyWith(
                            fontSize: 12,
                            color: useLightText
                                ? AppColors.messagingOnAccent.withValues(
                                    alpha: 0.7,
                                  )
                                : AppColors.messagingIconMuted,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],

                      // Time and delivery status at bottom of bubble
                      const SizedBox(height: AppSizes.xxs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: alignRight
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(widget.message.time),
                            style: AppTextStyles.size14.copyWith(
                              color: useLightText
                                  ? AppColors.messagingOnAccent.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppColors.messagingTextMeta,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (message.isPrivate &&
                              widget.senderIsOrgSide != null) ...[
                            const SizedBox(width: AppSizes.xxs),
                            GestureDetector(
                              onTap: _showPrivateMessageToast,
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 12,
                                color: useLightText
                                    ? AppColors.messagingOnAccent.withValues(
                                        alpha: 0.85,
                                      )
                                    : AppColors.messagingPrivateLock,
                              ),
                            ),
                          ],
                          // Read/delivery ticks are identity-only — only the
                          // literal sender (isMe) sees their own message's
                          // delivery status, regardless of which side it
                          // renders on.
                          if (isMe && widget.message.isFailed) ...[
                            const SizedBox(width: 6),
                            _RetryAffordance(
                              label: AppStrings.failedRetry,
                              icon: Icons.error_outline,
                              color: AppColors.messagingFailed,
                              onTap: widget.onRetry,
                            ),
                          ] else if (isMe &&
                              widget.message.hasProcessingAttachments) ...[
                            const SizedBox(width: 6),
                            _RetryAffordance(
                              label: AppStrings.processingShort,
                              icon: Icons.sync,
                              color: useLightText
                                  ? AppColors.messagingOnAccent.withValues(
                                      alpha: 0.8,
                                    )
                                  : AppColors.messagingTextMeta,
                              onTap: widget.onRetry,
                            ),
                          ] else if (isMe && widget.message.isSending) ...[
                            const SizedBox(width: AppSizes.xxs),
                            // WhatsApp-style "queued/sending, not yet
                            // reached the server" clock — the local bubble
                            // (with its local attachment preview) is already
                            // visible while this shows; it just marks the
                            // message as not-yet-confirmed, same as the
                            // single/double tick marks confirmed states.
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: useLightText
                                  ? AppColors.messagingOnAccent.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppColors.messagingTextMeta,
                            ),
                          ] else if (isMe) ...[
                            const SizedBox(width: AppSizes.xxs),
                            Icon(
                              widget.message.isRead
                                  ? Icons.done_all
                                  : widget.message.isDelivered
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: widget.message.isRead
                                  ? AppColors.primaryColor
                                  : AppColors.messagingOnAccent.withValues(
                                      alpha: 0.7,
                                    ),
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
        style: AppTextStyles.size16.copyWith(
          fontSize: fontSize,
          height: 1.15,
          // Explicit colour + decoration prevent DefaultTextStyle leakage
          // from dialog or Overlay contexts (same issue _StableHtml solves).
          color: AppColors.blackColor,
          decoration: TextDecoration.none,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );

    return Material(
      color: AppColors.transparentColor,
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
                style: AppTextStyles.size14.copyWith(
                  color: AppColors.messagingTextMeta,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
              if (message.isPrivate && widget.senderIsOrgSide != null) ...[
                const SizedBox(width: AppSizes.xxs),
                GestureDetector(
                  onTap: _showPrivateMessageToast,
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: AppColors.messagingPrivateLock,
                  ),
                ),
              ],
              if (isMe && message.isSending) ...[
                const SizedBox(width: AppSizes.xxs),
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: AppColors.messagingIconMuted.withValues(alpha: 0.7),
                ),
              ] else if (isMe) ...[
                const SizedBox(width: AppSizes.xxs),
                Icon(
                  widget.message.isRead
                      ? Icons.done_all
                      : widget.message.isDelivered
                      ? Icons.done_all
                      : Icons.done,
                  size: 13,
                  color: widget.message.isRead
                      ? AppColors.primaryColor
                      : AppColors.messagingIconMuted.withValues(alpha: 0.6),
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
    final textColor = useLightText
        ? AppColors.messagingOnAccent
        : AppColors.primaryColor;

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
        style: AppTextStyles.messagingBubbleText.copyWith(color: textColor),
      );
    }

    return _StableHtml(
      // Stable key tied to the message identity so the flutter_html subtree (which
      // owns a GlobalKey anchorKey) is preserved across live-sync rebuilds rather
      // than recreated/reparented mid-frame — the source of the semantics assertions.
      key: ValueKey('html_${widget.message.code}'),
      data: MessageContentProcessor.enrich(rawText),
      linkColor: useLightText
          ? AppColors.messagingLinkOnAccent
          : AppColors.messagingLink,
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
        margin: const EdgeInsets.only(bottom: AppSizes.xsPlus),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.sm,
          AppSizes.xsPlus,
          AppSizes.sm,
          AppSizes.xsPlus,
        ),
        decoration: BoxDecoration(
          color: AppColors.messagingOnAccent.withValues(
            alpha: isMe ? 0.15 : 0.60,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe
                  ? AppColors.messagingOnAccent.withValues(alpha: 0.85)
                  : AppColors.primaryColor,
              width: 3,
            ),
          ),
        ),
        child: _StableHtml(
          data: quoted.text.length > 120
              ? '${quoted.text.substring(0, 120)}…'
              : quoted.text,
          linkColor: isMe
              ? AppColors.messagingLinkOnAccent
              : AppColors.messagingLink,
          style: {
            'body': html.Style(
              margin: html.Margins.zero,
              padding: html.HtmlPaddings.zero,
              fontSize: html.FontSize(13.5),
              fontFamily: 'Manrope',
              color: isMe
                  ? AppColors.messagingOnAccent.withValues(alpha: 0.92)
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

  /// Fetch a remote attachment image with a few retries + backoff. A just-arrived
  /// (live-synced) image can momentarily 403/404 on the CloudFront edge before it
  /// propagates, so a single GET would fail and stick as an empty/blank bubble
  /// until a manual refresh re-ran the resolver. Retrying lets the live bubble fill
  /// itself in without the user having to refresh.
  Future<Uint8List> _fetchImageBytesWithRetry(String url) async {
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      try {
        final r = await http.get(Uri.parse(url));
        // A 200 status isn't proof the body is actually a decodable image —
        // a still-propagating CDN edge, an auth/redirect landing page, or a
        // body cut short mid-transfer can all come back as 200 with
        // non-image bytes. Handing those to the Thumbnail widget threw
        // "Invalid image data" from MemoryImage's async decode (visible in
        // the console as an "IMAGE RESOURCE SERVICE" exception even though
        // the widget itself falls back to its errorBuilder). Verify the
        // bytes actually decode before accepting this attempt as a success
        // — anything that doesn't decode is treated like a network failure
        // and retried, same as a non-200 status.
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          try {
            final codec = await ui.instantiateImageCodec(r.bodyBytes);
            codec.dispose();
            return r.bodyBytes;
          } catch (_) {
            // Falls through to retry below.
          }
        }
      } catch (_) {}
      if (i < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 600 * (i + 1)));
      }
    }
    return Uint8List(0);
  }

  /// Reads and validates a LOCAL attachment file's bytes — the remote path
  /// (above) already guards against undecodable bytes, but the local-file
  /// path previously had no such guard at all (`File(src).readAsBytes()`
  /// with no existence check, no empty check, no decode check), so a
  /// truncated/corrupt/deleted local file threw uncaught or handed garbage
  /// bytes straight to the renderer.
  Future<Uint8List> _readLocalImageBytes(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return Uint8List(0);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return Uint8List(0);
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      return bytes;
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<Uint8List> _resolveBubbleImageBytes(String src) {
    final isRemote = src.startsWith('http://') || src.startsWith('https://');
    return isRemote
        ? _fetchImageBytesWithRetry(src)
        : _readLocalImageBytes(src);
  }

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
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: GestureDetector(
                onTap: () => AttachmentOpenHelper.open(context, att),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.messagingBorderColor),
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
                              color: AppColors.messagingDocumentIcon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
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
                            const SizedBox(height: AppSizes.xxs),
                            CustomTextWidget(
                              text:
                                  '${(att.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB • ${att.type.toUpperCase()}',
                              fontSize: 13,
                              fontColor: AppColors.messagingMetaStrong,
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
          if (images.isNotEmpty) const SizedBox(height: AppSizes.md),
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
                // Drive this off the MESSAGE's own send state, not the
                // attachment's code/attachmentId presence — those can lag
                // behind a message that's already fully confirmed (e.g. a
                // just-arrived realtime delta that hasn't filled in
                // attachmentId on this exact snapshot yet), which kept the
                // spinner showing over an image that was already loaded and
                // sent (checkmark visible) correctly.
                final stillUploading = widget.message.isSending;
                AppLogger.i(
                  '[ATTACHMENT RENDER] msg=${widget.message.code} '
                  'name=${att.name} localPath=${att.localPath} '
                  'remoteUrl=${att.remoteUrl} code=${att.code} '
                  'attachmentId=${att.attachmentId} hasSource=$hasSource '
                  'stillUploading=$stillUploading isLoading=$isLoading '
                  'isProcessing=$isProcessing resolvedUrl=$resolvedUrl',
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (hasSource) {
                          context.push(
                            CommunicationRoutes.mediaViewer,
                            extra: MediaViewerArgs(
                              imageUrl: att.remoteUrl.isNotEmpty
                                  ? att.remoteUrl
                                  : null,
                              imageFile: att.localPath != null
                                  ? File(att.localPath!)
                                  : null,
                              title: att.name,
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasSource
                            ? _BubbleImageThumbnail(
                                key: ValueKey(att.displaySource),
                                bytesResolver: () => _resolveBubbleImageBytes(
                                  att.displaySource!,
                                ),
                                size: singleImageWidth,
                                errorIconSize: 80,
                              )
                            : Container(
                                height: singleImageWidth * 0.6,
                                color: AppColors.messagingThumbPlaceholderBg,
                                child: Center(
                                  child: isLoading
                                      ? const PrimaryCircularLoader(
                                          size: 28,
                                          strokeWidth: 2.5,
                                        )
                                      : isProcessing
                                      ? const _AttachmentProcessingPlaceholder()
                                      : const Icon(
                                          Icons.broken_image,
                                          size: 80,
                                          color: AppColors.messagingIconMuted,
                                        ),
                                ),
                              ),
                      ),
                    ),
                    if (hasSource && stillUploading)
                      const Positioned.fill(
                        child: IgnorePointer(child: _UploadingOverlay()),
                      ),
                  ],
                );
              },
            )
          else
            // Wrap (not GridView) — a message bubble is wrapped in
            // IntrinsicWidth above to shrink-fit its content, and
            // IntrinsicWidth cannot measure through a RenderViewport, which
            // is what backs GridView/ListView even with shrinkWrap: true.
            // That combination is exactly what threw Flutter's "does not
            // support returning intrinsic dimensions" assertion (and the
            // semantics-layer crash cascading from it) on every message with
            // 2+ images. displayImages is capped at 4, so a Wrap of
            // fixed-size tiles gives the identical 2-column look without a
            // viewport ever entering the tree.
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: List.generate(displayImages.length, (index) {
                final rawAtt = displayImages[index];
                final isLast = index == displayImages.length - 1;
                final remaining = images.length - 4;

                return SizedBox(
                  width: multiImageWidth,
                  height: multiImageWidth,
                  child: AttachmentUrlResolver(
                    attachment: rawAtt,
                    builder: (context, resolvedUrl, isLoading, isProcessing) {
                      final att =
                          (resolvedUrl != null && resolvedUrl.isNotEmpty)
                          ? rawAtt.copyWith(remoteUrl: resolvedUrl)
                          : rawAtt;
                      final hasSource = att.displaySource != null;
                      // See the single-image branch's matching comment —
                      // driven off the message's own send state now, not
                      // the attachment's code/attachmentId presence.
                      final stillUploading = widget.message.isSending;
                      return GestureDetector(
                        onTap: () {
                          if (hasMoreImages && isLast) {
                            context.push(
                              CommunicationRoutes.attachmentGallery,
                              extra: AttachmentGalleryArgs(
                                attachments: attachments,
                              ),
                            );
                          } else if (hasSource) {
                            context.push(
                              CommunicationRoutes.mediaViewer,
                              extra: MediaViewerArgs(
                                imageUrl: att.remoteUrl.isNotEmpty
                                    ? att.remoteUrl
                                    : null,
                                imageFile: att.localPath != null
                                    ? File(att.localPath!)
                                    : null,
                                title: att.name,
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
                                  ? _BubbleImageThumbnail(
                                      key: ValueKey(att.displaySource),
                                      bytesResolver: () =>
                                          _resolveBubbleImageBytes(
                                            att.displaySource!,
                                          ),
                                      size: multiImageWidth,
                                      errorIconSize: 50,
                                    )
                                  : Container(
                                      color: AppColors.messagingThumbPlaceholderBg,
                                      child: Center(
                                        child: isLoading
                                            ? const PrimaryCircularLoader(
                                                size: 22,
                                                strokeWidth: 2,
                                              )
                                            : isProcessing
                                            ? const _AttachmentProcessingPlaceholder(
                                                compact: true,
                                              )
                                            : const Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: AppColors.messagingIconMuted,
                                              ),
                                      ),
                                    ),
                            ),
                            if (hasMoreImages && isLast)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.blackColor.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CustomTextWidget(
                                    text: '+$remaining',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontColor: AppColors.messagingOnAccent,
                                  ),
                                ),
                              )
                            else if (hasSource && stillUploading)
                              const _UploadingOverlay(compact: true),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
        ],
      ],
    );
  }

  // ── Time formatter ────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) => MessagingTimeFormatter.bubbleTime(dt);
}

/// Renders a chat-bubble image thumbnail directly (bypassing the
/// `thumbnailer` package's `Thumbnail` widget, which has no error handling
/// of its own): a resolver failure returned empty bytes as a "successful"
/// result, which `Thumbnail` then handed to an internal `Image.memory` with
/// no `errorBuilder`, throwing an uncaught "Invalid image data" exception
/// and leaving the tile blank. Explicitly guards on empty bytes before ever
/// calling [Image.memory], and gives that call its own `errorBuilder` too —
/// mirrors [FullAttachmentViewer]'s `_ResilientImage`. Uses the app's
/// standard [PrimaryCircularLoader] instead of `Thumbnail`'s raw
/// `CircularProgressIndicator` while [bytesResolver] is in flight.
class _BubbleImageThumbnail extends StatefulWidget {
  const _BubbleImageThumbnail({
    super.key,
    required this.bytesResolver,
    required this.size,
    required this.errorIconSize,
  });

  final Future<Uint8List> Function() bytesResolver;
  final double size;
  final double errorIconSize;

  @override
  State<_BubbleImageThumbnail> createState() => _BubbleImageThumbnailState();
}

class _BubbleImageThumbnailState extends State<_BubbleImageThumbnail> {
  late final Future<Uint8List> _bytesFuture = widget.bytesResolver();

  Widget _broken() => Container(
    color: AppColors.messagingThumbPlaceholderBg,
    child: Icon(Icons.image, size: widget.errorIconSize, color: AppColors.messagingIconMuted),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.cardColor,
            child: Center(
              child: PrimaryCircularLoader(
                size: widget.size < 60 ? 22 : 28,
                strokeWidth: widget.size < 60 ? 2 : 2.5,
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _broken();
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) => _broken(),
        );
      },
    );
  }
}

/// Shown instead of the broken-image icon when the backend has reported the
/// attachment's asset as still `PROCESSING` (no delivery URL yet) rather
/// than an outright failure — tells the user it's still on its way instead
/// of looking like a load error.
/// Semi-transparent scrim + spinner drawn over an already-visible local
/// image preview while the attachment hasn't finished uploading/registering
/// yet (no delivery URL). Distinct from [_AttachmentProcessingPlaceholder],
/// which replaces the whole tile when there's no local preview to show at
/// all (a cached/history message with only a still-processing remote asset)
/// — here the picked photo is already on screen, this just signals "still
/// going" on top of it, the way a chat app overlays an in-flight send.
class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: PrimaryCircularLoader(
          size: compact ? 20 : 26,
          strokeWidth: 2.5,
          color: AppColors.messagingOnAccent,
        ),
      ),
    );
  }
}

class _AttachmentProcessingPlaceholder extends StatelessWidget {
  const _AttachmentProcessingPlaceholder({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryCircularLoader(size: iconSize, strokeWidth: 2.5),
        SizedBox(height: compact ? 6 : 8),
        Text(
          AppStrings.processing,
          style: AppTextStyles.size14.copyWith(
            fontSize: compact ? 11 : 13,
            color: AppColors.messagingMetaStrong,
          ),
        ),
      ],
    );
  }
}

/// Small tappable status shown next to a sent message's timestamp instead of
/// the normal delivery tick — either "Failed · Retry" (the send itself
/// errored: attachment upload or the API call) or "Processing" (sent fine,
/// but an attachment is still waiting on the document service; tapping just
/// re-polls, it does not re-send). No-op decoration (not a real button) when
/// [onTap] is null, e.g. a cached/legacy message with no retry wired up.
class _RetryAffordance extends StatelessWidget {
  const _RetryAffordance({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.size14.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
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
    super.key,
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
              child: Text(
                '❤️',
                style: AppTextStyles.size16.copyWith(
                  fontSize: 50,
                  decoration: TextDecoration.none,
                ),
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
    this.onLongPress,
  });

  final Map<String, int> counts;

  /// Tap anywhere on the badge — shows who reacted (WhatsApp-style).
  final VoidCallback? onTap;

  /// Long-press anywhere on the badge — opens the reaction line to
  /// add/change/remove your own reaction.
  final VoidCallback? onLongPress;

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

  // Mandate 2 (Bucket C): every setState in this badge (here and in
  // [_animateOut]) is tied to the per-emoji spring-in / shrink-out
  // AnimationControllers — animation lifecycle, so setState is the right tool.
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

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _displayed.entries.take(3)) ...[
            _buildAnimatedEmoji(entry.key, entry.value),
            const SizedBox(width: 3),
          ],
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: badge,
    );
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
          style: AppTextStyles.size14.copyWith(
            decoration: TextDecoration.none,
            height: 1.2,
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyles.size14.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.messagingPreviewBody,
              decoration: TextDecoration.none,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
