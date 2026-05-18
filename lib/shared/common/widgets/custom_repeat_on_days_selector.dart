import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/features/scheduling/cubit/Add-Shift/cubit/add_shift_cubit.dart';
import '../../utils/responsive_helper.dart';
import 'custom_checkbox.dart';
import 'custom_date_time_field.dart';
import 'custom_toggle.dart';

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
    "Saturday",
  ];

  late List<String> _selectedDays;

  String _getCurrentDayName() {
    final weekday = DateTime.now().weekday;

    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      default:
        return "";
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedDays = List.from(widget.selectedDays);

    final currentDay = _getCurrentDayName();

    if (_selectedDays.isEmpty && _allDays.contains(currentDay)) {
      _selectedDays.add(currentDay);

      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   widget.onSelectionChanged(_selectedDays);
      //   // context.read<AddShiftCubit>().updateRepeatDays(_selectedDays);
      //   try {
      //     context.read<AddShiftCubit>().updateRepeatDays(_selectedDays);
      //   } catch (_) {}
      // });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        widget.onSelectionChanged(_selectedDays);

        try {
          context.read<AddShiftCubit>().updateRepeatDays(_selectedDays);
        } catch (_) {}
      });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      // widget.onSelectionChanged(List.from(_selectedDays));
      final days = List<String>.from(_selectedDays);

      widget.onSelectionChanged(days);

      // context.read<AddShiftCubit>().updateRepeatDays(days);
      try {
        context.read<AddShiftCubit>().updateRepeatDays(days);
      } catch (_) {}
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedDays.length == _allDays.length) {
        _selectedDays.clear();
      } else {
        _selectedDays = List.from(_allDays);
      }
      // widget.onSelectionChanged(List.from(_selectedDays));
      final days = List<String>.from(_selectedDays);

      widget.onSelectionChanged(days);

      // context.read<AddShiftCubit>().updateRepeatDays(days);
      try {
        context.read<AddShiftCubit>().updateRepeatDays(days);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // final bool isAllSelected = _selectedDays.length == _allDays.length;
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              const Text(
                "Repeat Off",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: 16),
              CustomToggle(
                label: 'ON',
                isToggled: _isRepeatEnabled,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
                onToggle: (value) {
                  setState(() {
                    _isRepeatEnabled = value;

                    if (!value) {
                      _selectedDays.clear();
                      widget.onSelectionChanged([]);
                      // context.read<AddShiftCubit>().updateRepeatDays([]);
                      try {
                        context.read<AddShiftCubit>().updateRepeatDays([]);
                      } catch (_) {}
                    }
                  });
                },
                labelOnLeftSide: false,
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
        // if (_isRepeatEnabled)
        //   GridView.builder(
        //     shrinkWrap: true,
        //     physics: const NeverScrollableScrollPhysics(),
        //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //       crossAxisCount: 3,
        //       crossAxisSpacing: 12,
        //       mainAxisSpacing: 16,
        //       childAspectRatio: 2.4, // Increased for better text space
        //     ),
        //     itemCount: _allDays.length,
        //     itemBuilder: (context, index) {
        //       final day = _allDays[index];
        //       return CustomCheckbox(
        //         value: _selectedDays.contains(day),
        //         onChanged: (_) => _toggleDay(day),
        //         label: day,
        //         labelStyle: const TextStyle(
        //           fontSize: 14,
        //           fontWeight: FontWeight.w500,
        //         ),
        //         usingInkwell: false,
        //       );
        //     },
        //   ),
        if (_isRepeatEnabled)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              double fontSize = 12;
              double childAspectRatio = 2.4;

              if (width < 360) {
                fontSize = 10;
                childAspectRatio = 2.0;
              } else if (width < 420) {
                fontSize = 11;
                childAspectRatio = 2.2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 15,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _allDays.length,
                itemBuilder: (context, index) {
                  final day = _allDays[index];

                  return CustomCheckbox(
                    value: _selectedDays.contains(day),
                    onChanged: (_) => _toggleDay(day),
                    label: day,
                    labelStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis,
                    ),
                    usingInkwell: false,
                  );
                },
              );
            },
          ),
        const SizedBox(height: 16),
        if (_isRepeatEnabled)
          CustomDateTimeField(
            label: 'Until Date',

            labelStyle: TextStyle(
              fontSize: responsive.labelFontSize,
              fontWeight: FontWeight.w500,
            ),

            isRangePicker: false,
            isRequired: true,
            hasLabel: true,
            fetchInitialTime: false,

            onDateSelected: (date) {
              // context.read<AddShiftCubit>().updateDateRange(date, date);
              try {
                context.read<AddShiftCubit>().updateDateRange(date, date);
              } catch (_) {}
            },
          ),
      ],
    );
  }
}
