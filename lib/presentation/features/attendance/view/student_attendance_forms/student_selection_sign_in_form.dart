import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_search_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_sign_in_selection_cubit.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_select_all_row.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_selectable_person_tile.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'guardian_student_selection_scope.dart';
import 'student_sign_in_form.dart';

class StudentSelectionSignInForm extends StatefulWidget {
  static const String routeName = '/student-selection-sign-in-form';

  const StudentSelectionSignInForm({
    super.key,
    this.isQrScan = false,
    this.qrToken = '',
    this.preSelectedStudentCode,
    this.allowedStudentCodes,
    this.isKiosk = false,
    this.guardianCode,
    this.pin,
  });

  /// True when opened after a QR code scan. Passed down to [StudentSignInForm]
  /// so the API payload uses method=QR and withinGeofence=true.
  final bool isQrScan;

  /// QR token from the scanned code (only set when isQrScan=true).
  /// Passed to StudentSignInForm for inclusion in the API payload.
  final String qrToken;

  /// When set (GPS flow), this student is pre-selected after the list loads.
  final String? preSelectedStudentCode;

  /// List of student codes that are allowed to be shown/selected.
  final List<String>? allowedStudentCodes;

  /// True when called from kiosk flow (guardian persona).
  final bool isKiosk;

  /// Guardian code from kiosk PIN verification.
  final String? guardianCode;

  /// PIN from kiosk access. Passed to StudentSignInForm for API payload.
  final String? pin;

  @override
  State<StudentSelectionSignInForm> createState() =>
      _StudentSelectionSignInFormState();
}

