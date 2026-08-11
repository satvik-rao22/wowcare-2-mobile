// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:wowcare/app/theme/colors.dart';

// class CustomMultiSelectDropdown extends StatefulWidget {
//   final String? label;
//   final String? suffix;
//   final String hintText;
//   final List<String> items;
//   final List<String> selectedItems;
//   final ValueChanged<List<String>> onChanged;
//   final bool isField;
//   final bool showSelectAll;
//   final double? width;
//   final double gapHeight;
//   final double maxDropdownHeight;

//   const CustomMultiSelectDropdown({
//     Key? key,
//     required this.hintText,
//     required this.items,
//     required this.selectedItems,
//     required this.onChanged,
//     this.label,
//     this.suffix,
//     this.isField = false,
//     this.showSelectAll = true,
//     this.width,

//     /// Extra spacing between the field and dropdown (in addition to field height).
//     this.gapHeight = 6,
//     this.maxDropdownHeight = 250,
//   }) : super(key: key);

//   @override
//   State<CustomMultiSelectDropdown> createState() =>
//       _CustomMultiSelectDropdownState();
// }

// class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
//   late List<String> _localSelectedItems;
//   bool isDropdownOpen = false;
//   final LayerLink _layerLink = LayerLink();
//   final GlobalKey _fieldKey = GlobalKey();
//   OverlayEntry? _overlayEntry;
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _localSelectedItems = List.from(widget.selectedItems);
//     _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
//   }

//   @override
//   void didUpdateWidget(CustomMultiSelectDropdown oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (!listEquals(oldWidget.items, widget.items) ||
//         !listEquals(oldWidget.selectedItems, widget.selectedItems)) {
//       setState(() {
//         _localSelectedItems = List.from(widget.selectedItems);
//         _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
//       });
//     }
//   }

//   String get displaySuffix {
//     if (widget.hintText.toLowerCase() == 'status') {
//       return 'status';
//     } else if (widget.hintText.toLowerCase() == 'tags') {
//       return 'tag${_localSelectedItems.length > 1 ? 's' : ''}';
//     } else if (widget.suffix?.toLowerCase() == 'category') {
//       return '${_localSelectedItems.length > 1 ? 'categories' : 'category'}';
//     }
//     return 'items';
//   }

//   void _toggleDropdown() {
//     if (isDropdownOpen) {
//       _closeDropdown();
//     } else {
//       _openDropdown();
//     }
//   }

//   void _openDropdown() {
//     _overlayEntry = _createOverlayEntry();
//     Overlay.of(context).insert(_overlayEntry!);
//     setState(() {
//       isDropdownOpen = true;
//     });
//   }

//   void _closeDropdown({bool updateState = true}) {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
// <<<<<<< HEAD
//     if (mounted && !_isDisposed) {
// =======
//     if (updateState && mounted) {
// >>>>>>> origin/develop
//       setState(() {
//         isDropdownOpen = false;
//       });
//     }
//   }

//   OverlayEntry _createOverlayEntry() {
//     final renderObject =
//         _fieldKey.currentContext?.findRenderObject() ??
//         context.findRenderObject();
//     final renderBox = renderObject as RenderBox;
//     final size = renderBox.size;

//     return OverlayEntry(
//       builder: (context) => Stack(
//         children: [
//           // Barrier to close dropdown when tapping outside
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: _closeDropdown,
//               child: Container(color: Colors.transparent),
//             ),
//           ),
//           // Dropdown content
//           Positioned(
//             width: size.width,
//             child: CompositedTransformFollower(
//               link: _layerLink,
//               showWhenUnlinked: false,
//               //offset: Offset(0.0, size.height + 5.0),
//               offset: Offset(0.0, size.height + widget.gapHeight),
//               child: Material(
//                 elevation: 8.0,
//                 borderRadius: BorderRadius.circular(8),
//                 shadowColor: Colors.black26,
//                 child: Container(
//                   constraints: BoxConstraints(
//                     maxHeight: widget.maxDropdownHeight,
//                     minWidth: 120,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.shade300, width: 1),
//                   ),
//                   child: StatefulBuilder(
//                     builder:
//                         (BuildContext context, StateSetter setOverlayState) {
//                           final List<String> effectiveItems =
//                               widget.showSelectAll
//                               ? ['Select All', ...widget.items]
//                               : widget.items;

//                           return ListView.builder(
//                             padding: EdgeInsets.zero,
//                             shrinkWrap: true,
//                             itemCount: effectiveItems.length,
//                             itemBuilder: (context, index) {
//                               final item = effectiveItems[index];
//                               final bool isSelectAllItem =
//                                   widget.showSelectAll && index == 0;
//                               final bool isSelected = isSelectAllItem
//                                   ? _localSelectedItems.length ==
//                                         widget.items.length
//                                   : _localSelectedItems.contains(item);

