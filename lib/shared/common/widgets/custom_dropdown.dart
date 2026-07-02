// import 'package:flutter/material.dart';
// import 'package:schoolerp/core/res/colors.dart';

// class CustomDropdown extends StatefulWidget {
//   const CustomDropdown({
//     super.key,
//     this.label,
//     required this.hintText,
//     required this.items,
//     this.isField = true,
//     this.isEnabled = true,
//     this.border,
//     this.onSelect,
//     this.selectedItem, // New parameter for the selected item
//       this.controller,
//       this.value,
//   });

//   final String? label;
//   final String hintText;
//   final List<String> items;
//   final bool isField;
//   final bool isEnabled;
//   final InputBorder? border;
//   final ValueChanged<String?>? onSelect;
//   final String? selectedItem; // New parameter for the selected item
//    final TextEditingController? controller;
//     final String? value;

//   @override
//   State<CustomDropdown> createState() => _CustomDropdownState();
// }

// class _CustomDropdownState extends State<CustomDropdown> {
//   String? selectedItem; // Local state for the selected item

//   @override
//   void initState() {
//     super.initState();
//     selectedItem = widget.selectedItem; // Initialize with the selected item
//   }

//   @override
//   Widget build(BuildContext context) {
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
//         if (widget.label != null) const SizedBox(height: 12),
//         Container(
//           constraints: BoxConstraints(minHeight: widget.isField ? 40 : 30),
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8F7FA),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: PopupMenuButton<String>(
//             enabled: widget.isEnabled,
//             onSelected: (value) {
//               setState(() {
//                 selectedItem = value; // Update the selected item
//               });
//               // Call the onSelect callback if it's provided
//               if (widget.onSelect != null) {
//                 widget.onSelect!(value);
//               }
//             },
//             itemBuilder: (BuildContext context) {
//               return widget.items.map((String item) {
//                 return PopupMenuItem<String>(
//                   value: item,
//                   child: Text(
//                     item,
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: widget.isField ? 15 : 13,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 );
//               }).toList();
//             },
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Text(
//                       selectedItem ?? widget.hintText,
//                       style: TextStyle(
//                         color: widget.isEnabled
//                             ? AppColors.primaryColor.withValues(alpha: 0.6)
//                             : AppColors.primaryColor,
//                         fontSize: widget.isField ? 14 : 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   if (widget.isEnabled)
//                     const Icon(
//                       Icons.keyboard_arrow_down,
//                       color: AppColors.primaryColor,
//                       size: 24,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    this.initialValue,
    this.isField = true,
    this.isEnabled = true,
    this.border,
    this.onSelect,
    this.selectedItem, // New parameter for the selected item
    this.controller,
    this.labelStyle,
    this.showAsterisk = true,
    this.labelBottomSpacing,
    this.fieldHeight,
    this.selectedTextStyle,
    this.popupItemTextStyle,
    this.isRequired = false,
    this.contentPadding,
    this.height = null,
    this.leadingIcon,

    /// When true (default), [hintText] is the first menu item; choosing it clears the selection.
    /// Set false when a value must always stay chosen (e.g. parent global child picker).
    this.prependHintAsSelectableItem = true,

    /// Shows a search box at the top of the popup that filters [items] as you
    /// type. Off by default — opt in per-usage (e.g. the existing-parent picker).
    this.enableSearch = false,
  });

  final String? label;
  final String hintText;
  final bool isRequired;
  final List<String> items;
  final bool isField;
  final bool isEnabled;
  final InputBorder? border;
  final ValueChanged<String?>? onSelect;
  final String? selectedItem; // New parameter for the selected item
  final String? initialValue;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final bool showAsterisk;
  final double? labelBottomSpacing;
  final double? fieldHeight;
  final TextStyle? selectedTextStyle;
  final TextStyle? popupItemTextStyle;
  final EdgeInsets? contentPadding;
  final double? height;

  /// Optional leading widget (e.g. an icon) shown before the text.
  final Widget? leadingIcon;
  final bool prependHintAsSelectableItem;
  final bool enableSearch;

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedItem; // Local state for the selected item

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItem; // Initialize with the selected item
  }

  @override
  void didUpdateWidget(CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the selectedItem if the widget's selectedItem changes
    if (oldWidget.selectedItem != widget.selectedItem) {
      setState(() {
        selectedItem = widget.selectedItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> displayItems = widget.prependHintAsSelectableItem
        ? <String>[widget.hintText, ...widget.items]
        : List<String>.from(widget.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: (widget.labelStyle?.color ?? AppColors.primaryColor),
                fontSize: widget.labelStyle?.fontSize ?? 13,
                fontWeight: widget.labelStyle?.fontWeight ?? FontWeight.w400,
                fontFamily: widget.labelStyle?.fontFamily ?? 'Manrope',
              ),
              children: [
                TextSpan(text: widget.label!),
                if (widget.showAsterisk)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        if (widget.label != null)
          SizedBox(height: widget.labelBottomSpacing ?? 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(
                minHeight:
                    widget.height ??
                    widget.fieldHeight ??
                    (widget.isField ? 40 : 30),
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
                //color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              // Ensure dropdown interactions never trigger the software keyboard.
              // On some screens, after selecting an item the focus returns to a text field,
              // which causes the keyboard to pop open unexpectedly (e.g., State/Country).
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: PopupMenuButton<String>(
                    enabled: widget.isEnabled,
                    padding: EdgeInsets.zero,
                    position: PopupMenuPosition.under,
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (widget.prependHintAsSelectableItem &&
                            value == widget.hintText) {
                          selectedItem = null;
                        } else {
                          selectedItem = value;
                        }
                      });

                      // Call the onSelect callback if it's provided
                      if (widget.onSelect != null) {
                        widget.onSelect!(selectedItem);
                      }

                      // After the popup closes, ensure we don't restore focus to a text field.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      });
                    },
                    onCanceled: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          enabled: false,
                          padding: EdgeInsets.zero,
                          child: _DropdownMenuPanel(
                            items: displayItems,
                            maxWidth: constraints.maxWidth,
                            enableSearch: widget.enableSearch,
                            isField: widget.isField,
                            itemTextStyle: widget.popupItemTextStyle,
                          ),
                        ),
                      ];
                    },
                    child: Padding(
                      padding:
                          widget.contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            widget.leadingIcon!,
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              selectedItem ?? widget.hintText,
                              style:
                                  widget.selectedTextStyle ??
                                  TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: selectedItem != null
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selectedItem != null
                                        ? const Color(0xff573353)
                                        : Colors.grey[600],
                                    height: 19 / 14,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (widget.isEnabled)
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Scrollable popup body for [CustomDropdown]. When [enableSearch] is on it adds
/// a live filter box at the top; otherwise it is just the plain item list.
/// Stateful so the search query can filter the list inside the popup route
/// (the parent dropdown's State does not rebuild the open popup).
class _DropdownMenuPanel extends StatefulWidget {
  const _DropdownMenuPanel({
    required this.items,
    required this.maxWidth,
    required this.enableSearch,
    required this.isField,
    this.itemTextStyle,
  });

  final List<String> items;
  final double maxWidth;
  final bool enableSearch;
  final bool isField;
  final TextStyle? itemTextStyle;

  @override
  State<_DropdownMenuPanel> createState() => _DropdownMenuPanelState();
}

class _DropdownMenuPanelState extends State<_DropdownMenuPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered = widget.items;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
              .where((item) => item.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.enableSearch ? 320 : 240,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: _onQueryChanged,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: Color(0xff573353),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.themeColor),
                  ),
                ),
              ),
            ),
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No matches',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: AppColors.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 4,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              item,
                              style: widget.itemTextStyle ??
                                  TextStyle(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.9),
                                    fontSize: widget.isField ? 17 : 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
