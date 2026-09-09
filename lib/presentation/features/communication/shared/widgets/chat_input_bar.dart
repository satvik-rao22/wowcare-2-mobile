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
part 'chat_input_bar_previews.dart';
part 'chat_input_bar_input_row.dart';

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
