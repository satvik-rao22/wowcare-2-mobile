import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class MultiSelectWidget extends StatefulWidget {
  final List<String> availableOptions;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;
  final String label;
  final String hintText;
  final bool isRequired;
  final String? errorText;
  final bool colorfulSelection;

  /// When true, renders a fixed-height field with "N selected" summary
  /// (useful inside GridViews to avoid layout overflow).
  final bool compact;
  final bool showClearAllOption;
  final String clearSelectionText;

  const MultiSelectWidget({
    super.key,
    required this.availableOptions,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.label = "Select Tags",
    this.hintText = "Select Tags",
    this.isRequired = true,
    this.errorText = "This is a mandatory field please select one option",
    this.colorfulSelection = true,
    this.compact = false,
    this.showClearAllOption = false,
    this.clearSelectionText = 'Clear All',
  });

  @override
  State<MultiSelectWidget> createState() => _MultiSelectWidgetState();
}

class _MultiSelectWidgetState extends State<MultiSelectWidget> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();

  Color _getTagBackgroundColor(String tag) {
    if (tag.isEmpty) return AppColors.tagColors[0];
    if (tag == '5 Days') return AppColors.tagColors[1];
    if (tag == 'Full Day') return AppColors.tagColors[2];
    if (tag == 'Photo Permission') return AppColors.tagColors[3];
    final int index = tag.hashCode.abs() % AppColors.tagColors.length;
    return AppColors.tagColors[index];
  }

  Color _getTagTextColor(String tag) {
    return AppColors.tagTextColors[0];
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final RenderBox? box =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset position = box.localToGlobal(Offset.zero);
    final double fieldWidth = box.size.width;

    String searchQuery = "";
    List<String> filteredTags = List.from(widget.availableOptions);
    List<String> localSelected = List.from(widget.selectedOptions);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy - 10,
            width: fieldWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset.fromDirection(pi / 2, 70),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: AppSurfaces.card(radius: 12),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      final responsive = ResponsiveHelper(context);
                      filteredTags = widget.availableOptions
                          .where(
                            (tag) => tag.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppSurfaces.fieldFill,
                                hintText: widget.hintText,
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: MaterialHues.grey300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (val) =>
                                  setOverlayState(() => searchQuery = val),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount:
                                  filteredTags.length +
                                  (widget.showClearAllOption ? 1 : 0),
                              itemBuilder: (context, index) {
                                // for clear all selections option
                                if (widget.showClearAllOption && index == 0) {
                                  final hasSelections =
                                      localSelected.isNotEmpty;
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: hasSelections
                                            ? () {
                                                setOverlayState(() {
                                                  localSelected.clear();
                                                  widget.onSelectionChanged([]);
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          color: hasSelections
                                              ? AppPalette.surfaceSunken
                                              : Colors.transparent,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 34),
                                              Expanded(
                                                child: Text(
                                                  widget.clearSelectionText,
                                                  style: TextStyle(
                                                    fontFamily: AppFonts.body,
                                                    fontSize: responsive
                                                        .inputFontSize,
                                                    fontWeight: FontWeight.w500,
                                                    color: hasSelections
                                                        ? AppColors.primaryColor
                                                        : MaterialHues.grey400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Divider(height: 1),
                                    ],
                                  );
                                }
                                // all options
                                final tagIndex = widget.showClearAllOption
                                    ? index - 1
                                    : index;
                                final tag = filteredTags[tagIndex];
                                final isSelected = localSelected.contains(tag);

                                return InkWell(
                                  onTap: () {
                                    setOverlayState(() {
                                      if (isSelected) {
                                        localSelected.remove(tag);
                                      } else {
                                        localSelected.add(tag);
                                      }
                                      widget.onSelectionChanged(
                                        List.from(localSelected),
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        GradientCheckbox(value: isSelected),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize:
                                                  responsive.inputFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isDropdownOpen = false);
  }

  @override
  void dispose() {
    //_closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final String displayText = widget.selectedOptions.isEmpty
        ? widget.hintText
        : '${widget.selectedOptions.length} selected';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: responsive.labelFontSize,
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryColor,
              ),
              children: [
                TextSpan(text: widget.label),
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: MaterialHues.red),
                  ),
              ],
            ),
          ),
          SizedBox(height: responsive.isTablet ? 8.0 : 6.0),

          // Main field with chips
          GestureDetector(
            key: _fieldKey,
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              height: widget.compact ? 40 : null,
              padding: widget.compact
                  ? const EdgeInsets.symmetric(horizontal: 10)
                  : EdgeInsets.symmetric(
                      horizontal: responsive.isTablet ? 20 : 16,
                      vertical: responsive.isTablet ? 16 : 12,
                    ),
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   border: Border.all(
              //     color: widget.errorText != null ? Colors.red : AppPalette.textMuted,
              //   ),
              //   borderRadius: BorderRadius.circular(responsive.isTablet ? 12 : 10),
              // ),
              decoration: BoxDecoration(
                color: AppPalette.brandSoft.withValues(alpha: 0.102),
                //color: AppPalette.surfaceSunken,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  if (widget.compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: widget.selectedOptions.isEmpty
                              ? MaterialHues.grey600
                              : MaterialHues.black87,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (widget.selectedOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.hintText,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: responsive.inputFontSize,
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.selectedOptions.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.colorfulSelection
                                ? _getTagBackgroundColor(tag)
                                : AppPalette.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: _getTagTextColor(tag),
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.inputFontSize,
                                    fontFamily: AppFonts.body,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  final newList = widget.selectedOptions
                                      .where((t) => t != tag)
                                      .toList();
                                  widget.onSelectionChanged(newList);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _getTagTextColor(tag),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      _isDropdownOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                      size: responsive.isTablet ? 28 : 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (widget.errorText != null &&
              widget.isRequired &&
              widget.selectedOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.errorText!,
                style: const TextStyle(color: MaterialHues.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class GradientCheckbox extends StatelessWidget {
  final bool value;
  const GradientCheckbox({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? AppColors.transparentColor : AppPalette.borderStrong,
          width: 2,
        ),
        color: value ? AppPalette.brand : AppColors.transparentColor,
      ),
      child: value
          ? const Icon(Icons.check, size: 16, color: AppPalette.onBrand)
          : null,
    );
  }
}
