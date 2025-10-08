import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

class ClassroomSelectionWidget extends StatefulWidget {
  final String? primaryClassroom;
  final List<String> allowedClassrooms;
  final List<String> availableClassrooms;
  final Function(String?) onPrimaryClassroomChanged;
  final Function(List<String>) onAllowedClassroomsChanged;
  final bool isRequired;
  final String? primaryClassroomError;
  final String? allowedClassroomsError;

  const ClassroomSelectionWidget({
    super.key,
    required this.primaryClassroom,
    required this.allowedClassrooms,
    required this.availableClassrooms,
    required this.onPrimaryClassroomChanged,
    required this.onAllowedClassroomsChanged,
    this.isRequired = true,
    this.primaryClassroomError,
    this.allowedClassroomsError,
  });

  @override
  State<ClassroomSelectionWidget> createState() => _ClassroomSelectionWidgetState();
}

class _ClassroomSelectionWidgetState extends State<ClassroomSelectionWidget> {
  bool _isPrimaryDropdownOpen = false;
  bool _isAllowedDropdownOpen = false;
  OverlayEntry? _primaryOverlayEntry;
  OverlayEntry? _allowedOverlayEntry;
  final LayerLink _primaryLayerLink = LayerLink();
  final LayerLink _allowedLayerLink = LayerLink();
  final GlobalKey _primaryDropdownKey = GlobalKey();
  final GlobalKey _allowedDropdownKey = GlobalKey();

  @override
  void dispose() {
    _primaryOverlayEntry?.remove();
    _allowedOverlayEntry?.remove();
    super.dispose();
  }

  void _togglePrimaryDropdown() {
    if (_isPrimaryDropdownOpen) {
      _closePrimaryDropdown();
    } else {
      _closeAllowedDropdown(); // Close other dropdown
      _openPrimaryDropdown();
    }
  }

  void _toggleAllowedDropdown() {
    if (_isAllowedDropdownOpen) {
      _closeAllowedDropdown();
    } else {
      _closePrimaryDropdown(); // Close other dropdown
      _openAllowedDropdown();
    }
  }

  void _openPrimaryDropdown() {
    _primaryOverlayEntry = _createPrimaryOverlayEntry();
    Overlay.of(context).insert(_primaryOverlayEntry!);
    setState(() {
      _isPrimaryDropdownOpen = true;
    });
  }

  void _closePrimaryDropdown() {
    _primaryOverlayEntry?.remove();
    _primaryOverlayEntry = null;
    setState(() {
      _isPrimaryDropdownOpen = false;
    });
  }

  void _openAllowedDropdown() {
    _allowedOverlayEntry = _createAllowedOverlayEntry();
    Overlay.of(context).insert(_allowedOverlayEntry!);
    setState(() {
      _isAllowedDropdownOpen = true;
    });
  }

  void _closeAllowedDropdown() {
    _allowedOverlayEntry?.remove();
    _allowedOverlayEntry = null;
    setState(() {
      _isAllowedDropdownOpen = false;
    });
  }

  OverlayEntry _createPrimaryOverlayEntry() {
    final RenderBox renderBox = _primaryDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _primaryLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderColor),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableClassrooms.length,
                itemBuilder: (context, index) {
                  final classroom = widget.availableClassrooms[index];
                  final isSelected = widget.primaryClassroom == classroom;
                  
                  return InkWell(
                    onTap: () {
                      widget.onPrimaryClassroomChanged(classroom);
                      _closePrimaryDropdown();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.lightBlueProgressBar.withOpacity(0.1) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              classroom,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Manrope',
                                color: isSelected ? AppColors.primaryColor : Colors.black,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _createAllowedOverlayEntry() {
    final RenderBox renderBox = _allowedDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _allowedLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderColor),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableClassrooms.length,
                itemBuilder: (context, index) {
                  final classroom = widget.availableClassrooms[index];
                  final isSelected = widget.allowedClassrooms.contains(classroom);
                  
                  return InkWell(
                    onTap: () {
                      final newAllowed = List<String>.from(widget.allowedClassrooms);
                      if (isSelected) {
                        newAllowed.remove(classroom);
                      } else {
                        newAllowed.add(classroom);
                      }
                      widget.onAllowedClassroomsChanged(newAllowed);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.lightBlueProgressBar.withOpacity(0.1) : null,
                      ),
                      child: Row(
                        children: [
                          CustomCheckbox(
                            label: '',
                            value: isSelected,
                            onChanged: (value) {
                              final newAllowed = List<String>.from(widget.allowedClassrooms);
                              if (value == true) {
                                if (!newAllowed.contains(classroom)) {
                                  newAllowed.add(classroom);
                                }
                              } else {
                                newAllowed.remove(classroom);
                              }
                              widget.onAllowedClassroomsChanged(newAllowed);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              classroom,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Manrope',
                                color: isSelected ? AppColors.primaryColor : Colors.black,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double labelFontSize = responsive.labelFontSize;
    final double inputFontSize = responsive.inputFontSize;
    final double inputFieldHeight = responsive.inputFieldHeight;
    final bool isTablet = responsive.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Classroom Section
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              const TextSpan(text: 'Primary Classroom'),
              if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _primaryLayerLink,
          child: GestureDetector(
            key: _primaryDropdownKey,
            onTap: _togglePrimaryDropdown,
            child: Container(
              height: inputFieldHeight,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 16.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.primaryClassroomError != null 
                    ? Colors.red 
                    : const Color(0x66573353),
                ),
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.primaryClassroom ?? 'Select Primary Classroom',
                      style: TextStyle(
                        color: widget.primaryClassroom == null ? Colors.grey : Colors.black,
                        fontSize: inputFontSize,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  Icon(
                    _isPrimaryDropdownOpen 
                      ? Icons.keyboard_arrow_up_rounded 
                      : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff573353),
                    size: isTablet ? 28.0 : 24.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.primaryClassroomError != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.primaryClassroomError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'Manrope',
            ),
          ),
        ],
        const SizedBox(height: 16),
        
        // Allowed Classrooms Section
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              const TextSpan(text: 'Allowed Classrooms'),
              if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _allowedLayerLink,
          child: GestureDetector(
            key: _allowedDropdownKey,
            onTap: _toggleAllowedDropdown,
            child: Container(
              height: inputFieldHeight,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 16.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.allowedClassroomsError != null 
                    ? Colors.red 
                    : const Color(0x66573353),
                ),
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.allowedClassrooms.isEmpty
                        ? 'Select Allowed Classrooms'
                        : '${widget.allowedClassrooms.length} Classroom(s) selected',
                      style: TextStyle(
                        color: widget.allowedClassrooms.isEmpty ? Colors.grey : Colors.black,
                        fontSize: inputFontSize,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  Icon(
                    _isAllowedDropdownOpen 
                      ? Icons.keyboard_arrow_up_rounded 
                      : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff573353),
                    size: isTablet ? 28.0 : 24.0,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.allowedClassroomsError != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.allowedClassroomsError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontFamily: 'Manrope',
            ),
          ),
        ],
        
        // Selected Classrooms Display
        if (widget.allowedClassrooms.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.allowedClassrooms.map((classroom) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueProgressBar.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBlueProgressBar),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      classroom,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final newAllowed = List<String>.from(widget.allowedClassrooms);
                        newAllowed.remove(classroom);
                        widget.onAllowedClassroomsChanged(newAllowed);
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
