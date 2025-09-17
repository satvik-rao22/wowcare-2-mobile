import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:schoolerp/core/common/widgets/custom_checkbox.dart';
import 'package:schoolerp/core/res/colors.dart';

class CustomMultiSelectDropdown extends StatefulWidget {
  final String? label;
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.label,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdown> createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  late List<String> _localSelectedItems;
  bool isDropdownOpen = false;

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
    }
    return 'items';
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
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
              fontWeight: FontWeight.w400,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 8),
        Container(
          height: 40,
          width: widget.width,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F7FA),
              hintText: widget.hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.transparent),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 24,
            elevation: 2,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
            dropdownColor: Colors.white,
            items: widget.items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                enabled: false,
                child: StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setMenuItemState) {
                    final isSelected = _localSelectedItems.contains(item);
                    return InkWell(
                      onTap: () {
                        setMenuItemState(() {
                          if (isSelected) {
                            _localSelectedItems.remove(item);
                          } else {
                            _localSelectedItems.add(item);
                          }
                        });
                        setState(() {});
                        widget.onChanged(_localSelectedItems);
                      },
                      child: Row(
                        children: [
                          CustomCheckbox(
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setMenuItemState(() {
                                if (checked == true) {
                                  _localSelectedItems.add(item);
                                } else {
                                  _localSelectedItems.remove(item);
                                }
                              });
                              setState(() {});
                              widget.onChanged(_localSelectedItems);
                            },
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
            onChanged: (_) {},
            isExpanded: true,
            hint: Text(
              displayText,
              style: TextStyle(
                color: _localSelectedItems.isEmpty
                    ? Colors.grey[600]
                    : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
