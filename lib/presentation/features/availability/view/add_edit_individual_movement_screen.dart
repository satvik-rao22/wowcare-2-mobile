import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/text_field.dart';

class AddEditIndividualMovementScreen extends StatefulWidget {
  const AddEditIndividualMovementScreen({
    super.key,
    required this.students,
    required this.classrooms,
    required this.existingMovements,
    this.initialData,
    this.isEditing = false,
    this.editingMovementId,
  });

  final List<String> students;
  final List<String> classrooms;
  /// Full list used for duplicate detection (same student, date, from, to).
  final List<MovementItem> existingMovements;
  final MovementFormResult? initialData;
  final bool isEditing;
  final int? editingMovementId;

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

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialData?.student;
    _currentClassroom = widget.initialData?.currentClassroom;
    _nextClassroom = widget.initialData?.nextClassroom;
    _movementDate = widget.initialData?.movementDate ?? DateTime.now();
    _commentController = TextEditingController(text: widget.initialData?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.isEditing
                ? 'Individual Student Movement'
                : 'Add Individual Student Movement',
            style: const TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _fieldLabel('Select Student'),
                    CustomDropdown(
                      hintText: 'Select',
                      items: widget.students,
                      selectedItem: _selectedStudent,
                      showAsterisk: false,
                      onSelect: (value) => setState(() => _selectedStudent = value),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _fieldLabel('Current Classroom'),
                              CustomDropdown(
                                hintText: 'Select',
                                items: widget.classrooms,
                                selectedItem: _currentClassroom,
                                showAsterisk: false,
                                onSelect: (value) => setState(() => _currentClassroom = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _fieldLabel('Next to Classroom'),
                              CustomDropdown(
                                hintText: 'Select',
                                items: widget.classrooms,
                                selectedItem: _nextClassroom,
                                showAsterisk: false,
                                onSelect: (value) => setState(() => _nextClassroom = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel('Movement Date'),
                    CustomDateTimeField(
                      hasLabel: false,
                      initialDate: _movementDate,
                      fetchInitialTime: false,
                      onDateSelected: (date) => setState(() => _movementDate = date),
                    ),
                    const SizedBox(height: 10),
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
            ),
          ),
          const SizedBox(height: 10),
          CustomConfirmButton(
            label: 'Save',
            onPressed: () {
              final String? error = IndividualMovementValidators.validateMoveToNextClassroomForm(
                student: _selectedStudent,
                fromClassroom: _currentClassroom,
                toClassroom: _nextClassroom,
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
            },
          ),
        ],
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
