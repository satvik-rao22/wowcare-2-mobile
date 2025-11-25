import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class TagMultiSelectWidget extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(List<String>) onSelectionChanged;
  final String label;
  final bool isRequired;
  final String? errorText;

  const TagMultiSelectWidget({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onSelectionChanged,
    this.label = "Select Tags",
    this.isRequired = true,
    this.errorText,
  });

  @override
  State<TagMultiSelectWidget> createState() => _TagMultiSelectWidgetState();
}

class _TagMultiSelectWidgetState extends State<TagMultiSelectWidget> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _fieldKey = GlobalKey();


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
    final RenderBox? box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset position = box.localToGlobal(Offset.zero);
    final double fieldWidth = box.size.width;

    String searchQuery = "";
    List<String> filteredTags = List.from(widget.availableTags);
    List<String> localSelected = List.from(widget.selectedTags);

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
            top: position.dy - 320,
            width: fieldWidth,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    filteredTags = widget.availableTags
                        .where((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()))
                        .toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search tags",
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (val) => setOverlayState(() => searchQuery = val),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = filteredTags[index];
                              final isSelected = localSelected.contains(tag);

                              return InkWell(
                                onTap: () {
                                  setOverlayState(() {
                                    if (isSelected) {
                                      localSelected.remove(tag);
                                    } else {
                                      localSelected.add(tag);
                                    }
                                    widget.onSelectionChanged(List.from(localSelected));
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      GradientCheckbox(value: isSelected),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontFamily: "Manrope",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xff573353),
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
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manpore",
              fontWeight: FontWeight.w400,
              color: const Color(0xff573353),
            ),
            children: [
              TextSpan(text: widget.label),
              if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Main field with chips
        GestureDetector(
          key: _fieldKey,
          onTap: _toggleDropdown,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isTablet ? 20 : 16,
              vertical: responsive.isTablet ? 16 : 12,
            ),
            // decoration: BoxDecoration(
            //   color: Colors.white,
            //   border: Border.all(
            //     color: widget.errorText != null ? Colors.red : const Color(0x66573353),
            //   ),
            //   borderRadius: BorderRadius.circular(responsive.isTablet ? 12 : 10),
            // ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                if (widget.selectedTags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Select tags",
                      style: TextStyle(color: Color(0xff573353), fontSize: 14),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.selectedTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getTagBackgroundColor(tag),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: TextStyle(
                                color: _getTagTextColor(tag),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                final newList = widget.selectedTags.where((t) => t != tag).toList();
                                widget.onSelectionChanged(newList);
                              },
                              child: Icon(Icons.close, size: 16, color: _getTagTextColor(tag)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    _isDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff573353),
                    size: responsive.isTablet ? 28 : 24,
                  ),
                ),
              ],
            ),
          ),
        ),


        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
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
        border: Border.all(color: value ? Colors.transparent : Colors.grey, width: 2),
        gradient: value ? AppColors.buildPrimaryGradient() : null,
      ),
      child: value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }
}