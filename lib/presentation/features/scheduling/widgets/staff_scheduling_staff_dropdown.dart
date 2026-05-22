import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Compact staff picker — scrollable menu with a max height (not full screen).
class StaffSchedulingStaffDropdown extends StatelessWidget {
  const StaffSchedulingStaffDropdown({
    super.key,
    required this.staffNames,
    required this.selectedStaffName,
    required this.onSelected,
    this.isLoading = false,
    this.menuMaxHeight = 280,
  });

  final List<String> staffNames;
  final String? selectedStaffName;
  final ValueChanged<String> onSelected;
  final bool isLoading;
  final double menuMaxHeight;

  static const TextStyle _fieldTextStyle = TextStyle(
    fontFamily: 'Manrope',
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

    final hasSelection = selectedStaffName != null &&
        selectedStaffName!.isNotEmpty &&
        staffNames.contains(selectedStaffName);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasSelection ? selectedStaffName : null,
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
          items: staffNames
              .map(
                (name) => DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldTextStyle,
                  ),
                ),
              )
              .toList(),
          onChanged: staffNames.isEmpty
              ? null
              : (value) {
                  if (value != null) onSelected(value);
                },
        ),
      ),
    );
  }
}
