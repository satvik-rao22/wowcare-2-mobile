import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';

/// How tall the well sits. [compact] is for a dense tab header.
enum SearchFieldDensity {
  regular(44),
  compact(36);

  const SearchFieldDensity(this.height);

  final double height;
}

/// The app's only search input.
///
/// Every search box in the app is this widget, so its look changes in one
/// place. It is a well: the cool `surfaceField` fill with an inset shadow and
/// no outline, the same recipe every other input uses.
///
/// [controller] is optional. Pass one when the caller drives search from a
/// listener or reads the text elsewhere, and the caller keeps ownership of
/// disposing it. Leave it off and the widget makes and disposes its own.
///
/// Pass [debounce] only when the caller is *not* already debouncing, or the
/// two delays stack.
class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    required this.hintText,
    this.controller,
    this.onChanged,
    this.debounce,
    this.showClearButton = false,
    this.onCleared,
    this.density = SearchFieldDensity.regular,
    this.radius = AppRadius.md,
    this.trailing,
    super.key,
  });

  final String hintText;

  /// Caller-owned when given. The widget never disposes one it did not make.
  final TextEditingController? controller;

  final ValueChanged<String>? onChanged;

  /// Delay before [onChanged] fires. Null fires on every keystroke.
  final Duration? debounce;

  /// Shows an X once there is text to clear.
  final bool showClearButton;

  /// Runs after the clear button empties the field, for side effects the
  /// caller needs beyond [onChanged] seeing an empty string.
  final VoidCallback? onCleared;

  final SearchFieldDensity density;
  final double radius;
  final List<Widget>? trailing;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  TextEditingController? _own;
  Timer? _debounce;

  TextEditingController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = TextEditingController();
    if (widget.showClearButton) _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.showClearButton) _controller.removeListener(_onTextChanged);
    _own?.dispose();
    super.dispose();
  }

  /// Only to repaint the clear button. The search itself runs off onChanged.
  void _onTextChanged() => setState(() {});

  void _handleChanged(String value) {
    final ValueChanged<String>? onChanged = widget.onChanged;
    if (onChanged == null) return;
    final Duration? delay = widget.debounce;
    if (delay == null) {
      onChanged(value);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(delay, () => onChanged(value));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.density.height;
    final bool showClear =
        widget.showClearButton && _controller.text.isNotEmpty;

    return SkeuFieldWell(
      radius: widget.radius,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppPalette.brand,
          ),
        ),
        child: SearchBar(
          controller: _controller,
          constraints: BoxConstraints(minHeight: height, maxHeight: height),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: const WidgetStatePropertyAll(
            AppPalette.surfaceField,
          ),
          // Pin the surface tint to the same fill, so Material 3 cannot layer
          // its own overlay on top and grey the well out.
          surfaceTintColor: const WidgetStatePropertyAll(
            AppPalette.surfaceField,
          ),
          overlayColor: const WidgetStatePropertyAll(
            AppColors.transparentColor,
          ),
          hintText: widget.hintText,
          onChanged: _handleChanged,
          hintStyle: const WidgetStatePropertyAll(
            TextStyle(color: AppPalette.textMuted, fontSize: 15),
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.search, color: AppPalette.textMuted),
          ),
          trailing: <Widget>[
            if (showClear)
              IconButton(
                icon: const Icon(Icons.close, color: AppPalette.textMuted),
                onPressed: _clear,
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear',
              ),
            ...?widget.trailing,
          ],
          shape: WidgetStatePropertyAll(
            // Edgeless: a well is told by its fill, not by a line round it.
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.radius),
              side: BorderSide.none,
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
