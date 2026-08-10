import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// WhatsApp-style rich text formatting toolbar.
///
/// Wraps the current selection in the given HTML tags, or (when no text is
/// selected) inserts the tags with the cursor placed between them so the user
/// can start typing formatted content immediately.
///
/// Bullet list: prepends "• " to the current line.
/// Numbered list: prepends "1. " to the current line.
///
/// The controller is expected to own a [TextEditingController] already
/// attached to the active [TextField]. This widget does NOT manage focus.
class RichTextToolbar extends StatefulWidget {
  const RichTextToolbar({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<RichTextToolbar> createState() => _RichTextToolbarState();
}

class _RichTextToolbarState extends State<RichTextToolbar> {
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateFormatState);
    _updateFormatState();
  }

  @override
  void didUpdateWidget(RichTextToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateFormatState);
      widget.controller.addListener(_updateFormatState);
      _updateFormatState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateFormatState);
    super.dispose();
  }

  void _updateFormatState() {
    if (!mounted) return;
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final cursor = sel.baseOffset;
    
    bool isInside(String openTag, String closeTag) {
      if (cursor <= 0 || cursor > text.length) return false;
      int lastOpen = text.lastIndexOf(openTag, cursor - 1);
      int lastClose = text.lastIndexOf(closeTag, cursor - 1);
      return lastOpen != -1 && lastOpen > lastClose;
    }

    final newBold = isInside('<b>', '</b>');
    final newItalic = isInside('<i>', '</i>');
    final newUnderline = isInside('<u>', '</u>');
    final newStrike = isInside('<s>', '</s>');

    if (newBold != _isBold || newItalic != _isItalic || newUnderline != _isUnderline || newStrike != _isStrikethrough) {
      setState(() {
        _isBold = newBold;
        _isItalic = newItalic;
        _isUnderline = newUnderline;
        _isStrikethrough = newStrike;
      });
    }
  }

  // ── Tag wrapping ─────────────────────────────────────────────────────────

  void _wrapWith(String openTag, String closeTag) {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;
    final text = widget.controller.text;

    if (sel.isCollapsed) {
      // No selection: insert both tags and place cursor between them.
      final pos = sel.baseOffset;
      widget.controller.value = widget.controller.value.copyWith(
        text:
            text.substring(0, pos) + openTag + closeTag + text.substring(pos),
        selection: TextSelection.collapsed(offset: pos + openTag.length),
      );
    } else {
      // Selection: wrap the selected text.
      final start = sel.start;
      final end = sel.end;
      final selected = text.substring(start, end);
      widget.controller.value = widget.controller.value.copyWith(
        text: text.substring(0, start) +
            openTag +
            selected +
            closeTag +
            text.substring(end),
        selection: TextSelection.collapsed(
          offset: start + openTag.length + selected.length + closeTag.length,
        ),
      );
    }
  }

  // ── List prefixes ─────────────────────────────────────────────────────────

  void _prefixCurrentLine(String prefix) {
    final sel = widget.controller.selection;
    final text = widget.controller.text;
    final pos = sel.isValid ? sel.baseOffset : text.length;

    // Find the start of the current line.
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;

    // If the line already starts with this prefix, remove it (toggle).
    if (text.substring(lineStart).startsWith(prefix)) {
      final newText =
          text.substring(0, lineStart) + text.substring(lineStart + prefix.length);
      widget.controller.value = widget.controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: (pos - prefix.length).clamp(lineStart, newText.length),
        ),
      );
    } else {
      widget.controller.value = widget.controller.value.copyWith(
        text: text.substring(0, lineStart) + prefix + text.substring(lineStart),
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Slightly taller for larger touch targets
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _ToolbarBtn(
              icon: Icons.format_bold,
              label: 'Bold',
              isActive: _isBold,
              onTap: () => _wrapWith('<b>', '</b>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_italic,
              label: 'Italic',
              isActive: _isItalic,
              onTap: () => _wrapWith('<i>', '</i>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_underlined,
              label: 'Underline',
              isActive: _isUnderline,
              onTap: () => _wrapWith('<u>', '</u>'),
            ),
            _ToolbarBtn(
              icon: Icons.format_strikethrough,
              label: 'Strikethrough',
              isActive: _isStrikethrough,
              onTap: () => _wrapWith('<s>', '</s>'),
            ),
            const _Divider(),
            _ToolbarBtn(
              icon: Icons.format_list_bulleted,
              label: 'Bullet list',
              onTap: () => _prefixCurrentLine('• '),
            ),
            _ToolbarBtn(
              icon: Icons.format_list_numbered,
              label: 'Numbered list',
              onTap: () => _prefixCurrentLine('1. '),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTapDown: (_) => onTap(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Increased touch target
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.primaryColor : AppColors.primaryColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFE2E8F0),
    );
  }
}
