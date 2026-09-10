import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class CommonMultiSelectDropdown extends StatefulWidget {
  const CommonMultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.onConfirm,
    this.isRequired = true,
  });

  final String label;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onConfirm;
  final bool isRequired;

  @override
  State<CommonMultiSelectDropdown> createState() =>
      _CommonMultiSelectDropdownState();
}

class _CommonMultiSelectDropdownState extends State<CommonMultiSelectDropdown> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<String>.from(widget.selectedItems);
  }

  void _openDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.label),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final checked = _tempSelected.contains(item);
              return CheckboxListTile(
                title: Text(item),
                value: checked,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _tempSelected.add(item);
                    } else {
                      _tempSelected.remove(item);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onConfirm(_tempSelected);
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.selectedItems.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              TextSpan(text: widget.label),
              if (widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: MaterialHues.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openDialog,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppSurfaces.well(radius: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    count == 0 ? 'Select' : '$count item(s) selected',
                    style: const TextStyle(fontFamily: AppFonts.body),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