class _StudentSelectionSignInFormState
    extends State<StudentSelectionSignInForm> {
  bool _preSelectionApplied = false;
  bool isSelectAllChecked = false;
  List<String> _selectedClassrooms = [];
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  /// Parent persona: only linked children; hide classroom/tag filters.
  late final bool _restrictToGuardianChildren;

  late final StudentSignInSelectionCubit _cubit;

  /// Resolved once at mount (rarely changes mid-session) rather than
  /// re-fetched on every filter change, unlike the old per-fetch call.
  Set<String>? _allowUpper;

  @override
  void initState() {
    super.initState();
    AppLogger.d(
      '[Kiosk] StudentSelectionSignInForm initState: pin=${widget.pin}, isKiosk=${widget.isKiosk}, guardianCode=${widget.guardianCode}',
    );
    _restrictToGuardianChildren = context.read<RoleCubit>().isParent;
    _cubit = serviceLocator<StudentSignInSelectionCubit>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _allowUpper = await loadGuardianStudentAllowlistForSelection(context);
    if (!_restrictToGuardianChildren) {
      await _cubit.initFilters();
      // Staff persona: pre-select their primary classroom, if resolvable.
      final defaultClassroom = _cubit.state.defaultClassroomName;
      if (defaultClassroom != null) {
        _selectedClassrooms = [defaultClassroom];
      }
    }
    await _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStudents() async {
    await bootstrapAttendanceSchoolTimezone();
    final dateString = _formatDate(attendanceSchoolToday());
    await _cubit.loadStudents(
      fromAttendanceDate: dateString,
      toAttendanceDate: dateString,
      selectedClassroomNames: _selectedClassrooms,
      selectedTagNames: _selectedTag,
      search: _searchController.text,
    );
  }

  /// Applies the guardian allowlist + [StudentSelectionSignInForm.allowedStudentCodes]
  /// scoping and maps the cubit's raw API items into the UI's [StudentEntity].
  List<StudentEntity> _mapStudents(List<StudentAttendanceCustomItem> items) {
    var filtered = items;
    if (_allowUpper != null) {
      filtered = filtered
          .where(
            (i) => studentCodeAllowedForGuardianAllowlist(
              i.studentCode,
              _allowUpper!,
            ),
          )
          .toList();
    }
    if (widget.allowedStudentCodes != null) {
      final allowedUpper = widget.allowedStudentCodes!
          .map((c) => c.trim().toUpperCase())
          .toSet();
      filtered = filtered
          .where(
            (i) =>
                i.studentCode.trim().isNotEmpty &&
                allowedUpper.contains(i.studentCode.trim().toUpperCase()),
          )
          .toList();
    }
    return filtered.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return StudentEntity(
        id: index + 1,
        studentCode: item.studentCode,
        fullName: item.studentName,
        roomId: 0,
        roomName: item.classroomName,
        classroomCode: item.classroomCode,
        photoUuid: null,
        isExpectedToday: item.isExpectedToday,
      );
    }).toList();
  }

  /// Reacts to a fresh student list: prunes stale selections and applies the
  /// GPS/kiosk pre-selection exactly once (first successful load only).
  void _onStudentsChanged(List<StudentEntity> students) {
    selectedStudents.removeWhere(
      (s) => !students.any((e) => e.studentCode == s.studentCode),
    );

    if (!_preSelectionApplied && widget.preSelectedStudentCode != null) {
      _preSelectionApplied = true;
      final code = widget.preSelectedStudentCode!.trim();
      final match = students.where((s) => s.studentCode == code).firstOrNull;
      if (match != null) selectedStudents.add(match);
    }

    if (!_preSelectionApplied && widget.allowedStudentCodes != null) {
      _preSelectionApplied = true;
      selectedStudents.addAll(students);
    }

    isSelectAllChecked =
        students.isNotEmpty &&
        students.every((s) => selectedStudents.contains(s));
  }

  void _toggleSelectAll(bool? value, List<StudentEntity> students) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      if (value) {
        selectedStudents.addAll(students);
      } else {
        selectedStudents.removeAll(students);
      }
    });
  }

  void _toggleStudentSelection(
    StudentEntity student,
    bool? value,
    List<StudentEntity> students,
  ) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStudents.add(student);
      } else {
        selectedStudents.remove(student);
      }

      isSelectAllChecked = students.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  void refreshCallback() {
    // Reset selections + filters when returning from sign-in form, and
    // re-fetch so the list reflects the cleared filters (not a stale,
    // still-filtered cache).
    setState(() {
      isSelectAllChecked = false;
      selectedStudents.clear();
      _selectedClassrooms.clear();
      _selectedTag.clear();
    });
    _loadStudents();
  }

  void _handleNext() {
    if (selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Please select at least one student'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    // GoRouter holdout (documented): carries a refreshCallback closure and a form-local StudentEntity list, which don't fit GoRouter's URL/extra model — kept as an imperative Navigator.push.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSignInForm(
          students: selectedStudents.toList(),
          refreshCallback: refreshCallback,
          isQrScan: widget.isQrScan,
          qrToken: widget.qrToken,
          isKiosk: widget.isKiosk,
          guardianCode: widget.guardianCode,
          pin: widget.pin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

    return BlocConsumer<
      StudentSignInSelectionCubit,
      StudentSignInSelectionState
    >(
      bloc: _cubit,
      listenWhen: (previous, current) => previous.students != current.students,
      listener: (context, state) {
        setState(() {
          _onStudentsChanged(_mapStudents(state.students));
        });
      },
      builder: (context, state) {
        final students = _mapStudents(state.students);

        return StaffFormLayout(
          isKiosk: widget.isKiosk,
          title: 'Sign-In',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isKiosk) ...[
                AppText.subtitle(
                  _restrictToGuardianChildren
                      ? 'Select your children'
                      : 'Select Students',
                ),
                const SizedBox(height: AppSpacing.sm),
                AttendanceSearchField(
                  controller: _searchController,
                  hintText: _restrictToGuardianChildren
                      ? 'Search your children'
                      : 'Search Students',
                  onChanged: (_) => _loadStudents(),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!_restrictToGuardianChildren) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomMultiSelectDropdown(
                          hintText: 'Classroom',
                          items: state.classroomOptions,
                          selectedItems: _selectedClassrooms,
                          onChanged: (selectedItems) {
                            if (state.isLoadingFilters) return;
                            setState(() {
                              _selectedClassrooms = selectedItems;
                            });
                            _loadStudents();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: CustomMultiSelectDropdown(
                          hintText: 'Tags',
                          items: state.tagOptions,
                          selectedItems: _selectedTag,
                          onChanged: (selectedItems) {
                            setState(() {
                              _selectedTag = selectedItems;
                            });
                            _loadStudents();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AttendanceSelectAllRow(
                  isChecked: isSelectAllChecked,
                  onChanged: (value) => _toggleSelectAll(value, students),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Expanded(
                child: state.isLoadingStudents
                    ? const Center(child: PrimaryCircularLoader())
                    : state.studentsError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.body(
                              state.studentsError ?? 'Failed to load students',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.errorColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              onPressed: _loadStudents,
                              child: const AppText.body('Retry'),
                            ),
                          ],
                        ),
                      )
                    : students.isEmpty
                    ? Center(
                        child: AppText.body(
                          _restrictToGuardianChildren
                              ? 'No linked children appear in today\'s sign-in list. If this looks wrong, check the child selector at the top of the app.'
                              : 'No students found',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: isTablet ? 16 : 12,
                          mainAxisSpacing: isTablet ? 16 : 12,
                          mainAxisExtent: 72,
                        ),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final isSelected = selectedStudents.contains(student);

                          return AttendanceSelectablePersonTile(
                            name: student.fullName,
                            photoUuid: student.photoUuid ?? '',
                            code: student.studentCode,
                            isSelected: isSelected,
                            showOnlyAbsentAttendanceDot: true,
                            onSelectionChanged: (value) =>
                                _toggleStudentSelection(
                                  student,
                                  value,
                                  students,
                                ),
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomBar: Padding(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            child: CustomButtonLayout(
              confirmButtonLabel: 'Next',
              onPressedConfirm: _handleNext,
              showCancelButton: false,
            ),
          ),
        );
      },
    );
  }
}
