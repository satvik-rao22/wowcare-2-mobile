import 'dart:async';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/link_preview_card.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/rich_text_toolbar.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
    this.hintText = 'Type a message…',
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
  bool _emojiPickerVisible = false;
  bool _hasText = false;
  bool _hasFocus = false;

  // Link preview state
  PreviewMatch? _detectedPreview;
  bool _linkPreviewDismissed = false;
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
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    // Raw text alone isn't enough — a formatting tag pair with nothing
    // typed inside it (e.g. `<b></b>` left over from toggling Bold on then
    // off without typing) is non-empty text but has no actual visible
    // content, and must not enable Send.
    final hasText = MessageContentProcessor.stripHtmlTags(
      widget.controller.text,
    ).trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);

    // Debounce preview detection to avoid spamming on every keystroke.
    _urlDetectDebounce?.cancel();
    _urlDetectDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final preview = MessageContentProcessor.detectFirstPreview(
        widget.controller.text,
      );
      final samePreview =
          preview?.kind == _detectedPreview?.kind &&
          preview?.value == _detectedPreview?.value;
      if (!samePreview) {
        setState(() {
          _detectedPreview = preview;
          // Reset dismiss flag whenever the preview changes.
          if (preview != null) _linkPreviewDismissed = false;
        });
      }
    });
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final focused = _effectiveFocusNode.hasFocus;
    if (focused == _hasFocus) return;
    setState(() {
      _hasFocus = focused;
      // The text field regaining focus brings up the system keyboard —
      // without this, the custom emoji grid could stay open underneath it,
      // both reserving bottom space at once (visible as a layout jump /
      // "keyboard reopening" on top of the already-open panel).
      if (focused && _emojiPickerVisible) _emojiPickerVisible = false;
    });
  }

  void _toggleEmojiPicker() {
    if (_emojiPickerVisible) {
      FocusScope.of(context).requestFocus(FocusNode());
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() => _emojiPickerVisible = !_emojiPickerVisible);
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
    if (_emojiPickerVisible) {
      setState(() => _emojiPickerVisible = false);
    }
    // Restore focus so the keyboard stays open between sends.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _effectiveFocusNode.requestFocus();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // final screenSize = MediaQuery.of(context).size;
    // final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    // final safeAreaInset = MediaQuery.of(context).padding.bottom;

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
          if (_detectedPreview != null && !_linkPreviewDismissed)
            ComposerLinkPreview(
              preview: _detectedPreview!,
              onDismiss: () => setState(() => _linkPreviewDismissed = true),
            )
          else
            const SizedBox.shrink(),

          widget.enabled
              ? _InputRow(
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
                  hasText: _hasText || widget.pendingAttachments.isNotEmpty,
                  emojiVisible: _emojiPickerVisible,
                  onEmojiToggle: _toggleEmojiPicker,
                  onAttachmentTap: widget.onAttachmentTap,
                  onSend: _handleSend,
                )
              : _DisabledInputRow(
                  key: const ValueKey('chat_input_row_disabled'),
                  message:
                      widget.disabledMessage ??
                      'You can no longer send messages in this conversation.',
                ),

          // Rich-text formatting toolbar — visible when field is focused or
          // text already contains formatted content (indicated by _hasText).
          if (widget.enabled &&
              widget.showRichTextToolbar &&
              (_hasFocus || _hasText))
            RichTextToolbar(controller: widget.controller)
          else
            const SizedBox.shrink(),

          if (_emojiPickerVisible)
            SizedBox(
              height: (MediaQuery.of(context).size.height * 0.35).clamp(
                160.0,
                280.0,
              ),
              child: EmojiPicker(
                onEmojiSelected: _onEmojiSelected,
                config: Config(
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: const Color(0xFFF4F6FB),
                    emojiSizeMax: 28,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    backgroundColor: Colors.white,
                    indicatorColor: AppColors.primaryColor,
                    iconColorSelected: AppColors.primaryColor,
                    recentTabBehavior: RecentTabBehavior.RECENT,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    enabled: false,
                  ),
                  searchViewConfig: const SearchViewConfig(
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (message!.senderName?.isNotEmpty ?? false)
                        ? message!.senderName!
                        : 'You',
                    style: TextStyle(
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
                    fontColor: const Color(0xFF4A5568),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF94A3B8),
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Colors.amber.shade600, width: 3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Editing Message',
                        style: TextStyle(
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
                    fontColor: const Color(0xFF4A5568),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF94A3B8),
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFullScreenMediaView(
                            imageFile: att.isImage
                                ? File(att.localPath!)
                                : null,
                            videoFile: isVideo ? File(att.localPath!) : null,
                            title: att.name,
                          ),
                        ),
                      )
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: att.isImage
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
                                backgroundColor: Colors.white,
                                iconColor: AppColors.primaryColor,
                                textColor: AppColors.primaryColor,
                                wrapperBgColor: Colors.transparent,
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
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
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
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      att.name.length > 12
                          ? '${att.name.substring(0, 10)}…'
                          : att.name,
                      style: const TextStyle(
                        color: Colors.white,
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
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                message,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                style: AppTextStyles.bodySmall.copyWith(
                  color: Color(0xFFB2BEC3),
                ),
              );
            },
        textCapitalization: TextCapitalization.sentences,
        style: AppTextStyles.body.copyWith(color: Color(0xFF1E293B)),
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
          hintStyle: AppTextStyles.body.copyWith(color: Color(0xFFB2BEC3)),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
          const SizedBox(width: 8),

          // ── Text field pill ────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
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
          const SizedBox(width: 8),

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
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: hasText
                            ? Colors.white
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
