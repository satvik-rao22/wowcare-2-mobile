import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';

// Student entity for Transfer UI & API payload
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String photoUuid;
  final List<TagEntity> tags;
  final String classroomCode;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid = '',
    this.tags = const [],
    this.classroomCode = '',
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

class StudentTransferForm extends StatefulWidget {
  const StudentTransferForm({
    super.key,
    required this.students,
    this.refreshCallback,
    this.classroomNameToCode = const <String, String>{},
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;
  final Map<String, String> classroomNameToCode;

  static const String routeName = '/student-transfer-form';

  @override
  State<StudentTransferForm> createState() => _StudentTransferFormState();
}

class _StudentTransferFormState extends State<StudentTransferForm> {
  String? selectedClassroom;
  String currentClassroom = '';
  List<String> availableClassrooms = [];
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  Map<String, String> _classroomNameToCode = <String, String>{};

  @override
  void initState() {
    super.initState();
    currentStudents = List.from(widget.students);
    _classroomNameToCode = Map<String, String>.from(widget.classroomNameToCode);
    if (widget.students.isNotEmpty) {
      currentClassroom = widget.students.first.roomName;
      availableClassrooms = _filteredClassroomNames(
        _classroomNameToCode,
      );
    }
    _loadAvailableClassroomsFromApi();
  }

  List<String> _filteredClassroomNames(Map<String, String> classroomNameToCode) {
    final currentRoomNames = currentStudents
        .map((s) => s.roomName.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    return classroomNameToCode.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .where((entry) => !currentRoomNames.contains(entry.key))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  Future<void> _loadAvailableClassroomsFromApi() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;

      final getActiveClassroomsUseCase =
          serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: true,
      );

      final apiMap = <String, String>{
        for (final classroom in classrooms)
          if (classroom.name.trim().isNotEmpty && classroom.code.trim().isNotEmpty)
            classroom.name: classroom.code,
      };

      if (!mounted || apiMap.isEmpty) return;
      setState(() {
        _classroomNameToCode = apiMap;
        availableClassrooms = _filteredClassroomNames(_classroomNameToCode);
        if (selectedClassroom != null &&
            !availableClassrooms.contains(selectedClassroom)) {
          selectedClassroom = null;
        }
      });
    } catch (_) {
      // Keep fallback map from widget.classroomNameToCode if API load fails.
    }
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);

      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  void _handleSubmit() {
    if (selectedClassroom == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Please select a classroom to transfer to'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    _submitTransfer();
  }

  Future<String> _resolveStaffCode() async {
    return resolveStaffCodeForLoggedInUser();
  }

  Future<void> _submitTransfer() async {
    if (_isSubmitting) return;
    if (currentStudents.isEmpty || selectedClassroom == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('No students selected to transfer'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = serviceLocator<ApiClient>().client;
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceRecordsTransfer,
      ApiConstants.attendanceBaseUrl,
    );

    final today = DateTime.now();
    final transferDate =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final transferredAt = DateTime.now().toUtc();

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

    final studentCodes = currentStudents
        .map((s) => s.studentCode.trim())
        .where((code) => code.isNotEmpty)
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

    final toClassroomCode = selectedClassroom == null
        ? ''
        : (_classroomNameToCode[selectedClassroom!] ?? '').trim();
    if (toClassroomCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text(
            'Selected classroom is not linked to a classroom code yet.',
          ),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final toClassroomCodeByStudentCode = <String, String>{
      for (final s in currentStudents) s.studentCode: toClassroomCode,
    };

    final payload = <String, dynamic>{
      'transferDate': transferDate,
      'staffCode': staffCode,
      'studentCodes': studentCodes,
      'toClassroomCode': toClassroomCode,
      'toClassroomCodeByStudentCode': toClassroomCodeByStudentCode,
      // No dedicated reason field in UI yet, so send a generic placeholder.
      'transferReason': 'Transferred via mobile app',
      'timeZone': 'Asia/Kolkata',
      'transferredAt': transferredAt.toIso8601String(),
    };

    try {
      final response = await client.post<dynamic>(
        endpoint,
        data: payload,
      );

      final data = response.data;
      bool success = false;
      String message = 'Transfer successfully';

      if (data is Map<String, dynamic>) {
        success = data['success'] as bool? ?? false;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (success) {
        Navigator.pop(context);
        widget.refreshCallback?.call();
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Transfer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 3.5,
              ),
              itemCount: currentStudents.length,
              itemBuilder: (context, index) => RemoveStudentTile(
                student: currentStudents[index],
                onRemove: () => _removeStudent(currentStudents[index]),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Current Classroom'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    const Color.fromRGBO(177, 175, 233, 0.1),
                              ),
                              child: AppText.value(
                                currentClassroom,
                                style: TextStyle(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Transfer to Classroom'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromRGBO(177, 175, 233, 0.1),
                        ),
                        child: DropdownButton<String>(
                          value: selectedClassroom,
                          hint: const Text('Select classroom'),
                          style: TextStyle(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          isExpanded: true,
                          icon: SvgPicture.asset(MediaRes.arrow_drop_down),
                          underline: Container(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedClassroom = newValue!;
                            });
                          },
                          items: availableClassrooms.map((String classroom) {
                            return DropdownMenuItem<String>(
                              value: classroom,
                              child: Text(classroom),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
        showCancelButton: false,
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
                  name: student.fullName,
                  size: 30,
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
