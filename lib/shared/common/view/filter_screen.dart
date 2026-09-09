import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_selection_widget.dart';

class FilterScreen extends StatefulWidget {
  final String title;
  final List<FilerSection> sections;
  final void Function(Map<String, List<String>> appliedFilters) onApply;
  final bool showLoading;

  const FilterScreen({
    super.key,
    this.title = 'Filter',
    required this.sections,
    required this.onApply,
    this.showLoading = false,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late List<List<String>> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.sections
        .map((section) => List<String>.from(section.initialSelected))
        .toList();
  }

  void _applyFilters() {
    final Map<String, List<String>> result = {};
    for (int i = 0; i < widget.sections.length; i++) {
      result[widget.sections[i].label] = List.from(_selectedValues[i]);
    }
    widget.onApply(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: widget.title,
      child: widget.showLoading ? _buildShimmer() : _buildMasonryGrid(),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: CustomButtonLayout(
        confirmButtonLabel: 'Apply Filters',
        onPressedConfirm: _applyFilters,
        showCancelButton: false,
        isForm: false,
      ),
    );
  }

  Widget _buildMasonryGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.sections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final section = widget.sections[index];
        final selected = _selectedValues[index];

        if (section.isSingleSelect) {
          return CustomDropdown(
            label: section.label,
            hintText: section.hintText,
            // No "All"/clear entry in the popup — the only single-select
            // section today is Status (communication module), which should
            // not offer an unselectable "All" choice.
            items: section.items,
            selectedItem: selected.isNotEmpty ? selected.first : null,
            isField: true,
            showAsterisk: false,
            onSelect: (String? value) {
              setState(() {
                _selectedValues[index] = value != null ? [value] : [];
              });
            },
          );
        }

        if (section.isMultiSelectDropDown) {
          return CustomMultiSelectDropdown(
            label: section.label,
            hintText: section.hintText,
            items: section.items,
            selectedItems: selected,
            onChanged: (List<String> values) {
              setState(() => _selectedValues[index] = values);
            },
          );
        }

        return MultiSelectWidget(
          label: section.label,
          hintText: section.hintText,
          availableOptions: section.items,
          selectedOptions: selected,
          onSelectionChanged: (List<String> values) {
            setState(() => _selectedValues[index] = values);
          },
          compact: true,
          colorfulSelection: false,
          isRequired: false,
        );
      },
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.sections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sections[index].label,
              style: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            const ShimmerLoader(height: 40),
          ],
        );
      },
    );
  }
}

class FilerSection {
  final String label;
  final String hintText;
  final List<String> items;
  final List<String> initialSelected;
  final bool isMultiSelectDropDown;
  final bool colorfulChips;
  final bool isSingleSelect;
  FilerSection({
    required this.label,
    required this.items,
    this.hintText = 'Select',
    this.initialSelected = const [],
    this.isMultiSelectDropDown = true,
    this.colorfulChips = false,
    this.isSingleSelect = false,
  });
}