//                               return InkWell(
//                                 onTap: () {
//                                   setOverlayState(() {
//                                     if (isSelectAllItem) {
//                                       if (isSelected) {
//                                         _localSelectedItems.clear();
//                                       } else {
//                                         _localSelectedItems = List.from(
//                                           widget.items,
//                                         );
//                                       }
//                                     } else {
//                                       if (isSelected) {
//                                         _localSelectedItems.remove(item);
//                                       } else {
//                                         _localSelectedItems.add(item);
//                                       }
//                                     }
//                                   });
//                                   setState(() {}); // Update main widget
//                                   widget.onChanged(_localSelectedItems);
//                                 },
//                                 hoverColor: Colors.grey.shade100,
//                                 child: Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.transparent,
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Container(
//                                         width: 20,
//                                         height: 20,
//                                         decoration: BoxDecoration(
//                                           border: Border.all(
//                                             color: isSelected
//                                                 ? AppColors.themeColor
//                                                 : Colors.grey.shade400,
//                                             width: 2,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             4,
//                                           ),
//                                           color: isSelected
//                                               ? AppColors.themeColor
//                                               : Colors.transparent,
//                                         ),
//                                         child: isSelected
//                                             ? const Icon(
//                                                 Icons.check,
//                                                 size: 14,
//                                                 color: Colors.white,
//                                               )
//                                             : null,
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Text(
//                                           item,
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.black87,
//                                             fontWeight: FontWeight.w400,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
// <<<<<<< HEAD
//     _isDisposed = true;
//     _closeDropdown();
// =======
//     // Do not call setState while disposing.
//     _closeDropdown(updateState: false);
// >>>>>>> origin/develop
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String displayText = _localSelectedItems.isEmpty
//         ? widget.hintText
//         : '${_localSelectedItems.length} $displaySuffix';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.label != null)
//           Text(
//             widget.label!,
//             style: TextStyle(
//               color: AppColors.primaryColor.withValues(alpha: 0.5),
//               fontSize: 13,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         if (widget.label != null) const SizedBox(height: 8),
//         CompositedTransformTarget(
//           link: _layerLink,
//           child: GestureDetector(
//             key: _fieldKey,
//             onTap: _toggleDropdown,
//             child: Container(
//               height: 40,
//               width: widget.width,
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFB1AFE9).withValues(alpha:0.102),
//                 //color: const Color(0xFFF8F7FA),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.transparent),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       displayText,
//                       style: TextStyle(
//                         color: _localSelectedItems.isEmpty
//                             ? Colors.grey[600]
//                             : Colors.black87,
//                         fontSize: 15,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Icon(
//                     isDropdownOpen
//                         ? Icons.keyboard_arrow_up
//                         : Icons.keyboard_arrow_down,
//                     size: 24,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

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
                      final targetHeight =
                          (itemCount * _dropdownRowHeight) + searchBoxHeight;
                      final dropdownHeight =
                          targetHeight > widget.maxDropdownHeight
                          ? widget.maxDropdownHeight
                          : targetHeight;
                      return SizedBox(
                        height: dropdownHeight,
                        child: Column(
                          children: [
                            // if (widget.enableSearch)
                            //   Padding(
                            //     padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                            //     child: SizedBox(
                            //       height: 38,
                            //       child: TextField(
                            //         controller: _searchController,
                            //         onChanged: (value) {
                            //           setOverlayState(() {
                            //             _searchQuery = value;
                            //           });
                            //         },
                            //         decoration: InputDecoration(
                            //           isDense: true,
                            //           prefixIcon: const Icon(Icons.search, size: 18),
                            //           hintText: widget.searchHintText ?? 'Search',
                            //           contentPadding: const EdgeInsets.symmetric(
                            //             horizontal: 10,
                            //             vertical: 10,
                            //           ),
                            //           border: OutlineInputBorder(
                            //             borderRadius: BorderRadius.circular(8),
                            //             borderSide: BorderSide(color: Colors.grey.shade300),
                            //           ),
                            //           enabledBorder: OutlineInputBorder(
                            //             borderRadius: BorderRadius.circular(8),
                            //             borderSide: BorderSide(color: Colors.grey.shade300),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                // Always allow scrolling: rows can wrap to two
                                // lines (long student names / designations), so
                                // the fixed `_dropdownRowHeight` estimate can
                                // undercount the real content height. Gating
                                // scroll on that estimate left overflowing rows
                                // clipped and unreachable. ClampingScrollPhysics
                                // scrolls only when content exceeds the box and
                                // stays put when it fits.
                                physics: const ClampingScrollPhysics(),
                                // No fixed itemExtent: let rows size to content
                                // so long labels (e.g. "Assistant Teacher") can
                                // wrap to a second line instead of clipping.
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  if (widget.showSelectAll && index == 0) {
                                    final isAllSelected =
                                        _localSelectedItems.length ==
                                        widget.items.length;
                                    return InkWell(
                                      onTap: () {
                                        setOverlayState(() {
                                          if (isAllSelected) {
                                            _localSelectedItems.clear();
                                          } else {
                                            _localSelectedItems = List.from(
                                              widget.items,
                                            );
                                          }
                                        });
                                        setState(() {});
                                        widget.onChanged(
                                          List<String>.from(
                                            _localSelectedItems,
                                          ),
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
                                  final isSelected = _localSelectedItems
                                      .contains(item);

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
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              // Allow long designations (e.g.
                                              // "Assistant Teacher") to wrap to a
                                              // second line instead of clipping.
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
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
          Text(
            widget.label!,
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
