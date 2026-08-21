import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';

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
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.themeColor,
        ),
      ),
      child: SearchBar(
        controller: widget.controller,
        constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor:
            widget.searchBarColor ??
            const WidgetStatePropertyAll(AppColors.white),
        // Keep the fill pure white — prevents Material 3 from applying a
        // surface tint / overlay that greys the search box.
        surfaceTintColor: const WidgetStatePropertyAll(AppColors.white),
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        hintText: widget.hintText,
        onChanged: widget.onChanged,
        hintStyle: WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.search, color: AppColors.primaryColor),
        ),
        trailing: widget.trailing,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  widget.borderColor ??
                  AppColors.primaryColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
