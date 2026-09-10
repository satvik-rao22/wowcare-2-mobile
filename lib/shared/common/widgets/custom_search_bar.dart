import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';
import 'package:wowcare/core/theme/app_radius.dart';

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
  final WidgetStateProperty<Color>? searchBarColor;
  final Color? borderColor;
  final List<Widget>? trailing;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    return SkeuFieldWell(
      radius: AppRadius.md,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppPalette.brand,
          ),
        ),
        child: SearchBar(
          controller: widget.controller,
          constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor:
              widget.searchBarColor ??
              const WidgetStatePropertyAll(AppPalette.surfaceField),
          // Pin the surface tint to the same fill, so Material 3 cannot layer
          // its own overlay on top and grey the well out.
          surfaceTintColor: const WidgetStatePropertyAll(
            AppPalette.surfaceField,
          ),
          overlayColor: const WidgetStatePropertyAll(
            AppColors.transparentColor,
          ),
          hintText: widget.hintText,
          onChanged: widget.onChanged,
          hintStyle: const WidgetStatePropertyAll(
            TextStyle(color: AppPalette.textMuted, fontSize: 15),
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.search, color: AppPalette.textMuted),
          ),
          trailing: widget.trailing,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              // Edgeless: a well is told by its fill, not by a line round it.
              side: widget.borderColor == null
                  ? BorderSide.none
                  : BorderSide(color: widget.borderColor!, width: 1.2),
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
