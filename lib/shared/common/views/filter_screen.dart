import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/media_res.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_selection_widget.dart';

class FilterScreen extends StatefulWidget {
  final String title;
  final List<FilerSection> sections;
  final void Function(Map<String, List<String>> appliedFilters) onApply;
  final bool showLoading;

  const FilterScreen({super.key, this.title = 'Filter', required this.sections, required this.onApply, this.showLoading = false});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late List<List<String>> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.sections.map((section) => List<String>.from(section.initialSelected)).toList();
  }

  void _onChanged(int index, dynamic value) {
    setState(() {
      if (value is List<String>){
        _selectedValues[index] = value;
      } else if (value is String) {
        _selectedValues[index] = [value]; // for single select dropdowns
      }
    });
  }

  void _applyFilters(){
    final Map<String, List<String>> result = {};
    for (int i = 0; i < widget.sections.length; i++){
      result[widget.sections[i].label] = List.from(_selectedValues[i]);
    }
    widget.onApply(result);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _selectedValues = widget.sections.map((_) => <String>[]).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
              Expanded(
                child: Container(
                  width: responsive.containerWidth,
                  margin: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  padding: EdgeInsets.all(
                    responsive.isTablet ? 32.0 : 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        responsive.isTablet ? 40.0 : 24.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  //child: widget.showLoading ? _buildShimmer() : _buildGrid(),
                  child: widget.showLoading ? _buildShimmer() : _buildMasonryGrid(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
        ),
        child: TextButton(
          onPressed: _applyFilters,
          child: Text(
            'Apply Filters',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasonryGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 16,
      children: List.generate(widget.sections.length, (index) {
        final section = widget.sections[index];
        final selected = _selectedValues[index];

        return StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: section.isSingleSelect ?
          CustomDropdown(
              label: section.label,
              hintText: section.hintText,
              items: section.items,
              selectedItem: selected.isNotEmpty ? selected.first : null,
              isField: true,
              showAsterisk: false,
              onSelect: (String? value) {
                setState(() {
                  _selectedValues[index] = value != null ? [value] : [];
                });
              })
          :section.isMultiSelectDropDown
              ? CustomMultiSelectDropdown(
            label: section.label,
            hintText: section.hintText,
            items: section.items,
            selectedItems: selected,
            onChanged: (List<String> values) {
              setState(() => _selectedValues[index] = values);
            },
          )
              : MultiSelectWidget(
            label: section.label,
            availableOptions: section.items,
            selectedOptions: selected,
            onSelectionChanged: (List<String> values) {
              setState(() => _selectedValues[index] = values);
            },
            colorfulSelection: false,
            isRequired: false,
          ),


        );
      }),
    );
  }

// this was causing the last dropdown to be pushed to the bottom for bigger screens like tablet
  Widget _buildGrid() {
    return GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.sections.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6
        ),
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          final currentSelection = _selectedValues[index];

          if (section.isMultiSelectDropDown) {
            return CustomMultiSelectDropdown(
              label: section.label,
              hintText: section.hintText,
              items: section.items,
              selectedItems: currentSelection,
              onChanged: (List<String> newSelection) {
                setState(() {
                  _selectedValues[index] = newSelection;
                });
              },
            );
          }

          return CustomDropdown(
            label: section.label,
            hintText: section.hintText,
            items: section.items,
            selectedItem: currentSelection.isNotEmpty ? currentSelection.first : null,
            isField: true,
            showAsterisk: false,
            onSelect: (String? selected) {
              setState(() {
                _selectedValues[index] = selected != null ? [selected] : [];
              });
            },
          );


          // return CustomFlexibleDropdown(
          //     label: section.label,
          //     hintText: section.hintText,
          //     items: section.items,
          //     selectedItems: section.isMultiSelect ? currentSelection : [],
          //     selectedItem: section.isMultiSelect ? null : (currentSelection.isNotEmpty ? currentSelection.first : null),
          //     isMultiSelect: section.isMultiSelect,
          //     onChanged: (val) => _onChanged(index, val),
          // );
        }
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.sections.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sections[index].label, style: TextStyle(color: AppColors.primaryColor, fontSize: 13),),
              const SizedBox(height: 8,),
              const ShimmerLoader(height: 40,)
            ],
          );
        }
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
    this.isSingleSelect = false
  });
}