import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Compact staff picker — scrollable menu with a max height (not full screen).
///
/// Keyed by staff CODE, not display name: two staff members can share the
/// same name, and a name-keyed [DropdownButton] asserts (duplicate value)
/// the moment that happens.
class StaffSchedulingStaffDropdown extends StatelessWidget {
  const StaffSchedulingStaffDropdown({
    super.key,
    required this.staff,
    required this.selectedStaffCode,
    required this.onSelected,
    this.isLoading = false,
    this.menuMaxHeight = 280,
  });

  final List<StaffMember> staff;
  final String? selectedStaffCode;
  final ValueChanged<String> onSelected;
  final bool isLoading;
  final double menuMaxHeight;

  static const TextStyle _fieldTextStyle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: PrimaryCircularLoader(size: 22, strokeWidth: 2),
        ),
      );
    }

    final hasSelection = selectedStaffCode != null &&
        selectedStaffCode!.isNotEmpty &&
        staff.any((s) => s.code == selectedStaffCode);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasSelection ? selectedStaffCode : null,
          isExpanded: true,
          menuMaxHeight: menuMaxHeight,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryColor,
            size: 24,
          ),
          hint: const Text('Select Staff', style: _fieldTextStyle),
          style: _fieldTextStyle,
          items: staff
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.code,
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: staff.isEmpty
              ? null
              : (value) {
                  if (value != null) onSelected(value);
                },
        ),
      ),
    );
  }
}
