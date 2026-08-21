import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';

class AddEditIndividualMovementScreen extends StatefulWidget {
  const AddEditIndividualMovementScreen({
    super.key,
    required this.students,
    required this.classrooms,
    required this.existingMovements,
    this.studentNamesByCode = const <String, String>{},
    this.classroomNamesByCode = const <String, String>{},
    this.movementType = MovementType.moveToNextClassroom,
    this.initialData,
    this.isEditing = false,
    this.editingMovementId,
    this.disablePastDates = false,
    this.lockClassroomSelection = false,
  });

  /// Items are **codes**; UI can display names via [studentNamesByCode]/[classroomNamesByCode].
  final List<String> students;
  final List<String> classrooms;

  /// Full list used for duplicate detection (same student, date, from, to).
  final List<MovementItem> existingMovements;
  final Map<String, String> studentNamesByCode;
  final Map<String, String> classroomNamesByCode;
  final MovementType movementType;
  final MovementFormResult? initialData;
  final bool isEditing;
  final int? editingMovementId;
  final bool disablePastDates;
  final bool lockClassroomSelection;

  @override
  State<AddEditIndividualMovementScreen> createState() =>
      _AddEditIndividualMovementScreenState();
}

class _AddEditIndividualMovementScreenState
    extends State<AddEditIndividualMovementScreen> {
  String? _selectedStudent;
  String? _currentClassroom;
  String? _nextClassroom;
  DateTime _movementDate = AppTime.now();
  late final TextEditingController _commentController;

  String _nameForStudentCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return '';
    final name = (widget.studentNamesByCode[c] ?? '').trim();
    return name.isNotEmpty ? name : c;
  }

  String _nameForClassroomCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return '';
    final name = (widget.classroomNamesByCode[c] ?? '').trim();
    return name.isNotEmpty ? name : c;
  }

  /// Builds display-only names (no codes) while maintaining a stable mapping
  /// from display string -> code. If multiple items share the same name,
  /// suffix them as "Name (2)", "Name (3)", etc.
  ({
    List<String> items,
    Map<String, String> displayToCode,
    Map<String, String> codeToDisplay,
  })
  _buildDisplayOnlyOptions({
    required List<String> codes,
    required String Function(String code) nameForCode,
  }) {
    final counts = <String, int>{};
    final items = <String>[];
    final displayToCode = <String, String>{};
    final codeToDisplay = <String, String>{};

    for (final codeRaw in codes) {
      final code = codeRaw.trim();
      if (code.isEmpty) continue;
      final baseName = nameForCode(code).trim();
      final name = baseName.isNotEmpty ? baseName : code;

      final next = (counts[name] ?? 0) + 1;
      counts[name] = next;

      final display = next == 1 ? name : '$name ($next)';
      items.add(display);
      displayToCode[display] = code;
      codeToDisplay[code] = display;
    }

    return (
      items: items,
      displayToCode: displayToCode,
      codeToDisplay: codeToDisplay,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialData?.student;
    _currentClassroom = widget.initialData?.currentClassroom;
    _nextClassroom = widget.initialData?.nextClassroom;
    _movementDate = widget.initialData?.movementDate ?? AppTime.now();
    _commentController = TextEditingController(
      text: widget.initialData?.comment ?? '',
    );

    // Normalize for movement types where one side is expected to be empty.
    if (widget.movementType == MovementType.startSchool) {
      _currentClassroom = '';
    } else if (widget.movementType == MovementType.leaveSchool) {
      _nextClassroom = '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    final String? error =
        IndividualMovementValidators.validateMoveToNextClassroomForm(
          student: _selectedStudent,
          fromClassroom: _currentClassroom,
          toClassroom: _nextClassroom,
          movementType: widget.movementType,
          movementDate: _movementDate,
          existing: widget.existingMovements,
          excludeId: widget.editingMovementId,
        );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop(
      MovementFormResult(
        student: _selectedStudent!,
        currentClassroom: _currentClassroom!,
        nextClassroom: _nextClassroom!,
        movementDate: _movementDate,
        comment: _commentController.text.trim(),
      ),
    );
  }

  TextStyle _labelStyle(ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: Fonts.manrope,
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
  }

  Widget _commentField(ResponsiveHelper responsive) {
    final labelStyle = _labelStyle(responsive);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Comment', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _commentController,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 4,
            style: TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter Comment',
              hintStyle: labelStyle.copyWith(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    final studentOptions = _buildDisplayOnlyOptions(
      codes: widget.students,
      nameForCode: _nameForStudentCode,
    );
    final classroomOptions = _buildDisplayOnlyOptions(
      codes: widget.classrooms,
      nameForCode: _nameForClassroomCode,
    );
    final currentCode = _currentClassroom?.trim() ?? '';
    final nextClassroomOptions = _buildDisplayOnlyOptions(
      codes: currentCode.isEmpty
          ? widget.classrooms
          : widget.classrooms.where((c) => c.trim() != currentCode).toList(),
      nameForCode: _nameForClassroomCode,
    );
    return StaffFormLayout(
      title: widget.isEditing
          ? 'Individual Student Movement'
          : 'Add Individual Student Movement',
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          ),
        ),
        child: CustomConfirmButton(label: 'Save', onPressed: _onSavePressed),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Movement Type', style: _labelStyle(responsive)),
            SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: responsive.inputFieldHeight,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 12.0 : 8.0,
                ),
                border: Border.all(color: const Color(0x66573353)),
              ),
              child: Text(
                MovementItem(
                  id: 0,
                  name: '',
                  fromClassroom: '',
                  toClassroom: '',
                  movementDate: AppTime.now(),
                  workflowStatus: MovementWorkflowStatus.pending,
                  movementType: widget.movementType,
                ).movementTypeLabel,
                style: TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: responsive.inputFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                ),
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            CustomDropdown(
              label: 'Select Student',
              hintText: 'Select',
              items: studentOptions.items,
              selectedItem:
                  (_selectedStudent == null || _selectedStudent!.trim().isEmpty)
                  ? null
                  : studentOptions.codeToDisplay[_selectedStudent!.trim()],
              showAsterisk: true,
              labelStyle: _labelStyle(responsive),
              labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
              selectedTextStyle: TextStyle(
                fontFamily: Fonts.manrope,
                fontSize: responsive.inputFontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xff573353),
                height: 19 / 14,
              ),
              isEnabled: !widget.isEditing,
              onSelect: (value) => setState(
                () => _selectedStudent =
                    studentOptions.displayToCode[(value ?? '').trim()],
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            if (widget.movementType == MovementType.moveToNextClassroom)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CustomDropdown(
                          label: 'Current Classroom',
                          hintText: 'Select',
                          items: classroomOptions.items,
                          selectedItem:
                              (_currentClassroom == null ||
                                  _currentClassroom!.trim().isEmpty)
                              ? null
                              : classroomOptions
                                    .codeToDisplay[_currentClassroom!.trim()],
                          showAsterisk: true,
                          labelStyle: _labelStyle(responsive),
                          labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                          selectedTextStyle: TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: responsive.inputFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          isEnabled:
                              !widget.isEditing &&
                              !widget.lockClassroomSelection,
                          onSelect: (value) => setState(
                            () => _currentClassroom = classroomOptions
                                .displayToCode[(value ?? '').trim()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CustomDropdown(
                          label: 'Next to Classroom',
                          hintText: 'Select',
                          items: nextClassroomOptions.items,
                          selectedItem:
                              (_nextClassroom == null ||
                                  _nextClassroom!.trim().isEmpty)
                              ? null
                              : nextClassroomOptions
                                    .codeToDisplay[_nextClassroom!.trim()],
                          showAsterisk: true,
                          labelStyle: _labelStyle(responsive),
                          labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                          selectedTextStyle: TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: responsive.inputFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          isEnabled: !widget.lockClassroomSelection,
                          onSelect: (value) => setState(
                            () => _nextClassroom = nextClassroomOptions
                                .displayToCode[(value ?? '').trim()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (widget.movementType == MovementType.startSchool)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomDropdown(
                    label: 'Classroom',
                    hintText: 'Select',
                    items: classroomOptions.items,
                    selectedItem:
                        (_nextClassroom == null ||
                            _nextClassroom!.trim().isEmpty)
                        ? null
                        : classroomOptions.codeToDisplay[_nextClassroom!
                              .trim()],
                    showAsterisk: true,
                    labelStyle: _labelStyle(responsive),
                    labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                    selectedTextStyle: TextStyle(
                      fontFamily: Fonts.manrope,
                      fontSize: responsive.inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353),
                      height: 19 / 14,
                    ),
                    isEnabled: !widget.lockClassroomSelection,
                    onSelect: (value) => setState(
                      () => _nextClassroom =
                          classroomOptions.displayToCode[(value ?? '').trim()],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomDropdown(
                    label: 'Classroom',
                    hintText: 'Select',
                    items: classroomOptions.items,
                    selectedItem:
                        (_currentClassroom == null ||
                            _currentClassroom!.trim().isEmpty)
                        ? null
                        : classroomOptions.codeToDisplay[_currentClassroom!
                              .trim()],
                    showAsterisk: true,
                    labelStyle: _labelStyle(responsive),
                    labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                    selectedTextStyle: TextStyle(
                      fontFamily: Fonts.manrope,
                      fontSize: responsive.inputFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353),
                      height: 19 / 14,
                    ),
                    isEnabled:
                        !widget.isEditing && !widget.lockClassroomSelection,
                    onSelect: (value) => setState(
                      () => _currentClassroom =
                          classroomOptions.displayToCode[(value ?? '').trim()],
                    ),
                  ),
                ],
              ),
            SizedBox(height: responsive.verticalSpacing),
            CustomDateTimeField(
              hasLabel: true,
              label: 'Movement Date',
              isRequired: true,
              initialDate: _movementDate,
              fetchInitialTime: false,
              firstDate: widget.disablePastDates
                  ? DateTime(
                      AppTime.now().year,
                      AppTime.now().month,
                      AppTime.now().day,
                    )
                  : null,
              onDateSelected: (date) => setState(() => _movementDate = date),
            ),
            SizedBox(height: responsive.verticalSpacing),
            _commentField(responsive),
          ],
        ),
      ),
    );
  }
}
