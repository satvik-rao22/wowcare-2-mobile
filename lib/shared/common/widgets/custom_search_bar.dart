import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    required this.controller,
    required this.hintText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;

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
        constraints: const BoxConstraints(
          minHeight: 44,
          maxHeight: 44,
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
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
          child: Icon(
            Icons.search,
            color: AppColors.primaryColor,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}