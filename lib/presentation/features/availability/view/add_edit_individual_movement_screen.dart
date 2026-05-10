import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/text_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

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

class _AddEditIndividualMovementScreenState extends State<AddEditIndividualMovementScreen> {
  String? _selectedStudent;
  String? _currentClassroom;
  String? _nextClassroom;
  DateTime _movementDate = DateTime.now();
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
  }) _buildDisplayOnlyOptions({
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
    _movementDate = widget.initialData?.movementDate ?? DateTime.now();
    _commentController = TextEditingController(text: widget.initialData?.comment ?? '');

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
    final String? error = IndividualMovementValidators.validateMoveToNextClassroomForm(
      student: _selectedStudent,
      fromClassroom: _currentClassroom,
      toClassroom: _nextClassroom,
      movementType: widget.movementType,
      movementDate: _movementDate,
      existing: widget.existingMovements,
      excludeId: widget.editingMovementId,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final studentOptions = _buildDisplayOnlyOptions(
      codes: widget.students,
      nameForCode: _nameForStudentCode,
    );
    final classroomOptions = _buildDisplayOnlyOptions(
      codes: widget.classrooms,
      nameForCode: _nameForClassroomCode,
    );
    return StaffFormLayout(
      title: widget.isEditing
          ? 'Individual Student Movement'
          : 'Add Individual Student Movement',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.horizontalSpacing,
            0,
            responsive.horizontalSpacing,
            12,
          ),
          child: CustomConfirmButton(
            label: 'Save',
            onPressed: _onSavePressed,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _fieldLabel('Movement Type'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                MovementItem(
                  id: 0,
                  name: '',
                  fromClassroom: '',
                  toClassroom: '',
                  movementDate: DateTime.now(),
                  workflowStatus: MovementWorkflowStatus.pending,
                  movementType: widget.movementType,
                ).movementTypeLabel,
                style: const TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Select Student'),
            CustomDropdown(
              hintText: 'Select',
              items: studentOptions.items,
              selectedItem: (_selectedStudent == null ||
                      _selectedStudent!.trim().isEmpty)
                  ? null
                  : studentOptions.codeToDisplay[_selectedStudent!.trim()],
              showAsterisk: false,
              isEnabled: !widget.isEditing,
              onSelect: (value) => setState(
                () => _selectedStudent = studentOptions.displayToCode[(value ?? '').trim()],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.movementType == MovementType.moveToNextClassroom)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _fieldLabel('Current Classroom'),
                        CustomDropdown(
                          hintText: 'Select',
                          items: classroomOptions.items,
                          selectedItem: (_currentClassroom == null ||
                                  _currentClassroom!.trim().isEmpty)
                              ? null
                              : classroomOptions.codeToDisplay[_currentClassroom!.trim()],
                          showAsterisk: false,
                          isEnabled: !widget.isEditing && !widget.lockClassroomSelection,
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
                        _fieldLabel('Next to Classroom'),
                        CustomDropdown(
                          hintText: 'Select',
                          items: classroomOptions.items,
                          selectedItem: (_nextClassroom == null ||
                                  _nextClassroom!.trim().isEmpty)
                              ? null
                              : classroomOptions.codeToDisplay[_nextClassroom!.trim()],
                          showAsterisk: false,
                          isEnabled: !widget.lockClassroomSelection,
                          onSelect: (value) => setState(
                                () => _nextClassroom = classroomOptions
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
                  _fieldLabel('Classroom'),
                  CustomDropdown(
                    hintText: 'Select',
                    items: classroomOptions.items,
                    selectedItem: (_nextClassroom == null ||
                            _nextClassroom!.trim().isEmpty)
                        ? null
                        : classroomOptions.codeToDisplay[_nextClassroom!.trim()],
                    showAsterisk: false,
                    isEnabled: !widget.lockClassroomSelection,
                    onSelect: (value) => setState(
                          () => _nextClassroom = classroomOptions
                              .displayToCode[(value ?? '').trim()],
                        ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _fieldLabel('Classroom'),
                  CustomDropdown(
                    hintText: 'Select',
                    items: classroomOptions.items,
                    selectedItem: (_currentClassroom == null ||
                            _currentClassroom!.trim().isEmpty)
                        ? null
                        : classroomOptions.codeToDisplay[_currentClassroom!.trim()],
                    showAsterisk: false,
                    isEnabled: !widget.isEditing && !widget.lockClassroomSelection,
                    onSelect: (value) => setState(
                          () => _currentClassroom = classroomOptions
                              .displayToCode[(value ?? '').trim()],
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _fieldLabel('Movement Date'),
            CustomDateTimeField(
              hasLabel: false,
              initialDate: _movementDate,
              fetchInitialTime: false,
              firstDate: widget.disablePastDates
                  ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                  : null,
              onDateSelected: (date) => setState(() => _movementDate = date),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Comment'),
            CustomTextField(
              controller: _commentController,
              hintText: 'Enter Comment',
              isFilled: true,
              fillColor: Colors.white,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Fonts.manrope,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
