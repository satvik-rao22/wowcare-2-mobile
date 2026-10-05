import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'dart:convert';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

enum StudentFilterSection { classroom, status, tags, parents, attendance }

class StudentFilterScreen extends StatefulWidget {
  const StudentFilterScreen({
    super.key,
    this.initialFilters,
    this.sections = const [
      StudentFilterSection.classroom,
      StudentFilterSection.status,
      StudentFilterSection.tags,
      StudentFilterSection.parents,
      StudentFilterSection.attendance,
    ],
    this.allowCrossClassAttendance,
  });

  static const String routeName = '/student-filter';

  final Map<String, List<String>>? initialFilters;
  final List<StudentFilterSection> sections;

  /// Non-null only when this screen is opened from a STUDENT ATTENDANCE
  /// context (Daily view). When set, the Classroom section's accessibility
  /// follows the school's `allowTeacherCrossClassAttendance` setting instead
  /// of the legacy per-designation restriction below: `true` means the
  /// classroom list is unrestricted (like an admin), `false` means it's
  /// scoped to the staff member's allowed classrooms. Left `null` for other
  /// callers (e.g. the general Students roster), which keep their existing
  /// designation-based behavior unchanged.
  final bool? allowCrossClassAttendance;

  @override
  State<StudentFilterScreen> createState() => _StudentFilterScreenState();
}

class _StudentFilterScreenState extends State<StudentFilterScreen> {
  List<String> get _labelList {
    return widget.sections.map((s) {
      switch (s) {
        case StudentFilterSection.classroom:
          return 'Classroom';
        case StudentFilterSection.status:
          return 'Status';
        case StudentFilterSection.tags:
          return 'Tags';
        case StudentFilterSection.parents:
          return 'Parents';
        case StudentFilterSection.attendance:
          return 'Attendance';
      }
    }).toList();
  }

  // Options
  List<String> _classroomList = [];
  final List<String> _statusList = const ['Active', 'Upcoming'];
  List<String> _tagsList = const [];
  List<String> _parentsList = const [];
  final List<String> _attendanceList = const [
    'Signed-In',
    'Signed-Out',
    'Not-Marked',
    'Absent',
  ];

  // Selected
  List<String> _selectedClassroomList = [];
  List<String> _selectedStatusList = [];
  List<String> _selectedTagsList = [];
  List<String> _selectedParentsList = [];
  List<String> _selectedAttendanceList = [];

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  late final StorageService _storageService;
  String _staffDesignationLower = '';
  Set<String> _allowedClassroomCodes = <String>{};

  static const Set<String> _restrictedDesignationLabelsLower = <String>{
    'associate teacher',
    'assistant teacher',
    'floater',
    'lead teacher',
  };

  @override
  void initState() {
    super.initState();

    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _getTagNamesForSchoolUseCase =
        serviceLocator<GetTagNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();
    _preloadStaffScope();

    final initial = widget.initialFilters ?? const {};
    _selectedClassroomList = List<String>.from(
      initial['Classroom'] ?? const [],
    );
    _selectedStatusList = List<String>.from(
      initial['Status'] ?? const ['Active'],
    );
    _selectedTagsList = List<String>.from(initial['Tags'] ?? const []);
    _selectedParentsList = List<String>.from(initial['Parents'] ?? const []);
    _selectedAttendanceList = List<String>.from(
      initial['Attendance'] ?? const [],
    );

    if (widget.sections.contains(StudentFilterSection.status)) {
      if (_selectedStatusList.isEmpty) {
        _selectedStatusList = ['Active'];
      } else if (_selectedStatusList.length > 1) {
        _selectedStatusList = [_selectedStatusList.last];
      }
    }

    if (widget.sections.contains(StudentFilterSection.classroom)) {
      _fetchFilterData();
    }
    if (widget.sections.contains(StudentFilterSection.tags)) {
      _loadTags();
    }
    if (widget.sections.contains(StudentFilterSection.parents)) {
      _loadParents();
    }
  }

