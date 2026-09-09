import 'dart:async';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/link_preview_card.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/rich_text_toolbar.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// WhatsApp-style composable chat input bar.
///
/// Features:
///   • Emoji picker toggle (left of field)
///   • Multi-line text field with attachment icon inside
///   • Animated send / mic button (mic when empty, send when text present)
///   • Quoted-message preview strip
///   • Horizontal pending-attachment thumbnails
///   • Fully keyboard-aware (no explicit viewInsets handling needed — wrap in
///     a [Scaffold] with [resizeToAvoidBottomInset: true])
///
/// Usage:
/// ```dart
/// ChatInputBar(
///   controller: _controller,
///   isSending: state.isSending,
///   onSend: _sendMessage,
///   onAttachmentTap: _showAttachmentSheet,
/// )
/// ```
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    this.isSending = false,
    this.pendingAttachments = const [],
    this.quotedMessage,
    this.onCancelQuote,
    this.onRemoveAttachment,
    this.hintText = 'Type your message here…',
    this.maxLength = 2000,
    this.showCharCounter = false,
    this.focusNode,
    this.editingMessage,
    this.onCancelEdit,

    /// When true a formatting toolbar (B/I/U/S/Bullet/Numbered) is shown
    /// above the keyboard whenever the text field has focus.
    this.showRichTextToolbar = true,

    /// When false, the text field/attachment/emoji controls are replaced by
    /// [disabledMessage] and the Send button is permanently disabled — e.g.
    /// no active parent/guardian left in the conversation to send to.
    this.enabled = true,
    this.disabledMessage,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final bool isSending;
  final List<ChatAttachment> pendingAttachments;
  final Message? quotedMessage;
  final VoidCallback? onCancelQuote;
  final void Function(int index)? onRemoveAttachment;
  final String hintText;
  final int maxLength;
  final bool showCharCounter;
  final FocusNode? focusNode;
  final Message? editingMessage;
  final VoidCallback? onCancelEdit;
  final bool showRichTextToolbar;
  final bool enabled;
  final String? disabledMessage;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  // UI micro-state (Mandate 2): ValueNotifiers rather than `setState` so each
  // dynamic region of the composer rebuilds independently — `_hasText` changes
  // on every keystroke, so a whole-widget rebuild there is exactly the cost
  // this rule targets.
  final ValueNotifier<bool> _emojiPickerVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFocus = ValueNotifier<bool>(false);

  /// Detected link/email/phone preview for the draft, plus whether the user
  /// dismissed it. One notifier so the preview strip is the only thing that
  /// rebuilds when either changes.
  final ValueNotifier<({PreviewMatch? preview, bool dismissed})> _linkPreview =
      ValueNotifier<({PreviewMatch? preview, bool dismissed})>((
        preview: null,
        dismissed: false,
      ));
  Timer? _urlDetectDebounce;

  late final FocusNode _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _effectiveFocusNode.removeListener(_onFocusChanged);
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _urlDetectDebounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _effectiveFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode.dispose();
    _emojiPickerVisible.dispose();
    _hasText.dispose();
    _hasFocus.dispose();
    _linkPreview.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    // Raw text alone isn't enough — a formatting tag pair with nothing
    // typed inside it (e.g. `<b></b>` left over from toggling Bold on then
    // off without typing) is non-empty text but has no actual visible
    // content, and must not enable Send.
    // Assigning an unchanged value is a no-op — the notifier only fires on a
    // real change, so no manual diff is needed.
    _hasText.value = MessageContentProcessor.stripHtmlTags(
      widget.controller.text,
    ).trim().isNotEmpty;

    // Debounce preview detection to avoid spamming on every keystroke.
    _urlDetectDebounce?.cancel();
    _urlDetectDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final preview = MessageContentProcessor.detectFirstPreview(
        widget.controller.text,
      );
      final current = _linkPreview.value.preview;
      final samePreview =
          preview?.kind == current?.kind && preview?.value == current?.value;
      if (!samePreview) {
        _linkPreview.value = (
          preview: preview,
          // Reset dismiss flag whenever the preview changes.
          dismissed: preview != null ? false : _linkPreview.value.dismissed,
        );
      }
    });
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final focused = _effectiveFocusNode.hasFocus;
    if (focused == _hasFocus.value) return;
    _hasFocus.value = focused;
    // The text field regaining focus brings up the system keyboard — without
    // this, the custom emoji grid could stay open underneath it, both
    // reserving bottom space at once (visible as a layout jump / "keyboard
    // reopening" on top of the already-open panel).
    if (focused && _emojiPickerVisible.value) _emojiPickerVisible.value = false;
  }

  void _toggleEmojiPicker() {
    if (_emojiPickerVisible.value) {
      FocusScope.of(context).requestFocus(FocusNode());
    } else {
      FocusScope.of(context).unfocus();
    }
    _emojiPickerVisible.value = !_emojiPickerVisible.value;
  }

  void _onEmojiSelected(Category? _, Emoji emoji) {
    final pos = widget.controller.selection.isValid
        ? widget.controller.selection.baseOffset
        : widget.controller.text.length;
    final text = widget.controller.text;
    widget.controller.value = widget.controller.value.copyWith(
      text: text.substring(0, pos) + emoji.emoji + text.substring(pos),
      selection: TextSelection.collapsed(offset: pos + emoji.emoji.length),
    );
  }

  void _handleSend() {
    if (widget.isSending) return;
    widget.onSend();
    if (_emojiPickerVisible.value) {
      _emojiPickerVisible.value = false;
    }
    // Restore focus so the keyboard stays open between sends.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _effectiveFocusNode.requestFocus();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuotePreview(
            message: widget.quotedMessage,
            onCancel: widget.onCancelQuote,
          ),
          _EditPreview(
            message: widget.editingMessage,
            onCancel: widget.onCancelEdit,
          ),
          _AttachmentPreviewStrip(
            attachments: widget.pendingAttachments,
            onRemove: widget.onRemoveAttachment,
          ),
          // Composer preview strip — shown when a URL/email/phone is
          // detected in the draft and the user has not dismissed it.
          ValueListenableBuilder<({PreviewMatch? preview, bool dismissed})>(
            valueListenable: _linkPreview,
            builder: (context, lp, _) => (lp.preview != null && !lp.dismissed)
                ? ComposerLinkPreview(
                    preview: lp.preview!,
                    onDismiss: () => _linkPreview.value = (
                      preview: _linkPreview.value.preview,
                      dismissed: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          widget.enabled
              ? ListenableBuilder(
                  listenable: Listenable.merge([_hasText, _emojiPickerVisible]),
                  builder: (context, _) => _InputRow(
                    key: const ValueKey('chat_input_row'),
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    hintText: widget.hintText,
                    maxLength: widget.maxLength,
                    showCharCounter: widget.showCharCounter,
                    isSending: widget.isSending,
                    // An attachment-only message is valid too — the send
                    // button must not stay disabled just because the text
                    // field is empty.
                    hasText:
                        _hasText.value || widget.pendingAttachments.isNotEmpty,
                    emojiVisible: _emojiPickerVisible.value,
                    onEmojiToggle: _toggleEmojiPicker,
                    onAttachmentTap: widget.onAttachmentTap,
                    onSend: _handleSend,
                  ),
                )
              : _DisabledInputRow(
                  key: const ValueKey('chat_input_row_disabled'),
                  message:
                      widget.disabledMessage ??
                      'You can no longer send messages in this conversation.',
                ),

          // Rich-text formatting toolbar — visible when field is focused or
          // text already contains formatted content (indicated by _hasText).
          if (widget.enabled && widget.showRichTextToolbar)
            ListenableBuilder(
              listenable: Listenable.merge([_hasFocus, _hasText]),
              builder: (context, _) => (_hasFocus.value || _hasText.value)
                  ? RichTextToolbar(controller: widget.controller)
                  : const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),

          ValueListenableBuilder<bool>(
            valueListenable: _emojiPickerVisible,
            builder: (context, visible, _) => visible
                ? SizedBox(
                    height: (MediaQuery.sizeOf(context).height * 0.35).clamp(
                      160.0,
                      280.0,
                    ),
                    child: EmojiPicker(
                      onEmojiSelected: _onEmojiSelected,
                      config: Config(
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          backgroundColor: AppColors.messagingDialogBackground,
                          emojiSizeMax: 28,
                        ),
                        categoryViewConfig: const CategoryViewConfig(
                          backgroundColor: AppColors.cardColor,
                          indicatorColor: AppColors.primaryColor,
                          iconColorSelected: AppColors.primaryColor,
                          recentTabBehavior: RecentTabBehavior.RECENT,
                        ),
                        bottomActionBarConfig: const BottomActionBarConfig(
                          enabled: false,
                        ),
                        searchViewConfig: const SearchViewConfig(
                          backgroundColor: AppColors.cardColor,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Quote preview ──────────────────────────────────────────────────────────────

class _QuotePreview extends StatelessWidget {
  const _QuotePreview({this.message, this.onCancel});

  final Message? message;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (message!.senderName?.isNotEmpty ?? false)
                        ? message!.senderName!
                        : AppStrings.you,
                    style: AppTextStyles.size14.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CustomTextWidget(
                    text: MessageContentProcessor.previewText(message!.text),
                    fontSize: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontColor: AppColors.messagingPreviewBody,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.messagingDismissIcon,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _EditPreview extends StatelessWidget {
  const _EditPreview({this.message, this.onCancel});

  final Message? message;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.messagingEditAccent, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: AppSizes.xxs),
                      Text(
                        AppStrings.editingMessage,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  CustomTextWidget(
                    text: MessageContentProcessor.previewText(message!.text),
                    fontSize: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontColor: AppColors.messagingPreviewBody,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.messagingDismissIcon,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// ── Attachment thumbnails ──────────────────────────────────────────────────────

class _AttachmentPreviewStrip extends StatelessWidget {
  const _AttachmentPreviewStrip({required this.attachments, this.onRemove});

  final List<ChatAttachment> attachments;
  final void Function(int)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      // Extra top padding gives the tiles breathing room from the field above and
      // leaves headroom for the remove badge (which sits at top:-4) so it isn't clipped.
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.sm, AppSizes.sm, 6),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (context, i) {
          final att = attachments[i];
          final isVideo =
              att.type == 'video' || att.mimeType.startsWith('video/');
          final canPreview =
              (att.isImage || isVideo) && (att.localPath?.isNotEmpty ?? false);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Tapping an image/video tile opens a full-screen in-app preview.
              GestureDetector(
                onTap: canPreview
                    ? () => context.push(
                        CommunicationRoutes.mediaViewer,
                        extra: MediaViewerArgs(
                          imageFile: att.isImage ? File(att.localPath!) : null,
                          videoFile: isVideo ? File(att.localPath!) : null,
                          title: att.name,
                        ),
                      )
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      // A pending composer attachment normally carries a local
                      // file path; guard against a null path (e.g. a
                      // remote-only/not-yet-materialized entry) so the preview
                      // strip renders a neutral placeholder instead of throwing
                      // a null-check error at build.
                      child: att.localPath == null
                          ? Container(
                              width: 76,
                              height: 76,
                              color: AppColors.messagingDividerLight,
                              child: Icon(
                                att.isImage
                                    ? Icons.image_outlined
                                    : Icons.insert_drive_file_outlined,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : att.isImage
                          ? Image.file(
                              File(att.localPath!),
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            )
                          : Thumbnail(
                              mimeType: att.mimeType,
                              dataResolver: () =>
                                  File(att.localPath!).readAsBytes(),
                              widgetSize: 76,
                              decoration: WidgetDecoration(
                                backgroundColor: AppColors.cardColor,
                                iconColor: AppColors.primaryColor,
                                textColor: AppColors.primaryColor,
                                wrapperBgColor: AppColors.transparentColor,
                                wrapperSize: 80,
                              ),
                            ),
                    ),
                    // Play affordance so a video tile reads as tappable/previewable.
                    if (isVideo)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.messagingScrimDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.messagingOnAccent,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              if (!att.isImage)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.messagingScrimDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      att.name.length > 12
                          ? '${att.name.substring(0, 10)}…'
                          : att.name,
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingOnAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => onRemove?.call(i),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.messagingRemoveBadge,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.messagingOnAccent, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.messagingOnAccent,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Input row ──────────────────────────────────────────────────────────────────

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _CutIntent extends Intent {
  const _CutIntent();
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

/// Replaces the text field + Send button when [ChatInputBar.enabled] is
/// false — e.g. no active parent/guardian left in the conversation. Shows
/// [message] where the text field pill normally sits, with a permanently
/// disabled Send button beside it (no emoji/attachment controls — nothing
/// left to act on).
class _DisabledInputRow extends StatelessWidget {
  const _DisabledInputRow({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                message,
                style: AppTextStyles.size14.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.send_rounded,
              color: AppColors.primaryColor.withValues(alpha: 0.35),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.maxLength,
    required this.showCharCounter,
    required this.isSending,
    required this.hasText,
    required this.emojiVisible,
    required this.onEmojiToggle,
    required this.onAttachmentTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final int maxLength;
  final bool showCharCounter;
  final bool isSending;
  final bool hasText;
  final bool emojiVisible;
  final VoidCallback onEmojiToggle;
  final VoidCallback onAttachmentTap;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final useHtmlAwareClipboard = controller is HtmlAwareTextController;
    final textField = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 130),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        contextMenuBuilder: controller is HtmlAwareTextController
            ? (context, editableTextState) =>
                  HtmlAwareTextSelectionControls.buildContextMenu(
                    context,
                    editableTextState,
                    controller as HtmlAwareTextController,
                  )
            : null,
        onSubmitted: (_) {},
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 1,
        maxLines: null,
        maxLength: maxLength,
        // The default counter counts `controller.text` raw, which includes
        // the invisible `<b>`/`<i>`/`<u>`/`<s>` formatting markup the rich
        // text toolbar inserts — so bolding a 4-character word showed
        // "11/2000" instead of "4/2000". Count the stripped/visible text
        // the user actually sees instead.
        buildCounter:
            (
              context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              if (!showCharCounter) return null;
              final visibleLength = MessageContentProcessor.stripHtmlTags(
                controller.text,
              ).length;
              return Text(
                maxLength != null
                    ? '$visibleLength/$maxLength'
                    : '$visibleLength',
                style: AppTextStyles.size14.copyWith(
                  fontSize: 12,
                  color: AppColors.messagingTextPlaceholder,
                ),
              );
            },
        textCapitalization: TextCapitalization.sentences,
        style: AppTextStyles.size16.copyWith(
          fontSize: 15,
          color: AppColors.messagingTextStrong,
        ),
        onChanged: (value) {
          if (controller is HtmlAwareTextController) {
            final textController = controller as HtmlAwareTextController;
            if (textController.text != value) {
              textController.value = TextEditingValue(
                text: value,
                selection: textController.selection,
              );
            }
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.size16.copyWith(
            color: AppColors.messagingTextPlaceholder,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );

    final fieldWithShortcuts = useHtmlAwareClipboard
        ? Shortcuts(
            shortcuts: <ShortcutActivator, Intent>{
              const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                  const _CopyIntent(),
              const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                  const _CopyIntent(),
              const SingleActivator(LogicalKeyboardKey.keyX, control: true):
                  const _CutIntent(),
              const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
                  const _CutIntent(),
              const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                  const _PasteIntent(),
              const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                  const _PasteIntent(),
              const SingleActivator(LogicalKeyboardKey.keyA, control: true):
                  const _SelectAllIntent(),
              const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
                  const _SelectAllIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                _CopyIntent: CallbackAction<_CopyIntent>(
                  onInvoke: (_) async {
                    if (controller is HtmlAwareTextController) {
                      await (controller as HtmlAwareTextController)
                          .copySelectionToClipboard();
                    }
                    return null;
                  },
                ),
                _CutIntent: CallbackAction<_CutIntent>(
                  onInvoke: (_) async {
                    if (controller is HtmlAwareTextController) {
                      await (controller as HtmlAwareTextController)
                          .cutSelectionToClipboard();
                    }
                    return null;
                  },
                ),
                _PasteIntent: CallbackAction<_PasteIntent>(
                  onInvoke: (_) async {
                    if (controller is HtmlAwareTextController) {
                      await (controller as HtmlAwareTextController)
                          .pasteFromClipboard();
                    }
                    return null;
                  },
                ),
                _SelectAllIntent: CallbackAction<_SelectAllIntent>(
                  onInvoke: (_) {
                    if (controller is HtmlAwareTextController) {
                      (controller as HtmlAwareTextController).selectAllText();
                    }
                    return null;
                  },
                ),
              },
              child: textField,
            ),
          )
        : textField;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Emoji toggle ───────────────────────────────────────────
          Tooltip(
            message: 'Quick Reactions',
            child: _CircleActionButton(
              onTap: onEmojiToggle,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  emojiVisible
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
                  key: ValueKey(emojiVisible),
                  color: AppColors.primaryColor,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.xs),

          // ── Text field pill ────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.messagingInputBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    // ConstrainedBox caps the field at ~5 lines (~130 px).
                    // Beyond that the TextField scrolls internally — the
                    // composer never pushes the message list off-screen.
                    child: fieldWithShortcuts,
                  ),

                  // Attachment icon inside pill — stays pinned to the bottom
                  // of the pill regardless of how tall the text field grows.
                  Tooltip(
                    message: 'Add Attachment',
                    child: GestureDetector(
                      onTap: onAttachmentTap,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, AppSizes.xsPlus, AppSizes.xsPlus),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.attach_file_rounded,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.xs),

          // ── Send button (always visible, disabled when empty) ─────
          Tooltip(
            message: 'Send',
            child: GestureDetector(
              onTap: hasText && !isSending ? onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: hasText ? AppColors.buildPrimaryGradient() : null,
                  color: hasText
                      ? null
                      : AppColors.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: hasText
                      ? [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.30,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: PrimaryCircularLoader(
                          size: 22,
                          strokeWidth: 2,
                          color: AppColors.messagingOnAccent,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: hasText
                            ? AppColors.messagingOnAccent
                            : AppColors.primaryColor.withValues(alpha: 0.35),
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}
