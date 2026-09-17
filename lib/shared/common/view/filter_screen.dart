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

  /// Current picks keyed by section label, including unsaved in-dialog
  /// changes — the input [FilerSection.visibleWhen] predicates react to.
  Map<String, List<String>> _currentSelectionsByLabel() {
    final map = <String, List<String>>{};
    for (int i = 0; i < widget.sections.length; i++) {
      map[widget.sections[i].label] = _selectedValues[i];
    }
    return map;
  }

  bool _isVisible(int index) {
    final predicate = widget.sections[index].visibleWhen;
    if (predicate == null) return true;
    return predicate(_currentSelectionsByLabel());
  }

  void _applyFilters() {
    final selections = _currentSelectionsByLabel();
    final Map<String, List<String>> result = {};
    for (int i = 0; i < widget.sections.length; i++) {
      final section = widget.sections[i];
      // A section hidden by its own visibleWhen rule (e.g. Mode/Payment
      // Status once Type is picked) never contributes to the applied
      // filters, even if it holds a stale pick from before it was hidden.
      final visible = section.visibleWhen?.call(selections) ?? true;
      result[section.label] = visible ? List.from(_selectedValues[i]) : const [];
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
    final visibleIndices = [
      for (int i = 0; i < widget.sections.length; i++)
        if (_isVisible(i)) i,
    ];
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visibleIndices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) {
        final index = visibleIndices[i];
        final section = widget.sections[index];
        final selected = _selectedValues[index];

        if (section.isSingleSelect) {
          return CustomDropdown(
            label: section.label,
            hintText: section.hintText,
            // No "All" entry in the popup — the only single-select sections
            // are things like Status, which shouldn't offer an
            // unselectable "All" choice inside the list itself. Clearing a
            // pick instead goes through the dedicated [onClear] "x" below.
            items: section.items,
            selectedItem: selected.isNotEmpty ? selected.first : null,
            isField: true,
            showAsterisk: false,
            onSelect: (String? value) {
              setState(() {
                _selectedValues[index] = value != null ? [value] : [];
              });
            },
            onClear: selected.isEmpty
                ? null
                : () => setState(() => _selectedValues[index] = []),
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

  /// Whether this section should currently be shown, given the sheet's
  /// in-progress selections (label -> picked values, including unsaved
  /// picks). Null means always visible. Re-evaluated on every selection
  /// change, so a section can appear/disappear live as the user picks other
  /// fields (e.g. hiding Mode/Payment Status once Type is picked).
  final bool Function(Map<String, List<String>> currentSelections)?
      visibleWhen;

  FilerSection({
    required this.label,
    required this.items,
    this.hintText = 'Select',
    this.initialSelected = const [],
    this.isMultiSelectDropDown = true,
    this.colorfulChips = false,
    this.isSingleSelect = false,
    this.visibleWhen,
  });
}
