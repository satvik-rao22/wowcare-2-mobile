import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class CustomMultiSelectDropdown extends StatefulWidget {
  final String? label;
  final String? suffix;
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;
  final double? labelBottomSpacing;
  final double gapHeight;
  final double maxDropdownHeight;
  final bool showSelectAll;
  final bool enableSearch;
  final String? searchHintText;
  final bool isRequired;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    this.showSelectAll = false,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.label,
    this.suffix,
    this.isField = false,
    this.width,
    this.labelBottomSpacing,
    this.gapHeight = 6,
    this.maxDropdownHeight = 250,
    this.enableSearch = false,
    this.searchHintText,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdown> createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  static const double _dropdownRowHeight = 44;
  late List<String> _localSelectedItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
    _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
  }

  @override
  void didUpdateWidget(CustomMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      setState(() {
        _localSelectedItems = List.from(widget.selectedItems);
        _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
      });
      // The open overlay is a StatefulBuilder whose builder closure only
      // re-runs when explicitly told to - it does NOT automatically pick up
      // a new `widget.items`/`widget.selectedItems` just because this State
      // rebuilt. Without this, opening the dropdown before an async fetch
      // (e.g. seeding it from an API call) resolves freezes the overlay on
      // that empty/stale snapshot forever, even though the field's own
      // closed-state re-render (and every later rebuild) has the real data -
      // only closing and reopening would ever show it. Deferred to a
      // post-frame callback: didUpdateWidget runs mid-build, and
      // OverlayEntry.markNeedsBuild() asserts if called synchronously here
      // ("setState() or markNeedsBuild() called during build").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  String get displaySuffix {
    if (widget.hintText.toLowerCase() == 'status') {
      return 'status';
    } else if (widget.hintText.toLowerCase() == 'tags') {
      return 'tag${_localSelectedItems.length > 1 ? 's' : ''}';
    } else if (widget.suffix?.toLowerCase() == 'category') {
      return '${_localSelectedItems.length > 1 ? 'categories' : 'category'}';
    }
    return 'items';
  }

  void _toggleDropdown() {
    if (isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _searchQuery = '';
    _searchController.clear();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      isDropdownOpen = true;
    });
  }

  void _closeDropdown({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (updateState && mounted) {
      setState(() {
        isDropdownOpen = false;
      });
    }
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.themeColor : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? AppColors.themeColor : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  OverlayEntry _createOverlayEntry() {
    final renderObject =
        _fieldKey.currentContext?.findRenderObject() ??
        context.findRenderObject();
    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;

    // Decide whether the list opens downward (default) or upward. In a bottom
    // sheet the field sits near the bottom of the screen, so a downward list is
    // clipped by the screen edge and only a row or two is visible. When there
    // isn't enough room below, open upward instead.
    final fieldTopLeft = renderBox.localToGlobal(Offset.zero);
    final mq = MediaQuery.of(context);
    final itemCount = widget.items.length + (widget.showSelectAll ? 1 : 0);
    final desiredHeight = (itemCount * _dropdownRowHeight).clamp(
      0.0,
      widget.maxDropdownHeight,
    );
    final spaceBelow =
        mq.size.height - mq.viewInsets.bottom - (fieldTopLeft.dy + size.height);
    final spaceAbove = fieldTopLeft.dy;
    final openUpward =
        spaceBelow < desiredHeight + widget.gapHeight + 16 &&
        spaceAbove > spaceBelow;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() {
                    isDropdownOpen = false;
                  });
                }
                _closeDropdown();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: openUpward
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              followerAnchor: openUpward
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: Offset(
                0.0,
                openUpward ? -widget.gapHeight : widget.gapHeight,
              ),
              child: Material(
                elevation: 8.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      List<String> filteredItems() {
                        final q = _searchQuery.trim().toLowerCase();
                        if (q.isEmpty) return widget.items;
                        return widget.items
                            .where((item) => item.toLowerCase().contains(q))
                            .toList();
                      }

                      final visibleItems = filteredItems();
                      // No underlying items to pick from (or, once search is
                      // re-enabled, a query that matches nothing) — the
                      // "Select All" row alone with an empty list below it
                      // was confusing, so show a plain empty state instead.
                      if (visibleItems.isEmpty) {
                        return const SizedBox(
                          height: _dropdownRowHeight,
                          child: Center(
                            child: Text(
                              'No matches found',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: Color(0x99573353),
                              ),
                            ),
                          ),
                        );
                      }
                      final itemCount =
                          visibleItems.length + (widget.showSelectAll ? 1 : 0);
                      // final searchBoxHeight = widget.enableSearch ? 52.0 : 0.0;
                      const searchBoxHeight = 0.0;
                      // `_dropdownRowHeight` is only an ESTIMATE (one line of
                      // text) — a long label (e.g. a two-word student name in
                      // a narrow side-by-side dropdown) wraps to a second
                      // line, which the estimate doesn't account for. Capping
                      // the container to that estimate then clipped the
                      // wrapped second line with no way to reach it — most
                      // visible with a single item, where the whole overlay
                      // was barely one row tall. Below the max height, let
                      // the list size itself to its REAL (possibly wrapped)
                      // content instead of the flat estimate; only once the
                      // estimate crosses the cap does a fixed, scrollable
                      // height take over.
                      final targetHeight =
                          (itemCount * _dropdownRowHeight) + searchBoxHeight;
                      final needsScrollCap =
                          targetHeight > widget.maxDropdownHeight;

                      Widget buildRow(int index) {
                        if (widget.showSelectAll && index == 0) {
                          final isAllSelected =
                              _localSelectedItems.length == widget.items.length;
                          return InkWell(
                            onTap: () {
                              setOverlayState(() {
                                if (isAllSelected) {
                                  _localSelectedItems.clear();
                                } else {
                                  _localSelectedItems = List.from(widget.items);
                                }
                              });
                              setState(() {});
                              widget.onChanged(
                                List<String>.from(_localSelectedItems),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _buildCheckbox(isAllSelected),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Select All',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final actualIndex = widget.showSelectAll
                            ? index - 1
                            : index;
                        final item = visibleItems[actualIndex];
                        final isSelected = _localSelectedItems.contains(item);

                        return InkWell(
                          onTap: () {
                            setOverlayState(() {
                              if (isSelected) {
                                _localSelectedItems.remove(item);
                              } else {
                                _localSelectedItems.add(item);
                              }
                            });
                            setState(() {});
                            widget.onChanged(
                              List<String>.from(_localSelectedItems),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _buildCheckbox(isSelected),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 14),
                                    // Allow long labels (e.g. a two-word
                                    // student name, "Assistant Teacher") to
                                    // wrap to a second line instead of
                                    // clipping.
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!needsScrollCap) {
                        // Few enough rows to stay under the cap — size the
                        // list to its ACTUAL content (including any row that
                        // wraps to 2 lines) instead of the flat per-row
                        // estimate.
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < itemCount; i++) buildRow(i),
                          ],
                        );
                      }

                      return SizedBox(
                        height: widget.maxDropdownHeight,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: itemCount,
                          itemBuilder: (context, index) => buildRow(index),
                        ),
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
  }

  @override
  void dispose() {
    _closeDropdown(updateState: false);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClassroom = widget.hintText.toLowerCase().contains('classroom');
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : isClassroom
        ? _localSelectedItems.join(', ')
        : '${_localSelectedItems.length} $displaySuffix';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: widget.label!),
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        if (widget.label != null)
          SizedBox(height: widget.labelBottomSpacing ?? 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _fieldKey,
            onTap: _toggleDropdown,
            child: Container(
              height: 40,
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: _localSelectedItems.isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    isDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
