import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

/// Reusable filter panel used in Attendance Custom and Absent tabs
/// for both staff and students.
class AttendanceFilterPanel extends StatefulWidget {
  const AttendanceFilterPanel({
    super.key,
    required this.isStaff,
  });

  final bool isStaff;

  @override
  State<AttendanceFilterPanel> createState() => _AttendanceFilterPanelState();
}

class _AttendanceFilterPanelState extends State<AttendanceFilterPanel> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassroom;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Demo classroom options – to be wired to real data later.
    final classrooms = <String>['All Classrooms', 'Room A', 'Room B', 'Room C'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search + classroom dropdown on the same row
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText:
                      widget.isStaff ? 'Search Staff' : 'Search Students',
                  onChanged: (value) {
                    // TODO: wire to real search later
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClassroom ?? classrooms.first,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                    ),
                    items: classrooms
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff573353),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClassroom = value;
                      });
                      // TODO: wire classroom filter
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date range selector
          const Align(
            alignment: Alignment.centerLeft,
            child: CustomDateTimeField(
              label: null,
              hasLabel: false,
              isTime: false,
              isRangePicker: true,
            ),
          ),
        ],
      ),
    );
  }
}

