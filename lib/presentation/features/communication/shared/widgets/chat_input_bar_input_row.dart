part of 'chat_input_bar.dart';

// The composer input rows and circular action button (Mandate 6 split from chat_input_bar.dart). A `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

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
              decoration: AppSurfaces.field(radius: 26),
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
                decoration: AppSurfaces.fab(enabled: hasText),
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
