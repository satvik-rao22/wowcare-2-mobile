import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';

/// Shared pure UI-builder helpers extracted from `activity_daily_tab.dart`
/// and `activity_custom_tab.dart` (Mandate 6, "Reuse what exists").
///
/// These two functions were byte-identical (module-private instance methods
/// named `_buildCustomDropdown`/`_buildCustomMultiDropdown`) in both View
/// State classes. Neither reads nor writes any instance field of either
/// State — both are pure functions of their parameters — so they were safe
/// to hoist here as top-level functions rather than left duplicated.
///
/// (Other identically-named method pairs between the two tab files were
/// investigated in the same pass but were either meaningfully different in
/// behaviour, or read/wrote several instance fields and so were left
/// un-deduped — see the Package 8 refactor notes.)

/// Single-select dropdown with the styling shared by the daily/custom
/// activity feed tabs.
Widget buildActivityTabCustomDropdown(
  String hintText,
  List<String> items,
  String? selectedItem,
  ValueChanged<String?> onSelect, {
  bool isRequired = false,
  double? height,
}) {
  return CustomDropdown(
    label: null,
    hintText: hintText,
    height: height ?? 40,
    items: items,
    selectedItem: selectedItem,
    onSelect: onSelect,
    showAsterisk: isRequired,
    selectedTextStyle: AppTextStyles.activityDropdownValueText(
      hasValue: selectedItem != null && selectedItem.trim().isNotEmpty,
    ),
    popupItemTextStyle: AppTextStyles.activityDropdownPopupItem,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );
}

/// Multi-select dropdown with the styling shared by the daily/custom
/// activity feed tabs.
Widget buildActivityTabCustomMultiDropdown(
  String hintText,
  List<String> items,
  List<String> selectedItems,
  ValueChanged<List<String>> onChanged, {
  double? height,
}) {
  return SizedBox(
    height: height ?? 40,
    child: CustomMultiSelectDropdown(
      hintText: hintText,
      items: items,
      selectedItems: selectedItems,
      onChanged: onChanged,
      gapHeight: 8,
      maxDropdownHeight: 280,
    ),
  );
}
