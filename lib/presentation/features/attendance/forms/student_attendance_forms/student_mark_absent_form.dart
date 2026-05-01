import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/mark_students_absent_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'dart:convert';

// Mock student entity for UI-only implementation
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String classroomCode;
  final String photoUuid;
  final List<TagEntity> tags;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    required this.classroomCode,
    this.photoUuid = '',
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          studentCode == other.studentCode;

  @override
  int get hashCode => studentCode.hashCode;
}

// Mock tag entity for UI-only implementation
class TagEntity {
  final String name;

  TagEntity({required this.name});
}

class StudentMarkAbsentForm extends StatefulWidget {
  const StudentMarkAbsentForm({
    super.key,
    required this.students,
    this.refreshCallback,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;

  @override
  State<StudentMarkAbsentForm> createState() => _StudentMarkAbsentFormState();
}

class _StudentMarkAbsentFormState extends State<StudentMarkAbsentForm> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  Map<String, TextEditingController> notesControllers = {};
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;

  late final MarkStudentsAbsentUseCase _markStudentsAbsentUseCase;

  @override
  void initState() {
    super.initState();
    _markStudentsAbsentUseCase = serviceLocator<MarkStudentsAbsentUseCase>();
    for (var student in widget.students) {
      notesControllers[student.studentCode] = TextEditingController();
    }

    currentStudents = List.from(widget.students);
    _loadPersonaFlags();
  }

  Future<void> _loadPersonaFlags() async {
    try {
      String? schoolIana;
      try {
        schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
          storage: serviceLocator<StorageService>(),
          apiClient: serviceLocator<ApiClient>(),
        );
      } catch (_) {}

      final storage = serviceLocator<StorageService>();
      final staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
      bool isAdmin = staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';
      if (!isAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
          for (final r in roles) {
            final roleCode =
                ((r as Map<String, dynamic>)['role'] ?? '').toString().toUpperCase();
            if (roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN') {
              isAdmin = true;
              break;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _isStaffAdminPersona = isAdmin;
        if (schoolIana != null && schoolIana.isNotEmpty) {
          startDate = SchoolZoneDateTime.schoolCalendarTodayOnly(schoolIana);
        } else {
          final now = DateTime.now();
          startDate = DateTime(now.year, now.month, now.day);
        }
        endDate = startDate;
      });
    } catch (_) {}
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);
      notesControllers[student.studentCode]?.dispose();
      notesControllers.remove(student.studentCode);

      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (currentStudents.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Please select at least one student'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    // classroomCode is required by API; use the first non-empty classroomCode.
    final classroomCode = currentStudents
        .map((s) => s.classroomCode.trim())
        .firstWhere(
          (c) => c.isNotEmpty,
          orElse: () => '',
        );

    final absenceFromDate = _formatDate(startDate);
    final absenceToDate = _formatDate(endDate);
    final absenceReason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : 'Marked Absent';

    final studentCodes = currentStudents
        .map((s) => s.studentCode.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (studentCodes.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Student code missing for selected students'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final absenceNotes = <String, String>{};
    for (final s in currentStudents) {
      final code = s.studentCode.trim();
      if (code.isEmpty) continue;
      final note = (notesControllers[code]?.text ?? '').trim();
      if (note.isNotEmpty) {
        absenceNotes[code] = note;
      }
    }
    final isExpectedTodayByStudentCode = <String, bool>{
      for (final code in studentCodes) code: true,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await _markStudentsAbsentUseCase(
        staffCode: staffCode,
        studentCodes: studentCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceNotes: absenceNotes,
        classroomCode: classroomCode,
        isExpectedTodayByStudentCode: isExpectedTodayByStudentCode,
        markAbsentMethod: 'APP',
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'Marked Absent successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const StudentAttendanceTabbedView(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(ApiErrorHandler.extractErrorMessage(e)),
          backgroundColor: AppColors.warningColor,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Mark Absent',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.label('Reason'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter absence reason',
                hintStyle: AppTextStyles.body.copyWith(
                  color: const Color.fromRGBO(87, 51, 83, 0.5),
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.cardColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Start Date'),
                      const SizedBox(height: 8),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: startDate,
                        isDisabled: !(_isStaffAdminPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            final picked = DateTime(date.year, date.month, date.day);
                            startDate = picked;
                            if (startDate.isAfter(endDate)) {
                              endDate = startDate;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('End Date'),
                      const SizedBox(height: 8),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: endDate,
                        isDisabled: !(_isStaffAdminPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            final picked = DateTime(date.year, date.month, date.day);
                            endDate = picked;
                            if (endDate.isBefore(startDate)) {
                              startDate = endDate;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: currentStudents.length,
              itemBuilder: (context, index) {
                final student = currentStudents[index];

                return Column(
                  children: [
                    RemoveStudentTile(
                      student: student,
                      onRemove: () => _removeStudent(student),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: notesControllers[student.studentCode],
                      decoration: InputDecoration(
                        hintText: 'Enter Absent Notes',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: const Color.fromRGBO(87, 51, 83, 0.5),
                          fontSize: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color.fromRGBO(87, 51, 83, 0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(87, 51, 83, 0.4),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(87, 51, 83, 0.4),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.cardColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _handleSubmit,
        showCancelButton: false,
        isLoading: _isSubmitting,
      ),
    );
  }
}

class RemoveStudentTile extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onRemove;

  const RemoveStudentTile({
    super.key,
    required this.student,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.themeColor,
        ),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: student.photoUuid,
                  size: 30,
                  name: student.fullName,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    student.fullName.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(MediaRes.delete_icon),
          )
        ],
      ),
    );
  }
}
