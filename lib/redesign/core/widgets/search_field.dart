import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A search well with a leading glyph and a clear key that appears once
/// there is something to clear. Components page `.search`, 5a's roster.
///
/// Owns its controller when none is passed. Debouncing is the caller's job:
/// `AppDurations.searchDebounce` is the interval.
class SearchField extends StatefulWidget {
  const SearchField({
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = AppStrings.search,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called after the clear key has emptied the field.
  final VoidCallback? onClear;

  final String hintText;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.field(c),
      padding: AppSizes.searchPad,
      child: Row(
        spacing: AppSizes.dropdownGap,
        children: <Widget>[
          Icon(AppIcons.search, size: AppSizes.searchGlyph, color: c.ink3),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              cursorColor: c.pink,
              style: AppTextStyles.fieldText.copyWith(color: c.ink),
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.placeholder.copyWith(color: c.ink3),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : Semantics(
                    button: true,
                    label: AppStrings.clearSearch,
                    child: Pressable.surface(
                      onTap: _clear,
                      child: Icon(
                        AppIcons.close,
                        size: AppSizes.searchGlyph,
                        color: c.ink3,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
