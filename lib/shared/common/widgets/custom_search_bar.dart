import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app-wide search field.
///
/// A recessed well in the skeuomorphic language — the same material as every
/// other input, so "type here" reads the same everywhere. Replaces Material's
/// [SearchBar], whose raised outlined shell is the opposite of what this design
/// wants. All existing parameters are honoured; [searchBarColor] and
/// [borderColor] no longer apply, because the well paints its own face and rim.
class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.searchBarColor,
    this.borderColor,
    this.trailing,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;

  /// Retained for call-site compatibility — the well's face is fixed.
  final WidgetStateProperty<Color>? searchBarColor;

  /// Retained for call-site compatibility — the well paints its own rim.
  final Color? borderColor;

  final List<Widget>? trailing;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted && _focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeuWell(
      height: 44,
      radius: SkeuRadius.field,
      focused: _focused,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: SkeuColors.inkFaint,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              cursorColor: SkeuColors.teal600,
              style: SkeuText.body(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hintText,
                hintStyle: SkeuText.body(color: SkeuColors.inkFaint),
              ),
            ),
          ),
          if (widget.trailing != null) ...widget.trailing!,
        ],
      ),
    );
  }
}
