import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/classroom_visibility.dart';

class ClassroomDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final Function(String) onChanged;

  const ClassroomDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  State<ClassroomDropdown> createState() => _ClassroomDropdownState();
}

class _ClassroomDropdownState extends State<ClassroomDropdown> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  late OverlayEntry _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.only(left: 4),
          decoration: const BoxDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    letterSpacing: 18 * (-3 / 100),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _overlayEntry.remove();
      setState(() => _isOpen = false);
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
      setState(() => _isOpen = true);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    final visibleItems = widget.items
        .where(isSelectableClassroomName)
        .toList(growable: false);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _toggleDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height,
            width: 200,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(5, size.height + 5),
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          visibleItems[index],
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          widget.onChanged(visibleItems[index]);
                          _toggleDropdown();
                        },
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
}
