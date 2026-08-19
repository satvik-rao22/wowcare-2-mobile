import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomFlexibleDropdown extends StatefulWidget {
  const CustomFlexibleDropdown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    this.selectedItems = const [],
    this.selectedItem,
    this.isMultiSelect = false,
    this.isEnabled = true,
    this.onChanged,
    this.labelStyle,
    this.showAsterisk = false,
    this.fieldHeight = 40,
    this.contentPadding,
  });

  final String? label;
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final String? selectedItem;

  final bool isMultiSelect;
  final bool isEnabled;
  final ValueChanged<dynamic>? onChanged; // List<String> or String

  final TextStyle? labelStyle;
  final bool showAsterisk;
  final double fieldHeight;
  final EdgeInsets? contentPadding;

  @override
  State<CustomFlexibleDropdown> createState() => _CustomFlexibleDropdownState();
}

class _CustomFlexibleDropdownState extends State<CustomFlexibleDropdown> {
  List<String> _selectedItems = [];
  String? _selectedItem;

  @override
  void initState() {
    super.initState();
    _updateFromWidget();
  }

  @override
  void didUpdateWidget(covariant CustomFlexibleDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems != widget.selectedItems ||
        oldWidget.selectedItem != widget.selectedItem ||
        oldWidget.isMultiSelect != widget.isMultiSelect) {
      _updateFromWidget();
    }
  }

  void _updateFromWidget() {
    if (widget.isMultiSelect) {
      _selectedItems = List.from(widget.selectedItems);
      _selectedItem = null; // clear single
    } else {
      _selectedItem = widget.selectedItem;
      _selectedItems = _selectedItem != null ? [_selectedItem!] : [];
    }
  }

  String get _displayText {
    if (widget.isMultiSelect) {
      return _selectedItems.isEmpty
          ? widget.hintText
          : '${_selectedItems.length} selected';
    } else {
      return _selectedItem ?? widget.hintText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          RichText(
            text: TextSpan(
              style: widget.labelStyle ?? TextStyle(color: AppColors.primaryColor, fontSize: 13, fontFamily: 'Manrope'),
              children: [
                TextSpan(text: widget.label!),
                if (widget.showAsterisk)
                  const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          height: widget.fieldHeight,
          width: double.infinity,
          padding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: PopupMenuButton<String>(
            enabled: widget.isEnabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            onSelected: (String value) {
              setState(() {
                if (widget.isMultiSelect) {
                  if (_selectedItems.contains(value)) {
                    _selectedItems.remove(value);
                  } else {
                    _selectedItems.add(value);
                  }
                  widget.onChanged?.call(List.from(_selectedItems));
                } else {
                  _selectedItem = value;
                  _selectedItems = [value];
                  widget.onChanged?.call(value);
                }
              });
            },
            itemBuilder: (context) => widget.items.map((item) {
              final bool isSelected = widget.isMultiSelect
                  ? _selectedItems.contains(item)
                  : _selectedItem == item;

              return PopupMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    if (widget.isMultiSelect)
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank_outlined,
                        size: 20,
                        //color: isSelected ? AppColors.themeColor : Colors.grey,
                        color:  Color(0xFF8A85FF)
                      )
                    else if (isSelected)
                      const Icon(Icons.check, size: 20, color: Color(0xFF8A85FF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:  AppColors.primaryColor,
                          fontFamily: "Manrope",
                          fontSize: 14
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      fontFamily: 'Manrope'
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

