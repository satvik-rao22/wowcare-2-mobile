import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class ClassroomSelectionWidgetExact extends StatefulWidget {
  final String? primaryClassroom;
  final List<String> allowedClassrooms;
  final List<String> availableClassrooms;
  final Function(String?) onPrimaryClassroomChanged;
  final Function(List<String>) onAllowedClassroomsChanged;
  final bool isRequired;
  final String? primaryClassroomError;
  final String? allowedClassroomsError;
  final bool showPrimaryClassroom;

  /// When false, shows greyish disabled state; values remain visible but not editable.
  final bool isEnabled;

  const ClassroomSelectionWidgetExact({
    super.key,
    required this.primaryClassroom,
    required this.allowedClassrooms,
    required this.availableClassrooms,
    required this.onPrimaryClassroomChanged,
    required this.onAllowedClassroomsChanged,
    this.isRequired = true,
    this.primaryClassroomError,
    this.allowedClassroomsError,
    this.showPrimaryClassroom = true,
    this.isEnabled = true,
  });

  @override
  State<ClassroomSelectionWidgetExact> createState() =>
      _ClassroomSelectionWidgetExactState();
}

class _ClassroomSelectionWidgetExactState
    extends State<ClassroomSelectionWidgetExact> {
  bool _isPrimaryDropdownOpen = false;
  bool _isAllowedDropdownOpen = false;
  OverlayEntry? _primaryOverlayEntry;
  OverlayEntry? _allowedOverlayEntry;
  final GlobalKey _primaryDropdownKey = GlobalKey();
  final GlobalKey _allowedDropdownKey = GlobalKey();

  // Function to generate different colors for each classroom
  Color _getClassroomColor(String classroom) {
    // Use profile avatar colors for chips with transparency
    final hash = classroom.hashCode;
    final baseColor = AppColors
        .profileAvatarColors[hash.abs() % AppColors.profileAvatarColors.length];
    return baseColor.withValues(
      alpha: 0.2,
    ); // Make it lighter for chip background
  }

  @override
  void dispose() {
    _primaryOverlayEntry?.remove();
    _allowedOverlayEntry?.remove();
    super.dispose();
  }

  void _togglePrimaryDropdown() {
    if (!widget.isEnabled) return;
    if (_isPrimaryDropdownOpen) {
      _closePrimaryDropdown();
    } else {
      _closeAllowedDropdown();
      _openPrimaryDropdown();
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

  void _closeAllowedDropdown() {
    _allowedOverlayEntry?.remove();
    _allowedOverlayEntry = null;
    setState(() {
      _isAllowedDropdownOpen = false;
    });
  }

  OverlayEntry _createPrimaryOverlayEntry() {
    final RenderBox renderBox =
        _primaryDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(8),
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
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x1A573353)
                          : AppColors.whiteColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            classroom,
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
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
    );
  }

  void _showAllowedDropdown(
    BuildContext context,
    Offset position,
    double fieldWidth,
    double fieldHeight,
  ) {
    if (_allowedOverlayEntry != null) {
      _allowedOverlayEntry!.remove();
      _allowedOverlayEntry = null;
      _isAllowedDropdownOpen = false;
      return;
    }

    String searchQuery = "";
    List<String> filteredClassrooms = List.from(widget.availableClassrooms);
    List<String> localAllowedClassrooms = List.from(widget.allowedClassrooms);

    // Calculate the height of the dropdown based on the number of items
    double dropdownHeight =
        filteredClassrooms.length * 56.0 +
        48.0; // 56 for each item + 48 for search bar
    dropdownHeight = dropdownHeight.clamp(
      0,
      MediaQuery.of(context).size.height * 0.3,
    ); // Limit to 30% of screen height

    _allowedOverlayEntry = OverlayEntry(
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            if (_isAllowedDropdownOpen) {
              setState(() {
                _allowedOverlayEntry?.remove();
                _allowedOverlayEntry = null;
                _isAllowedDropdownOpen = false;
              });
              return false; // Prevent navigation
            }
            return true;
          },
          child: Stack(
            children: [
              ModalBarrier(
                dismissible: true,
                color: Colors.transparent,
                onDismiss: () {
                  setState(() {
                    _allowedOverlayEntry?.remove();
                    _allowedOverlayEntry = null;
                    _isAllowedDropdownOpen = false;
                  });
                },
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _allowedOverlayEntry?.remove();
                      _allowedOverlayEntry = null;
                      _isAllowedDropdownOpen = false;
                    });
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Positioned(
                left: position.dx,
                top: position.dy - dropdownHeight, // Position above the field
                width: fieldWidth,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setOverlayState) {
                      filteredClassrooms = widget.availableClassrooms
                          .where(
                            (c) => c.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();
                      // Recalculate height based on filtered items
                      double updatedHeight =
                          filteredClassrooms.length * 56.0 + 48.0;
                      updatedHeight = updatedHeight.clamp(
                        0,
                        MediaQuery.of(context).size.height * 0.3,
                      );

                      return Container(
                        height: updatedHeight,
                        decoration: const BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: "Search...",
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                onChanged: (value) {
                                  setOverlayState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final scrollController = ScrollController();
                                  return Scrollbar(
                                    thumbVisibility: true,
                                    controller: scrollController,
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      child: Column(
                                        children: filteredClassrooms.map((
                                          classroom,
                                        ) {
                                          final isChecked =
                                              localAllowedClassrooms.contains(
                                                classroom,
                                              );
                                          return InkWell(
                                            onTap: () {
                                              setOverlayState(() {
                                                if (isChecked) {
                                                  localAllowedClassrooms.remove(
                                                    classroom,
                                                  );
                                                  widget
                                                      .onAllowedClassroomsChanged(
                                                        List.from(
                                                          localAllowedClassrooms,
                                                        ),
                                                      );
                                                } else {
                                                  localAllowedClassrooms.add(
                                                    classroom,
                                                  );
                                                  widget
                                                      .onAllowedClassroomsChanged(
                                                        List.from(
                                                          localAllowedClassrooms,
                                                        ),
                                                      );
                                                }
                                              });
                                            },
                                            child: Container(
                                              height: 56,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              decoration: const BoxDecoration(
                                                color: AppColors.whiteColor,
                                              ),
                                              child: Row(
                                                children: [
                                                  GradientCheckbox(
                                                    value: isChecked,
                                                    onChanged: null,
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      classroom,
                                                      style: const TextStyle(
                                                        fontFamily: AppFonts.body,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color(
                                                          0xff573353,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
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
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_allowedOverlayEntry!);
    setState(() {
      _isAllowedDropdownOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double labelFontSize = responsive.labelFontSize;
    final double inputFontSize = responsive.inputFontSize;
    final double inputFieldHeight = responsive.inputFieldHeight;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Classroom Section
        if (widget.showPrimaryClassroom) ...[
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: labelFontSize,
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryColor,
              ),
              children: [
                const TextSpan(text: 'Primary Classroom'),
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: MaterialHues.red),
                  ),
              ],
            ),
          ),
          SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
          GestureDetector(
            key: _primaryDropdownKey,
            onTap: _togglePrimaryDropdown,
            child: Container(
              height: inputFieldHeight,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 20.0 : 16.0,
                vertical: responsive.isTablet ? 12.0 : 10.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.primaryClassroomError != null
                      ? MaterialHues.red
                      : AppPalette.borderField,
                ),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 12.0 : 8.0,
                ),
                color: widget.isEnabled ? AppColors.whiteColor : MaterialHues.grey200,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.primaryClassroom ?? 'Select Primary Classroom',
                      style: TextStyle(
                        color: widget.primaryClassroom == null
                            ? AppColors.primaryColor
                            : AppColors.blackColor,
                        fontSize: inputFontSize,
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.isEnabled)
                    Icon(
                      _isPrimaryDropdownOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                      size: responsive.isTablet ? 28.0 : 24.0,
                    ),
                ],
              ),
            ),
          ),
          if (widget.primaryClassroomError != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.primaryClassroomError!,
              style: const TextStyle(
                color: MaterialHues.red,
                fontSize: 12,
                fontFamily: AppFonts.body,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],

        // Allowed Classrooms Section - Exact UI from WowInventory
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: labelFontSize,
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: const [
              TextSpan(text: "Allowed Classrooms"),
              TextSpan(
                text: ' *',
                style: TextStyle(color: MaterialHues.red),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
        Builder(
          builder: (context) {
            return Focus(
              canRequestFocus: false,
              child: GestureDetector(
                key: _allowedDropdownKey,
                onTap: () {
                  if (!widget.isEnabled) return;
                  // Unfocus any active text field and disable keyboard
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();

                  if (widget.availableClassrooms.isEmpty) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'No classrooms available',
                      isWarning: true,
                    );
                    return;
                  }

                  final RenderBox? box =
                      _allowedDropdownKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (box == null) {
                    return;
                  }

                  final Offset position = box.localToGlobal(Offset.zero);
                  final double fieldWidth = box.size.width;
                  final double fieldHeight = box.size.height;

                  _showAllowedDropdown(
                    context,
                    position,
                    fieldWidth,
                    fieldHeight,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.isTablet ? 20.0 : 16.0,
                    vertical: responsive.isTablet ? 12.0 : 10.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.allowedClassroomsError != null
                          ? MaterialHues.red
                          : AppPalette.borderField,
                    ),
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 12.0 : 8.0,
                    ),
                    color: widget.isEnabled
                        ? AppColors.whiteColor
                        : MaterialHues.grey200,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: widget.allowedClassrooms.isEmpty
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: responsive.isTablet ? 4.0 : 2.0,
                                ),
                                child: Text(
                                  "Select",
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: inputFontSize,
                                    fontFamily: AppFonts.body,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.only(
                                  right: responsive.isTablet ? 40.0 : 32.0,
                                ),
                                child: Wrap(
                                  spacing: responsive.isTablet ? 12.0 : 8.0,
                                  runSpacing: responsive.isTablet ? 12.0 : 8.0,
                                  children: widget.allowedClassrooms.map((
                                    classroom,
                                  ) {
                                    final chipColor = _getClassroomColor(
                                      classroom,
                                    );
                                    return Chip(
                                      label: Text(
                                        classroom,
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: inputFontSize,
                                          fontFamily: AppFonts.body,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      deleteIcon: Icon(
                                        Icons.close,
                                        size: responsive.isTablet ? 20.0 : 18.0,
                                        color: AppColors.primaryColor,
                                      ),
                                      backgroundColor: chipColor,
                                      onDeleted: widget.isEnabled
                                          ? () {
                                              final newAllowed =
                                                  List<String>.from(
                                                    widget.allowedClassrooms,
                                                  );
                                              newAllowed.remove(classroom);
                                              widget.onAllowedClassroomsChanged(
                                                newAllowed,
                                              );
                                              if (widget.primaryClassroom ==
                                                  classroom) {
                                                widget
                                                    .onPrimaryClassroomChanged(
                                                      null,
                                                    );
                                              }
                                            }
                                          : null,
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                      if (widget.isEnabled)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            _isAllowedDropdownOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryColor,
                            size: responsive.isTablet ? 28.0 : 24.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.allowedClassroomsError != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.allowedClassroomsError!,
            style: const TextStyle(
              color: MaterialHues.red,
              fontSize: 12,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ],
    );

    if (!widget.isEnabled) {
      content = Opacity(opacity: 0.7, child: AbsorbPointer(child: content));
    }
    return content;
  }
}

class GradientCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const GradientCheckbox({Key? key, required this.value, this.onChanged})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? Colors.transparent : MaterialHues.grey500,
          width: 2,
        ),
        gradient: value ? AppColors.buildPrimaryGradient() : null,
        color: value ? null : Colors.transparent,
      ),
      child: value
          ? const Icon(Icons.check, size: 18, color: AppColors.whiteColor)
          : null,
    );
  }
}
