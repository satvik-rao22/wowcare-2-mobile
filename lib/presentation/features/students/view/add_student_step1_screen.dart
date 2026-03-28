import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step2_screen.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step3_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/duplicate_student_bottom_sheet.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';

class AddStudentStep1Screen extends StatefulWidget {
  const AddStudentStep1Screen({
    super.key,
    this.initialStatus,
    this.initialFirstName,
    this.initialLastName,
    this.initialClassroom,
    this.initialBirthdate,
    this.initialSchoolStartDate,
    this.initialProfilePhoto,
  });

  static const String routeName = '/add-student-step1-screen';

  final String? initialStatus;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialClassroom;
  final DateTime? initialBirthdate;
  final DateTime? initialSchoolStartDate;
  final File? initialProfilePhoto;

  @override
  _AddStudentStep1ScreenState createState() => _AddStudentStep1ScreenState();
}

class _AddStudentStep1ScreenState extends State<AddStudentStep1Screen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const int _nameMaxLength = 50;
  static const int _duplicateQueryPageSize = 25;
  static const int _duplicateQueryMaxPages = 10; // safety cap (25 * 10 = 250 scanned)

  String? _selectedStatus;
  String? _selectedClassroom;
  DateTime? _selectedBirthdate;
  DateTime? _selectedSchoolStartDate;
  File? _profilePhoto;
  int? _calculatedAge;
  bool _isSubmitting = false;

  final List<String> _statusOptions = ['Active', 'Upcoming'];

  bool get _isActive => (_selectedStatus ?? '').toLowerCase() == 'active';
  bool get _isUpcoming => (_selectedStatus ?? '').toLowerCase() == 'upcoming';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? 'Active';
    if (widget.initialFirstName != null) {
      _firstNameController.text = widget.initialFirstName!.trim();
    }
    if (widget.initialLastName != null) {
      _lastNameController.text = widget.initialLastName!.trim();
    }
    _selectedClassroom = widget.initialClassroom;
    _selectedBirthdate = widget.initialBirthdate;
    _selectedSchoolStartDate = widget.initialSchoolStartDate;
    _profilePhoto = widget.initialProfilePhoto;
    if (_selectedBirthdate != null) {
      _calculateAge(_selectedBirthdate!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    setState(() {
      _calculatedAge = age;
    });
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final file = File(image.path);
      final fileSizeInMB = await file.length() / (1024 * 1024);

      if (fileSizeInMB > 10) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Image size must be less than 10MB',
          isError: true,
        );
        return;
      }

      setState(() {
        _profilePhoto = file;
      });
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  Future<void> _selectBirthdate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: _selectedBirthdate,
        ),
      );

      if (result != null && result['date'] != null) {
        final selectedDate = result['date'] as DateTime;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Validate: must be past date only
        if (selectedDate.isAfter(today.subtract(const Duration(days: 1)))) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Birthdate must be a past date',
            isError: true,
          );
          return;
        }

        setState(() {
          _selectedBirthdate = selectedDate;
        });
        _calculateAge(selectedDate);
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  Future<void> _selectSchoolStartDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: _selectedSchoolStartDate,
        ),
      );

      if (result != null && result['date'] != null) {
        setState(() {
          _selectedSchoolStartDate = result['date'] as DateTime;
        });
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  void _trimAllInputs() {
    _firstNameController.text = _firstNameController.text.trim();
    _lastNameController.text = _lastNameController.text.trim();
  }

  Future<void> _onNext() async {
    _trimAllInputs();
    
    if (_firstNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name is required',
        isError: true,
      );
      return;
    }

    if (_firstNameController.text.length > _nameMaxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name must be at most $_nameMaxLength characters',
        isError: true,
      );
      return;
    }
    
    if (_lastNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name is required',
        isError: true,
      );
      return;
    }

    if (_lastNameController.text.length > _nameMaxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name must be at most $_nameMaxLength characters',
        isError: true,
      );
      return;
    }

    if (_selectedClassroom == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a classroom',
        isError: true,
      );
      return;
    }

    if (_isActive && _selectedBirthdate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Birthdate is required for active students',
        isError: true,
      );
      return;
    }

    if (_isUpcoming && _selectedSchoolStartDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'School start date is required for upcoming students',
        isError: true,
      );
      return;
    }

    final proceed = await _confirmIfDuplicateNameExists(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    if (!proceed) return;

    final step1Data = {
      'status': _selectedStatus,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'classroom': _selectedClassroom,
      'birthdate': _selectedBirthdate,
      'schoolStartDate': _selectedSchoolStartDate,
      'profilePhoto': _profilePhoto,
      'age': _calculatedAge,
    };

    // Navigate to step 2
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentStep2Screen(
          initialSelectFromExisting: false,
          initialSelectedExistingParents: const [],
        ),
      ),
    ).then((step2Result) {
      if (step2Result != null) {
        // Handle step 2 result and continue to step 3 or complete
        _handleStep2Result(step1Data, [step2Result]);
      }
    });
  }

  Future<bool> _confirmIfDuplicateNameExists({
    required String firstName,
    required String lastName,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty) return true;

    // Best-effort duplicate check. If it fails, do not block the flow.
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return true;

      final repo = serviceLocator<StudentRepository>();

      String norm(String s) => s.trim().toLowerCase();
      final firstNorm = norm(firstName);
      final lastNorm = norm(lastName);

      // Paginate to avoid missing duplicates beyond first page.
      final matches = <Student>[];
      int pageIndex = 0;
      bool hasMore = true;
      while (hasMore && pageIndex < _duplicateQueryMaxPages) {
        final page = await repo.getStudentPage(
          schoolCode: schoolCode,
          firstName: firstName,
          lastName: lastName,
          page: pageIndex,
          size: _duplicateQueryPageSize,
        );

        for (final s in page.items) {
          if (norm(s.firstName) == firstNorm && norm(s.lastName) == lastNorm) {
            matches.add(s);
          }
        }

        // If backend correctly filters by first+last, there shouldn't be many results,
        // but this keeps us safe if it returns broader matches.
        hasMore = page.hasMore;
        pageIndex++;

        // Early exit: if we already found at least one exact match and this page
        // returned fewer than page size, there are no further pages.
        if (!page.hasMore) break;
      }

      if (matches.isEmpty) return true;

      // Show bottom sheet with clickable matches.
      final enteredName = '$firstName $lastName'.trim();
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DuplicateStudentBottomSheet(
            enteredName: enteredName,
            matches: matches.map((m) => m.fullName.isNotEmpty ? m.fullName : enteredName).toList(),
            onTapMatch: (matchName) {
              final match = matches.firstWhere(
                (m) => (m.fullName.isNotEmpty ? m.fullName : enteredName) == matchName,
                orElse: () => matches.first,
              );
              Navigator.of(ctx).pop(false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentProfileScreen(
                    name: match.fullName.isNotEmpty ? match.fullName : enteredName,
                    classroom: match.classroom,
                    tags: match.tags,
                    schedule: match.schedule,
                    sibling: const {},
                    studentCode: match.code,
                  ),
                ),
              );
            },
          );
        },
      );

      // true => add anyway. null/false => cancel.
      return result == true;
    } catch (e) {
      CoreUtils.logApiError('Duplicate name check failed: $e');
      return true;
    }
  }

  void _handleStep2Result(Map<String, dynamic> step1Data, List<dynamic> parents) async {
    // Ask if user wants to add another parent
    final addAnother = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmationBottomSheet(
        title: 'Do you want to add another parent?',
        confirmText: 'Yes',
        cancelText: 'Skip',
        icon: Icons.family_restroom,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (addAnother == true) {
      // Navigate to step 2 again to add another parent
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddStudentStep2Screen(
            initialSelectFromExisting: false,
            initialSelectedExistingParents: const [],
          ),
        ),
      ).then((nextParentResult) {
        if (nextParentResult != null) {
          final updatedParents = List<dynamic>.from(parents)..add(nextParentResult);
          _handleStep2Result(step1Data, updatedParents);
        }
      });
      return;
    }

    // Ask if user wants to add schedule
    final addSchedule = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmationBottomSheet(
        title: 'Do you want to add schedule for this child now?',
        confirmText: 'Yes',
        cancelText: 'Skip',
        icon: Icons.calendar_today,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (addSchedule == true) {
      // Navigate to step 3
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddStudentStep3Screen(),
        ),
      ).then((step3Result) {
        _handleStep3Result(step1Data, parents, step3Result);
      });
    } else {
      // Complete without schedule
      _completeWizard(step1Data, parents, null);
    }
  }

  void _handleStep3Result(
    Map<String, dynamic> step1Data,
    List<dynamic> parents,
    dynamic step3Result,
  ) async {
    // Ask if user wants to create recurring invoices
    final addInvoices = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmationBottomSheet(
        title: 'Do you want to create recurring invoices for this child now?',
        confirmText: 'Yes',
        cancelText: 'Skip',
        icon: Icons.receipt_long,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (addInvoices == true) {
      // TODO: Navigate to recurring invoices screen
      // For now, just complete the wizard
      _completeWizard(step1Data, parents, step3Result);
    } else {
      // Complete the wizard
      _completeWizard(step1Data, parents, step3Result);
    }
  }

  Future<void> _completeWizard(
    Map<String, dynamic> step1Data,
    List<dynamic> parents,
    dynamic schedule,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final firstName = (step1Data['firstName'] as String?)?.trim() ?? '';
      final lastName = (step1Data['lastName'] as String?)?.trim() ?? '';
      final rawStatus = (step1Data['status'] as String?) ?? 'Active';
      final status = rawStatus.toUpperCase();
      final classroom = (step1Data['classroom'] as String?) ?? '';
      final DateTime? birthdate = step1Data['birthdate'] as DateTime?;
      final DateTime? schoolStartDate = step1Data['schoolStartDate'] as DateTime?;

      final storage = serviceLocator<StorageService>();
      final schoolCode =
          await storage.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await storage.getString(StorageKeys.organizationCode) ?? '';
      final userCode =
          await storage.getString(StorageKeys.userCode) ?? '';

      final repo = serviceLocator<StudentRepository>();

      final Student student = await repo.createStudent(
        schoolCode: schoolCode,
        firstName: firstName,
        lastName: lastName,
        status: status,
        classroom: classroom,
        dob: birthdate,
        schoolStartDate: schoolStartDate,
        profilePhotoUrl: null,
      );

      final studentName = student.fullName.isNotEmpty
          ? student.fullName
          : '$firstName $lastName'.trim();

      // Create guardian-user records for each newly entered parent (step 2).
      // Existing parents selected from the list are skipped here.
      if (organizationCode.trim().isEmpty) {
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                'Organization is missing; cannot add guardians. Re-select your school and try again.',
            isError: true,
          );
        }
      } else {
        for (final parent in parents) {
        if (parent is! Map) continue;
        final map = Map<String, dynamic>.from(parent);
        final bool selectFromExisting =
            map['selectFromExisting'] as bool? ?? false;
        if (selectFromExisting) {
          // Existing parents linking flow is not implemented yet.
          continue;
        }

        final parentFirst =
            (map['firstName'] as String?)?.trim() ?? '';
        final parentLast =
            (map['lastName'] as String?)?.trim() ?? '';
        final parentEmail =
            (map['email'] as String?)?.trim().toLowerCase() ?? '';
        final parentPhoneRaw =
            (map['phoneNumber'] as String?)?.trim() ?? '';
        final parentPhoneDigits =
            parentPhoneRaw.replaceAll(RegExp(r'\D'), '');

        if (parentFirst.isEmpty ||
            parentLast.isEmpty ||
            parentEmail.isEmpty ||
            parentPhoneDigits.isEmpty) {
          continue;
        }

        final relationLabel =
            (map['relation'] as String?)?.trim() ?? '';
        final relationOther =
            (map['relationOther'] as String?)?.trim() ?? '';
        final relationToStudent = (relationLabel == 'Other' && relationOther.isNotEmpty
                ? relationOther
                : relationLabel)
            .toUpperCase();

        final bool primaryContact =
            map['isEmergencyContact'] as bool? ?? true;
        final bool legalCustody =
            map['isChildCustody'] as bool? ?? true;

        try {
          await repo.createGuardianUser(
            schoolCode: schoolCode,
            studentCode: student.code,
            firstName: parentFirst,
            lastName: parentLast,
            email: parentEmail,
            mobile: parentPhoneDigits,
            relationToStudent: relationToStudent,
            primaryContact: primaryContact,
            legalCustody: legalCustody,
            profilePhotoUrl: null,
            userCode: userCode.isEmpty ? null : userCode,
            organizationCode: organizationCode.trim(),
          );
        } catch (e) {
          final message = ApiErrorHandler.extractErrorMessage(e);
          if (mounted) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Failed to add guardian: $message',
              isError: true,
            );
          }
        }
        }
      }

      // If a schedule was provided from Step 3, send it to the regular-schedules API.
      try {
        if (schedule is Map) {
          final rawSchedule = Map<String, dynamic>.from(schedule);
          final List<Map<String, dynamic>> payloadSchedule = [];

          String _formatLocalTime(TimeOfDay time) {
            final h = time.hour.toString().padLeft(2, '0');
            final m = time.minute.toString().padLeft(2, '0');
            // Use HH:mm:ss which Jackson's LocalTime can parse by default.
            return '$h:$m:00';
          }

          for (final entry in rawSchedule.entries) {
            final dayName = entry.key.toString();
            final timesMap = Map<String, dynamic>.from(entry.value as Map);
            final start = timesMap['start'] as TimeOfDay?;
            final end = timesMap['end'] as TimeOfDay?;

            if (start == null || end == null) {
              continue;
            }

            // Compute a simple mid-point time for halfDay between start and end.
            final startMinutes = start.hour * 60 + start.minute;
            final endMinutes = end.hour * 60 + end.minute;
            final midMinutes = ((startMinutes + endMinutes) / 2).floor();
            final halfDay = TimeOfDay(
              hour: (midMinutes ~/ 60) % 24,
              minute: midMinutes % 60,
            );

            payloadSchedule.add({
              'dayOfWeek': dayName.toUpperCase(), // e.g. MONDAY
              'startTime': _formatLocalTime(start),
              'halfDay': _formatLocalTime(halfDay),
              'endTime': _formatLocalTime(end),
            });
          }

          if (payloadSchedule.isNotEmpty && schoolCode.isNotEmpty) {
            final remote = serviceLocator<StudentRemoteDataSource>();
            await remote.updateStudentRegularSchedules(
              schoolCode: schoolCode,
              studentCode: student.code,
              schedule: payloadSchedule,
            );
          }
        }
      } catch (e) {
        final message = ApiErrorHandler.extractErrorMessage(e);
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Student created but failed to save schedule: $message',
            isError: true,
          );
        }
      }

      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Student${studentName.isNotEmpty ? ' $studentName ' : ' '}added successfully',
        isSuccess: true,
      );

      Navigator.pop(context, {
        'showPostAddPrompt': true,
        'studentName': studentName,
        'studentCode': student.code,
      });
    } catch (e) {
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
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
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        final classroomNames =
            classroomState.classrooms.map((c) => c.name).toList();

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: const CustomAppBar(hasBackButton: true),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buildScaffoldGradient(),
                    ),
                    child: Image.asset(
                      MediaRes.wowcareMobileBg,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add Student - Step 1 of 3',
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: responsive.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                    Expanded(
                      child: Container(
                        width: responsive.containerWidth,
                        margin: EdgeInsets.symmetric(
                            horizontal: responsive.horizontalSpacing),
                        padding: EdgeInsets.all(
                            responsive.isTablet ? 32.0 : 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                                responsive.isTablet ? 40.0 : 24.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Status
                                  CustomDropdown(
                                    label: "Status",
                                    hintText: 'Select',
                                    items: _statusOptions,
                                    selectedItem: _selectedStatus,
                                    labelStyle: TextStyle(
                                      fontSize: responsive.labelFontSize,
                                      fontFamily: "Manrope",
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff573353),
                                    ),
                                    showAsterisk: true,
                                    labelBottomSpacing:
                                        responsive.isTablet ? 8.0 : 6.0,
                                    onSelect: (val) {
                                      setState(() {
                                        _selectedStatus = val;
                                      });
                                    },
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // First Name and Last Name
                                  _buildRowInputs(context),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Classroom
                                  CustomDropdown(
                                    label: "Classroom",
                                    hintText: 'Select',
                                    items: classroomNames,
                                    selectedItem: _selectedClassroom,
                                    labelStyle: TextStyle(
                                      fontSize: responsive.labelFontSize,
                                      fontFamily: "Manrope",
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff573353),
                                    ),
                                    showAsterisk: true,
                                    labelBottomSpacing:
                                        responsive.isTablet ? 8.0 : 6.0,
                                    onSelect: (val) {
                                      setState(() {
                                        _selectedClassroom = val;
                                      });
                                    },
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Profile Photo
                                  _buildProfilePhotoField(responsive),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Birthdate
                                  _buildDateField(
                                    "Birthdate",
                                    _selectedBirthdate,
                                    _selectBirthdate,
                                    isRequired: _isActive,
                                    age: _calculatedAge,
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // School Start Date
                                  _buildDateField(
                                    "School Start Date",
                                    _selectedSchoolStartDate,
                                    _selectSchoolStartDate,
                                    isRequired: _isUpcoming,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.only(
                bottom: safeAreaBottom,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft:
                      Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                  topRight:
                      Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                ),
              ),
              child: CustomButtonLayout(
                confirmButtonLabel: 'Next',
                onPressedConfirm: _isSubmitting ? null : _onNext,
                showCancelButton: false,
                isForm: false,
                isLoading: _isSubmitting,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRowInputs(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            "First Name",
            "E.g. John",
            _firstNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s\-']")),
              LengthLimitingTextInputFormatter(_nameMaxLength),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
        SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
        Expanded(
          child: _buildInputField(
            "Last Name",
            "E.g. Smith",
            _lastNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s\-']")),
              LengthLimitingTextInputFormatter(_nameMaxLength),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
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

  Widget _buildProfilePhotoField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: "Manrope",
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x66573353)),
            ),
            child: _profilePhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _profilePhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, max 10MB (Optional)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    VoidCallback onTap, {
    bool isRequired = false,
    int? age,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0x66573353)),
              borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateFormat('MM/dd/yyyy').format(selectedDate)
                              : 'Select Date',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.inputFontSize,
                            fontWeight: selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (age != null && selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Age: $age ${age == 1 ? 'year' : 'years'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: 20.0,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove trailing spaces
    text = text.replaceFirst(RegExp(r"\s+"), ' '); // collapse multiple spaces inside
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Enforce first letter uppercase, remaining lowercase
    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trimLeft();
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}