  Future<void> _preloadStaffScope() async {
    try {
      final d =
          (await _storageService.getString(StorageKeys.staffDesignation) ?? '')
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ');
      final raw =
          (await _storageService.getString(
                    StorageKeys.staffAllowedClassroomCodes,
                  ) ??
                  '')
              .trim();
      final codes = <String>{};
      if (raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final e in decoded) {
              if (e is String) {
                final c = e.trim();
                if (c.isNotEmpty) codes.add(c);
              } else if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                final c = (m['code'] ?? m['classroomCode'] ?? '')
                    .toString()
                    .trim();
                if (c.isNotEmpty) codes.add(c);
              }
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _staffDesignationLower = d;
        _allowedClassroomCodes = codes;
      });
    } catch (_) {
      // Non-blocking
    }
  }

  void _fetchFilterData() {
    final crossClass = widget.allowCrossClassAttendance;
    context.read<ClassroomCubit>().loadActiveClassrooms(
      force: true,
      // Student-attendance context: honor the resolved cross-class flag from
      // the Daily view instead of always scoping. Other callers (crossClass
      // == null) keep the original always-scoped behavior.
      applyAttendanceStaffScope: crossClass == null ? true : !crossClass,
    );
  }

  Future<void> _loadTags() async {
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final names = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      // Names list is enough for UI; codes are resolved when applying filters
      // by using the same names and a separate codes lookup if needed.
      setState(() {
        _tagsList = names;
        _selectedTagsList.removeWhere((tag) => !_tagsList.contains(tag));
      });
    } catch (_) {
      // Non-critical for filters; ignore errors.
    }
  }

  Future<void> _loadParents() async {
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final names = await _getGuardianNamesForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (!mounted) return;

      setState(() {
        _parentsList = names;
        _selectedParentsList.removeWhere(
          (parent) => !_parentsList.contains(parent),
        );
      });
    } catch (_) {
      // For filter dropdowns this is non-critical; ignore errors silently.
    }
  }

  void _applyFilters() {
    final result = <String, List<String>>{};
    if (widget.sections.contains(StudentFilterSection.classroom)) {
      result['Classroom'] = List<String>.from(_selectedClassroomList);
    }
    if (widget.sections.contains(StudentFilterSection.status)) {
      result['Status'] = List<String>.from(_selectedStatusList);
    }
    if (widget.sections.contains(StudentFilterSection.tags)) {
      result['Tags'] = List<String>.from(_selectedTagsList);
    }
    if (widget.sections.contains(StudentFilterSection.parents)) {
      result['Parents'] = List<String>.from(_selectedParentsList);
    }
    if (widget.sections.contains(StudentFilterSection.attendance)) {
      result['Attendance'] = List<String>.from(_selectedAttendanceList);
    }

    context.pop<Map<String, List<String>>>(<String, List<String>>{...result});
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: StudentStrings.filterStudents,
      child: _buildFilterContent(),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    return CustomButtonLayout(
      confirmButtonLabel: StudentStrings.applyFilters,
      onPressedConfirm: _applyFilters,
      showCancelButton: false,
      isForm: false,
    );
  }

  Widget _buildFilterContent() {
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        final role = context.watch<RoleCubit>();
        // In the student-attendance context, the ClassroomCubit state passed
        // in already reflects the correct scope (allowed-only, or unrestricted
        // when cross-class attendance is enabled) — the legacy per-designation
        // restriction below must not re-narrow or bypass that.
        final restrictToAllowed =
            widget.allowCrossClassAttendance == null &&
            role.isStaff &&
            _restrictedDesignationLabelsLower.contains(
              _staffDesignationLower,
            ) &&
            _allowedClassroomCodes.isNotEmpty;

        final classroomNames = restrictToAllowed
            ? classroomState.classrooms
                  .where((c) => _allowedClassroomCodes.contains(c.code.trim()))
                  .map((c) => c.name)
                  .toList()
            : classroomState.classrooms.map((c) => c.name).toList();

        // Keep classroom list in sync with the current scope (all vs allowed-only).
        // Previously we only set it once, which caused "all classrooms" to stick.
        final nextClassroomList = List<String>.from(classroomNames);
        if (!listEquals(nextClassroomList, _classroomList)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _classroomList = nextClassroomList;
              _selectedClassroomList.removeWhere(
                (item) => !_classroomList.contains(item),
              );
            });
          });
        }

        List<String> _optionsFor(StudentFilterSection section) {
          switch (section) {
            case StudentFilterSection.classroom:
              return _classroomList;
            case StudentFilterSection.status:
              return _statusList;
            case StudentFilterSection.tags:
              return _tagsList;
            case StudentFilterSection.parents:
              return _parentsList;
            case StudentFilterSection.attendance:
              return _attendanceList;
          }
        }

        List<String> _selectedFor(StudentFilterSection section) {
          switch (section) {
            case StudentFilterSection.classroom:
              return _selectedClassroomList;
            case StudentFilterSection.status:
              return _selectedStatusList;
            case StudentFilterSection.tags:
              return _selectedTagsList;
            case StudentFilterSection.parents:
              return _selectedParentsList;
            case StudentFilterSection.attendance:
              return _selectedAttendanceList;
          }
        }

        // Consider API-driven data (classrooms, tags, parents) independently.
        // Even if one API fails, the others can still populate their dropdowns.
        // Status options are always available; allow rendering when only Status/Tags are shown
        // even if tag names are still loading (tags dropdown can populate after).
        final hasAnyApiData =
            widget.sections.contains(StudentFilterSection.status) ||
            (widget.sections.contains(StudentFilterSection.classroom) &&
                _classroomList.isNotEmpty) ||
            (widget.sections.contains(StudentFilterSection.tags) &&
                _tagsList.isNotEmpty) ||
            (widget.sections.contains(StudentFilterSection.parents) &&
                _parentsList.isNotEmpty);

        if (hasAnyApiData) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final section = widget.sections[index];
              final label = _labelList[index];
              final items = _optionsFor(section);
              final selected = _selectedFor(section);

              // Status is a true single-select dropdown, not a checkbox list —
              // picking both Active + Upcoming used to leave Upcoming
              // students missing from the roster (whatever combined
              // `status=ACTIVE&status=UPCOMING` request the backend
              // received didn't return them), so only one can be chosen.
              if (section == StudentFilterSection.status) {
                return CustomDropdown(
                  label: label,
                  hintText: StudentStrings.select,
                  showAsterisk: false,
                  items: items,
                  selectedItem: selected.isNotEmpty ? selected.first : 'Active',
                  onSelect: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedStatusList = [value];
                    });
                  },
                );
              }

              return CustomMultiSelectDropdown(
                label: label,
                hintText: StudentStrings.select,
                showSelectAll: true,
                items: items,
                selectedItems: selected,
                onChanged: (selectedItems) {
                  setState(() {
                    selected
                      ..clear()
                      ..addAll(selectedItems);
                  });
                },
              );
            },
          );
        }

        // Loading state
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: _labelList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelList[index],
                  style: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                AppSpacing.gapVXs,
                const ShimmerLoader(height: 40),
              ],
            );
          },
        );
      },
    );
  }
}
