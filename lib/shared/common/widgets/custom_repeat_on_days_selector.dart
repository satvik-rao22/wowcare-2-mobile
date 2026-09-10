import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class CustomRepeatOnDaysSelector extends StatefulWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onSelectionChanged;

  const CustomRepeatOnDaysSelector({
    super.key,
    required this.selectedDays,
    required this.onSelectionChanged,
  });

  @override
  State<CustomRepeatOnDaysSelector> createState() =>
      _CustomRepeatOnDaysSelectorState();
}

class _CustomRepeatOnDaysSelectorState
    extends State<CustomRepeatOnDaysSelector> {
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  late List<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      widget.onSelectionChanged(List.from(_selectedDays));
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedDays.length == _allDays.length) {
        _selectedDays.clear();
      } else {
        _selectedDays = List.from(_allDays);
      }
      widget.onSelectionChanged(List.from(_selectedDays));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = _selectedDays.length == _allDays.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              const Text(
                'Repeat On',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleSelectAll,
                child: const Text(
                  'Select All',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.brand,
                  ),
                ),
              ),
            ],
          ),
        ),

        // GridView - 3 items per row with better text visibility
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 3.2, // Increased for better text space
          ),
          itemCount: _allDays.length,
          itemBuilder: (context, index) {
            final day = _allDays[index];
            return _buildDayCheckbox(day);
          },
        ),
      ],
    );
  }

  Widget _buildDayCheckbox(String day) {
    final bool isSelected = _selectedDays.contains(day);

    return GestureDetector(
      onTap: () => _toggleDay(day),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppPalette.brand : AppPalette.borderStrong,
                width: 2,
              ),
              color: isSelected ? AppPalette.brand : AppColors.transparentColor,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: AppPalette.onBrand)
                : null,
          ),
          const SizedBox(width: 10),
          // Day Name - Now with proper wrapping
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE9E6EC) // selected background
                    : const Color(0xFFF8F7FA), // unselected background
                borderRadius: BorderRadius.circular(
                  8,
                ), // rectangular with slight curve
              ),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color(0xFF7C94C1),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
