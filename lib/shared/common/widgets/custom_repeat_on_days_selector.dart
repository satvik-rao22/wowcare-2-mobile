import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

import 'custom_date_time_field.dart';

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
  bool _isRepeatEnabled = false;
  final List<String> _allDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  late List<String> _selectedDays;
  DateTime? _repeatUntil;

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
                "Repeat On",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B2E4C),
                ),
              ),
              SizedBox(width: 16),
              Row(
                children: [
                  const Text("Off"),
                  Switch(
                    value: _isRepeatEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isRepeatEnabled = value;

                        if (!value) {
                          _selectedDays.clear();
                          widget.onSelectionChanged([]);
                        }
                      });
                    },

                    /// Track (background)
                    trackColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.themeColor; // ON
                      }
                      return Colors.grey.shade300; // OFF
                    }),

                    /// Thumb (bubble) → always white
                    thumbColor: MaterialStateProperty.all(Colors.white),
                  ),
                  const Text("On"),
                ],
              ),
              const Spacer(),
              if (_isRepeatEnabled)
                GestureDetector(
                  onTap: _toggleSelectAll,

                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: AppColors.primaryGradientColors,
                    ).createShader(bounds),
                    child: const Text(
                      "Select All",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // GridView - 3 items per row with better text visibility
        if (_isRepeatEnabled)
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
        const SizedBox(height: 16),
        if (_isRepeatEnabled)
          CustomDateTimeField(
            label: 'Until Date',
            isRequired: true,
            fetchInitialTime: false,
            onDateSelected: (date) {
              setState(() {
                _repeatUntil = date;
              });
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
                color: isSelected
                    ? AppColors.themeColor
                    : const Color(0xFFDDD6DD),
                width: 2,
              ),
              color: isSelected ? AppColors.themeColor : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
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
