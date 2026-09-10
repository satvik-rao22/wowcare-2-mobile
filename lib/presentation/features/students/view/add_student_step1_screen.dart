import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/students/view/student_form_formatters.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/students/view_model/student_create_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classroom/utils/classroom_age_range.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step2_screen.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step3_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/duplicate_student_bottom_sheet.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/same_last_name_siblings_dialog.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

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

  static const int _nameMaxLength = 50;
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static const int _duplicateQueryPageSize = 25;
  static const int _duplicateQueryMaxPages =
      10; // safety cap (25 * 10 = 250 scanned)
  static const int _maxParentsPerStudent = 4;

  final StudentCreateCubit _createCubit = serviceLocator<StudentCreateCubit>();

  final List<String> _statusOptions = ['Active', 'Upcoming'];

  // Read the status-derived flags off the cubit-owned form model.
  bool get _isActive =>
      (_createCubit.state.step1Status ?? '').toLowerCase() == 'active';
  bool get _isUpcoming =>
      (_createCubit.state.step1Status ?? '').toLowerCase() == 'upcoming';

  @override
  void initState() {
    super.initState();
    if (widget.initialFirstName != null) {
      _firstNameController.text = widget.initialFirstName!.trim();
    }
    if (widget.initialLastName != null) {
      _lastNameController.text = widget.initialLastName!.trim();
    }
    // Controllers stay local; the rest of the step-1 form model seeds the cubit.
    _createCubit.initializeStep1(
      status: widget.initialStatus ?? 'Active',
      classroom: widget.initialClassroom,
      birthdate: widget.initialBirthdate,
      schoolStartDate: widget.initialSchoolStartDate,
      profilePhoto: widget.initialProfilePhoto,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _createCubit.close();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      // Use the shared file picker so every allowed image format is selectable
      // (jpeg/jpg/png/webp/heic/heif/avif/gif/bmp/tiff), not just gallery JPEGs.
      final picked = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
        context: context,
      );
      final path = picked?.path;
      if (path == null || path.isEmpty) return;

      final file = File(path);
      final fileSizeInMB = await file.length() / (1024 * 1024);

      if (fileSizeInMB > 10) {
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.imageSizeMustBeLessThan10mb,
          isError: true,
        );
        return;
      }

      _createCubit.setStep1ProfilePhoto(file);
    } catch (e) {
      if (!mounted) return;
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
          initialDate: _createCubit.state.step1Birthdate,
        ),
      );

      if (result != null && result['date'] != null) {
        final selectedDate = result['date'] as DateTime;
        final now = AppTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Validate: must be past date only
        if (selectedDate.isAfter(today.subtract(const Duration(days: 1)))) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: StudentStrings.birthdateMustBeAPastDate,
            isError: true,
          );
          return;
        }

        // Cubit sets the date AND derives the age label.
        _createCubit.setStep1Birthdate(selectedDate);
      }
    } catch (e) {
      AppLogger.d('Error opening calendar dialog: $e');
    }
  }

  Future<void> _selectSchoolStartDate() async {
    try {
      final now = AppTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final initial = _createCubit.state.step1SchoolStartDate;
      final DateTime? initialForPicker = _isUpcoming
          ? (initial == null || initial.isBefore(today) ? today : initial)
          : initial;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: initialForPicker,
          firstDate: _isUpcoming ? today : null,
          lastDate: DateTime(today.year + 5),
        ),
      );

      if (result != null && result['date'] != null) {
        final selectedDate = result['date'] as DateTime;
        final selDay = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        if (_isUpcoming && selDay.isBefore(today)) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: StudentStrings.schoolStartDateCannotBeInThePast,
            isError: true,
          );
          return;
        }
        _createCubit.setStep1SchoolStartDate(selectedDate);
      }
    } catch (e) {
      AppLogger.d('Error opening calendar dialog: $e');
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
        message: StudentStrings.firstNameIsRequired2,
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
    if (!_nameRegex.hasMatch(_firstNameController.text)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.firstNameMustBeLettersOnlyAndMax50Characters,
        isError: true,
      );
      return;
    }

    if (_lastNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.lastNameIsRequired2,
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
    if (!_nameRegex.hasMatch(_lastNameController.text)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.lastNameMustBeLettersOnlyAndMax50Characters,
        isError: true,
      );
      return;
    }

    if (_createCubit.state.step1Classroom == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.pleaseSelectAClassroom,
        isError: true,
      );
      return;
    }

    if (_isActive && _createCubit.state.step1Birthdate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.birthdateIsRequiredForActiveStudents,
        isError: true,
      );
      return;
    }

    if (_isUpcoming && _createCubit.state.step1SchoolStartDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.schoolStartDateIsRequiredForUpcomingStudents,
        isError: true,
      );
      return;
    }

    final proceed = await _confirmIfDuplicateNameExists(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    if (!proceed) return;

    final siblingCodesToLink = await _pickSameLastNameSiblings(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final selectedClassroom = classrooms.where(
      (c) => c.name == _createCubit.state.step1Classroom,
    );
    final selectedClassroomCode = selectedClassroom.isNotEmpty
        ? selectedClassroom.first.code
        : '';
    if (selectedClassroomCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.selectedClassroomIsInvalidPleaseSelectAgain,
        isError: true,
      );
      return;
    }

    // WARN (never block) when the DOB is outside the classroom's age range.
    // An out-of-range placement is a legitimate staff decision, so we surface it
    // and let them proceed — matching the web "warn but allow" behaviour.
    final ageWarning = classroomAgeRangeWarning(
      classroom: selectedClassroom.first,
      birthDate: _createCubit.state.step1Birthdate,
      studentName: _firstNameController.text.trim(),
    );
    if (ageWarning != null) {
      final proceedAnyway = await _confirmAgeOutsideRange(ageWarning);
      if (!proceedAnyway || !mounted) return;
    }

    await _createStudentAndContinue(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      classroomCode: selectedClassroomCode,
      siblingCodesToLink: siblingCodesToLink,
    );
  }

  /// Amber confirm for an out-of-range DOB. Returns true to proceed anyway.
  Future<bool> _confirmAgeOutsideRange(String message) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (ctx) => ConfirmationBottomSheet(
        icon: Icons.warning_amber_rounded,
        title: message,
        confirmText: StudentStrings.continueAnyway,
        cancelText: StudentStrings.cancel,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result == true;
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

      String norm(String s) => s.trim().toLowerCase();
      final firstNorm = norm(firstName);
      final lastNorm = norm(lastName);

      // Paginate to avoid missing duplicates beyond first page.
      final matches = <Student>[];
      int pageIndex = 0;
      bool hasMore = true;
      while (hasMore && pageIndex < _duplicateQueryMaxPages) {
        final page = await _createCubit.fetchStudentPage(
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
        backgroundColor: AppColors.transparentColor,
        builder: (ctx) {
          return DuplicateStudentBottomSheet(
            enteredName: enteredName,
            matches: matches
                .map((m) => m.fullName.isNotEmpty ? m.fullName : enteredName)
                .toList(),
            onTapMatch: (matchName) {
              final match = matches.firstWhere(
                (m) =>
                    (m.fullName.isNotEmpty ? m.fullName : enteredName) ==
                    matchName,
                orElse: () => matches.first,
              );
              Navigator.of(ctx).pop(false);
              context.push(
                StudentProfileScreen.routeName,
                extra: <String, dynamic>{
                  'name': match.fullName.isNotEmpty
                      ? match.fullName
                      : enteredName,
                  'classroom': match.classroom,
                  'tags': match.tags,
                  'schedule': match.schedule,
                  'sibling': const StudentSiblingInfo(),
                  'studentCode': match.code,
                  'initialEnrollmentStatus': match.status,
                },
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

  Future<List<Student>> _fetchSameLastNameStudents({
    required String firstName,
    required String lastName,
  }) async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
    if (schoolCode.isEmpty) return <Student>[];

    String norm(String s) => s.trim().toLowerCase();
    final firstNorm = norm(firstName);
    final lastNorm = norm(lastName);

    final matches = <Student>[];
    int pageIndex = 0;
    bool hasMore = true;
    while (hasMore && pageIndex < _duplicateQueryMaxPages) {
      final page = await _createCubit.fetchStudentPage(
        schoolCode: schoolCode,
        lastName: lastName,
        page: pageIndex,
        size: _duplicateQueryPageSize,
      );

      for (final s in page.items) {
        if (norm(s.lastName) != lastNorm) continue;
        if (norm(s.firstName) == firstNorm && norm(s.lastName) == lastNorm) {
          continue;
        }
        // Only offer active students as sibling candidates, matching web.
        if (s.status.trim().toUpperCase() != 'ACTIVE') continue;
        matches.add(s);
      }

      hasMore = page.hasMore;
      pageIndex++;
      if (!page.hasMore) break;
    }

    return matches;
  }

  Future<List<String>> _pickSameLastNameSiblings({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final candidates = await _fetchSameLastNameStudents(
        firstName: firstName,
        lastName: lastName,
      );
      if (candidates.isEmpty) return <String>[];
      if (!mounted) return <String>[];
      final result = await showSameLastNameSiblingsDialog(
        context: context,
        candidates: candidates,
      );
      if (result == null) return <String>[];
      return result;
    } catch (e) {
      CoreUtils.logApiError('Same-last-name siblings lookup failed: $e');
      return <String>[];
    }
  }

  /// Creates the student via the student API immediately (Step 1's own
  /// concern), then hands off to the now-optional Add Parent step. Parent
  /// creation is Step 2's own API call — see [AddStudentStep2Screen] with
  /// `createGuardianDirectly: true` — this method no longer touches guardian
  /// endpoints at all.
  Future<void> _createStudentAndContinue({
    required String firstName,
    required String lastName,
    required String classroomCode,
    required List<String> siblingCodesToLink,
  }) async {
    _createCubit.setStep1Submitting(true);

    try {
      final rawStatus = _createCubit.state.step1Status ?? 'Active';
      final status = rawStatus.toUpperCase();

      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await storage.getString(StorageKeys.organizationCode) ?? '';

      final Student student = await _createCubit.createStudent(
        schoolCode: schoolCode,
        firstName: firstName,
        lastName: lastName,
        status: status,
        classroom: classroomCode,
        dob: _createCubit.state.step1Birthdate,
        schoolStartDate: _createCubit.state.step1SchoolStartDate,
        profilePhotoUrl: null,
      );

      // Upload the picked student photo in the BACKGROUND so creation returns
      // immediately; the upload keeps running even after this screen is closed.
      final pickedPhoto = _createCubit.state.step1ProfilePhoto;
      if (pickedPhoto != null && student.code.trim().isNotEmpty) {
        unawaited(
          _createCubit.uploadStudentPhotoInBackground(
            studentCode: student.code.trim(),
            file: pickedPhoto,
            schoolCode: schoolCode.trim(),
            organizationCode: organizationCode.trim(),
          ),
        );
      }

      // Link same-last-name siblings picked in Step 1
      // (POST /api/v1/student/{code}/add-sibling).
      if (siblingCodesToLink.isNotEmpty) {
        try {
          await _createCubit.addStudentSibling(
            studentCode: student.code,
            siblingCodes: siblingCodesToLink,
          );
        } catch (e) {
          final message = ApiErrorHandler.extractErrorMessage(e);
          if (mounted) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Student created, but linking siblings failed: $message',
              isError: true,
            );
          }
        }
      }

      final studentName = student.fullName.isNotEmpty
          ? student.fullName
          : '$firstName $lastName'.trim();

      if (!mounted) return;

      // Step 2 (Add Parent) is now optional: it calls the guardian API itself
      // (createGuardianDirectly) and returns true only if a parent was saved.
      final parentResult = await context.push<bool>(
        AddStudentStep2Screen.routeName,
        extra: <String, dynamic>{
          'studentCode': student.code,
          'schoolCode': schoolCode,
          'createGuardianDirectly': true,
          'isOptionalStep': true,
        },
      );

      if (!mounted) return;

      await _onParentStepResult(
        studentCode: student.code,
        studentName: studentName,
        justAddedParent: parentResult == true,
        parentCount: parentResult == true ? 1 : 0,
      );
    } catch (e) {
      final message = ApiErrorHandler.extractErrorMessage(e);
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: message,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        _createCubit.setStep1Submitting(false);
      }
    }
  }

  /// After the (optional) Add Parent step returns, offer to add another
  /// parent, then move on to the (optional) schedule step, then finish.
  Future<void> _onParentStepResult({
    required String studentCode,
    required String studentName,
    required bool justAddedParent,
    required int parentCount,
  }) async {
    if (justAddedParent && parentCount < _maxParentsPerStudent) {
      final addAnother = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.transparentColor,
        builder: (context) => ConfirmationBottomSheet(
          title: StudentStrings.doYouWantToAddAnotherParent,
          confirmText: StudentStrings.yes,
          cancelText: StudentStrings.skip,
          icon: Icons.family_restroom,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      );

      if (addAnother == true) {
        if (!mounted) return;
        final storage = serviceLocator<StorageService>();
        final schoolCode =
            await storage.getString(StorageKeys.schoolCode) ?? '';
        if (!mounted) return;

        final nextParentResult = await context.push<bool>(
          AddStudentStep2Screen.routeName,
          extra: <String, dynamic>{
            'studentCode': studentCode,
            'schoolCode': schoolCode,
            'createGuardianDirectly': true,
            'isOptionalStep': true,
          },
        );

        if (!mounted) return;
        await _onParentStepResult(
          studentCode: studentCode,
          studentName: studentName,
          justAddedParent: nextParentResult == true,
          parentCount: nextParentResult == true ? parentCount + 1 : parentCount,
        );
        return;
      }
    }

    if (!mounted) return;

    // After parent completion (or it being skipped/cancelled), ask for schedule.
    final addSchedule = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (context) => ConfirmationBottomSheet(
        title: StudentStrings.doYouWantToAddSchedule,
        confirmText: StudentStrings.yes,
        cancelText: StudentStrings.skip,
        icon: Icons.schedule,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    dynamic scheduleData;
    if (addSchedule == true) {
      if (!mounted) return;
      final step3Result = await context.push(AddStudentStep3Screen.routeName);
      if (step3Result is Map<String, Map<String, TimeOfDay>>) {
        scheduleData = step3Result;
      } else if (step3Result is Map) {
        scheduleData = Map<String, Map<String, TimeOfDay>>.from(
          step3Result.map(
            (k, v) =>
                MapEntry(k.toString(), Map<String, TimeOfDay>.from(v as Map)),
          ),
        );
      }
    }

    if (!mounted) return;
    await _finalizeWizard(
      studentCode: studentCode,
      studentName: studentName,
      schedule: scheduleData,
    );
  }

  /// Student and parent are already saved by this point (each via its own
  /// API call). This only saves the optional schedule and closes the wizard.
  Future<void> _finalizeWizard({
    required String studentCode,
    required String studentName,
    required dynamic schedule,
  }) async {
    try {
      if (schedule is Map) {
        final storage = serviceLocator<StorageService>();
        final schoolCode =
            await storage.getString(StorageKeys.schoolCode) ?? '';
        final rawSchedule = Map<String, dynamic>.from(schedule);
        final List<Map<String, dynamic>> payloadSchedule = [];

        String formatLocalTime(TimeOfDay time) {
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
            'startTime': formatLocalTime(start),
            'halfDay': formatLocalTime(halfDay),
            'endTime': formatLocalTime(end),
          });
        }

        if (payloadSchedule.isNotEmpty && schoolCode.isNotEmpty) {
          final remote = serviceLocator<StudentRemoteDataSource>();
          await remote.updateStudentRegularSchedules(
            schoolCode: schoolCode,
            studentCode: studentCode,
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

    if (!mounted) return;

    final bool anyPhotoUploading = _createCubit.state.step1ProfilePhoto != null;
    CoreUtils.showTopSnackBar(
      context: context,
      message:
          'Student${studentName.isNotEmpty ? ' $studentName ' : ' '}added successfully'
          '${anyPhotoUploading ? '. Photo is uploading in the background…' : ''}',
      isSuccess: true,
    );

    Navigator.pop(context, {
      'showPostAddPrompt': true,
      'studentName': studentName,
      'studentCode': studentCode,
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocBuilder<StudentCreateCubit, StudentCreateState>(
      bloc: _createCubit,
      builder: (context, createState) =>
          BlocBuilder<ClassroomCubit, ClassroomState>(
            builder: (context, classroomState) {
              final classroomNames = classroomState.classrooms
                  .map((c) => c.name)
                  .toList();

              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Scaffold(
                  backgroundColor: AppColors.pageBackgroundColor,
                  appBar: const CustomAppBar(hasBackButton: true),
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: AppColors.pageBackgroundColor),
                      ),
                      Column(
                        children: [
                          AppSpacing.gapVMd,
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.horizontalSpacing,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                StudentStrings.addStudentStep1Of3,
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: responsive.titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                          Expanded(
                            child: Container(
                              width: responsive.containerWidth,
                              margin: EdgeInsets.symmetric(
                                horizontal: responsive.horizontalSpacing,
                              ),
                              padding: EdgeInsets.all(
                                responsive.isTablet ? 32.0 : 16.0,
                              ),
                              decoration: AppSurfaces.card(borderRadius: BorderRadius.all( Radius.circular( responsive.isTablet ? 40.0 : 24.0, ), )),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.zero,
                                      children: [
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // Status
                                        CustomDropdown(
                                          label: StudentStrings.status,
                                          hintText: StudentStrings.select,
                                          items: _statusOptions,
                                          selectedItem:
                                              _createCubit.state.step1Status,
                                          labelStyle: TextStyle(
                                            fontSize: responsive.labelFontSize,
                                            fontFamily: AppFonts.body,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.primaryColor,
                                          ),
                                          showAsterisk: true,
                                          labelBottomSpacing:
                                              responsive.isTablet ? 8.0 : 6.0,
                                          onSelect: (val) =>
                                              _createCubit.setStep1Status(val),
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // First Name and Last Name
                                        _buildRowInputs(context),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // Classroom
                                        CustomDropdown(
                                          label: StudentStrings.classroom,
                                          hintText: StudentStrings.select,
                                          items: classroomNames,
                                          selectedItem:
                                              _createCubit.state.step1Classroom,
                                          labelStyle: TextStyle(
                                            fontSize: responsive.labelFontSize,
                                            fontFamily: AppFonts.body,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.primaryColor,
                                          ),
                                          showAsterisk: true,
                                          labelBottomSpacing:
                                              responsive.isTablet ? 8.0 : 6.0,
                                          onSelect: (val) => _createCubit
                                              .setStep1Classroom(val),
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // Profile Photo
                                        _buildProfilePhotoField(responsive),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // Birthdate
                                        _buildDateField(
                                          StudentStrings.birthdate,
                                          _createCubit.state.step1Birthdate,
                                          _selectBirthdate,
                                          isRequired: _isActive,
                                          ageLabel:
                                              _createCubit.state.step1AgeLabel,
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // School Start Date
                                        _buildDateField(
                                          StudentStrings.schoolStartDate,
                                          _createCubit
                                              .state
                                              .step1SchoolStartDate,
                                          _selectSchoolStartDate,
                                          isRequired: _isUpcoming,
                                        ),
                                        AppSpacing.gapVSm,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapVSm,
                        ],
                      ),
                    ],
                  ),
                  bottomNavigationBar: Container(
                    padding: EdgeInsets.only(
                      bottom: safeAreaBottom,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      top: AppSpacing.xs,
                    ),
                    decoration: AppSurfaces.card(borderRadius: BorderRadius.only( topLeft: Radius.circular( responsive.isTablet ? 40.0 : 24.0, ), topRight: Radius.circular( responsive.isTablet ? 40.0 : 24.0, ), )),
                    child: CustomButtonLayout(
                      confirmButtonLabel: StudentStrings.next,
                      onPressedConfirm: _createCubit.state.step1Submitting
                          ? null
                          : _onNext,
                      showCancelButton: false,
                      isForm: false,
                      isLoading: _createCubit.state.step1Submitting,
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildRowInputs(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            StudentStrings.firstName,
            StudentStrings.eGJohn,
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
            StudentStrings.lastName,
            StudentStrings.eGSmith,
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
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.errorColor),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: controller,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(
                color: AppColors.attendanceMutedTextColor,
              ),
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
          StudentStrings.profilePhoto,
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.attendanceShimmerHighlightColor,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.inputBorderColor),
            ),
            child: _createCubit.state.step1ProfilePhoto != null
                ? ClipRRect(
                    borderRadius: AppRadius.allMd,
                    child: Image.file(
                      _createCubit.state.step1ProfilePhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: AppColors.attendanceDialogHintTextColor,
                        size: AppDimensions.iconLg,
                      ),
                      AppSpacing.gapVXs,
                      Text(
                        StudentStrings.uploadPhoto,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.attendanceDialogHintTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        AppSpacing.gapVXxs,
        Text(
          StudentStrings.jpgPngMax10mbOptional,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.attendanceDialogHintTextColor,
            fontFamily: AppFonts.body,
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
    String? ageLabel,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
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
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.errorColor),
                ),
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
              color: AppColors.whiteColor,
              border: Border.all(color: AppColors.inputBorderColor),
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
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
                              : StudentStrings.selectDate,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: responsive.inputFontSize,
                            fontWeight: selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppColors.primaryColor,
                            height: 19 / 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ageLabel != null && selectedDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xxs),
                            child: Text(
                              'Age: $ageLabel',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.attendanceDialogHintTextColor,
                                fontFamily: AppFonts.body,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapHXxs,
                  AppIcon(
                    MediaRes.calender_icon,
                    height: 20.0,
                    color: AppColors.primaryColor,
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
