import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// UI-only: use wowcare widgets and theme; backend/bloc imports removed
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/classroom/utils/classroom_age_range.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_students_cubit.dart';

// UI-only lightweight types
class _TagEntity {
  final String name;
  const _TagEntity(this.name);
}

class StudentEntity {
  final int id;
  final String code;
  final String fullName;
  final String? profileImageUrl;
  final String? profilePhotoAssetCode;
  final String? roomName;
  final String? roomCode;
  final List<_TagEntity> tags;

  /// Raw DOB string from the student list (may be empty / unparseable). Kept so
  /// the assign flow can WARN when a student's age is outside the target room.
  final String dob;
  const StudentEntity({
    required this.id,
    required this.code,
    required this.fullName,
    this.profileImageUrl,
    this.profilePhotoAssetCode,
    this.roomName,
    this.roomCode,
    this.tags = const [],
    this.dob = '',
  });
}

class AssignStudentToClassroomForm extends StatefulWidget {
  final VoidCallback onStudentsAssigned; // Add this line
  final String selectedRoomName;
  final String classroomCode;

  const AssignStudentToClassroomForm({
    required this.onStudentsAssigned,
    required this.selectedRoomName,
    required this.classroomCode,
    super.key,
  });

  @override
  State<AssignStudentToClassroomForm> createState() =>
      _AssignStudentToClassroomFormState();
}

class _AssignStudentToClassroomFormState
    extends State<AssignStudentToClassroomForm> {
  static const int _pageSize = 200;

  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  final List<StudentEntity> _allStudents = [];
  final List<String> _allRooms = [];
  final List<String> _allTags = [];
  Set<String> _assignedStudentCodes = {};
  bool _isLoadingStudents = false;
  String? _studentsError;
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Today's sign-in status per student code — drives disabling the
  // selection checkbox for students who are currently signed in (they can't
  // be reassigned to another classroom while signed in).
  Map<String, String> _todayStatusByCode = {};

  bool _isStudentSignedIn(String code) {
    final gate = studentAttendanceGateFromTodayStatus(
      isActiveProfile: true,
      todayStatusRaw: _todayStatusByCode[code],
    );
    return gate.isSignedInToday;
  }

  @override
  void initState() {
    super.initState();
    try {
      final cubit = serviceLocator<ClassroomStudentsCubit>();
      _assignedStudentCodes = cubit.state.students
          .map((s) => s.studentCode.trim().toUpperCase())
          .where((code) => code.isNotEmpty)
          .toSet();
    } catch (_) {}
    _loadStudentsFromApi();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsFromApi() async {
    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) {
        throw 'School code is not set. Please sign in and select a school.';
      }

      final getStudentPageUseCase = serviceLocator<GetStudentPageUseCase>();

      // Fetch all active classrooms to get the "rest" of the classrooms
      final activeClassrooms =
          await serviceLocator<GetActiveClassroomsUseCase>()(
            schoolCode: schoolCode,
            onlyTypeClassroom: true,
          );

      // Filter out the target classroom to get available classrooms
      final availableClassrooms = activeClassrooms
          .where((classroom) => classroom.code != widget.classroomCode)
          .toList();

      final classroomCodes = availableClassrooms
          .map((classroom) => classroom.code)
          .toList();

      final fetchedStudents = <StudentEntity>[];
      final uniqueRooms = <String>{};
      final uniqueTags = <String>{};

      int page = 0;
      bool hasMore = true;
      while (hasMore) {
        final studentPage = await getStudentPageUseCase(
          schoolCode: schoolCode,
          page: page,
          size: _pageSize,
          status: 'ACTIVE',
          classroomCodes: classroomCodes,
        );

        for (final s in studentPage.items) {
          final tagEntities = s.tags
              .where((t) => t.trim().isNotEmpty)
              .map((t) => _TagEntity(t.trim()))
              .toList();
          fetchedStudents.add(
            StudentEntity(
              id: fetchedStudents.length + 1,
              code: s.code,
              fullName: s.fullName,
              profileImageUrl: (s.profileImage ?? '').trim().isEmpty
                  ? null
                  : s.profileImage!.trim(),
              profilePhotoAssetCode:
                  (s.profilePhotoAssetCode ?? '').trim().isEmpty
                  ? null
                  : s.profilePhotoAssetCode!.trim(),
              roomName: s.classroom,
              roomCode: s.classroomCode,
              tags: tagEntities,
              dob: s.dob,
            ),
          );
          if (s.classroom.trim().isNotEmpty) {
            uniqueRooms.add(s.classroom.trim());
          }
          for (final t in s.tags) {
            final normalized = t.trim();
            if (normalized.isNotEmpty) uniqueTags.add(normalized);
          }
        }

        hasMore = studentPage.hasMore;
        page += 1;
      }

      if (!mounted) return;
      setState(() {
        _allStudents
          ..clear()
          ..addAll(fetchedStudents);
        final availableRoomNames = availableClassrooms
            .map((c) => c.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        _allRooms
          ..clear()
          ..addAll(availableRoomNames..sort());
        _allTags
          ..clear()
          ..addAll(uniqueTags.toList()..sort());
        _filterStudents();
      });
      unawaited(_loadTodaySignInStatuses(fetchedStudents));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  /// Fetches today's sign-in status for every loaded student in one batch
  /// call, reusing the same use case the Student list/profile screens use —
  /// students currently signed in can't be reassigned to another classroom.
  Future<void> _loadTodaySignInStatuses(List<StudentEntity> students) async {
    final codes = students
        .map((s) => s.code.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isEmpty) return;
    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusMapUseCase>();
      final map = await useCase(studentCodes: codes);
      if (!mounted) return;
      setState(() => _todayStatusByCode = map);
    } catch (_) {
      // Non-critical: leave statuses empty so nothing is incorrectly
      // disabled if the status check itself fails.
    }
  }

  void _onSearchChanged() {
    // Debounce so the list filters once the user pauses typing.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _filterStudents();
    });
  }

  void _filterStudents() {
    final allStudents = _allStudents;
    _filteredStudents = allStudents.where((student) {
      // Exclude students whose current classroom matches the target classroom
      if (student.roomCode != null &&
          student.roomCode!.trim().toUpperCase() ==
              widget.classroomCode.trim().toUpperCase()) {
        return false;
      }
      // Fallback: exclude students already assigned to the selected classroom based on the Cubit
      if (_assignedStudentCodes.contains(student.code.trim().toUpperCase())) {
        return false;
      }
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesTag = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = student.fullName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (_selectedClassroom != null && _selectedClassroom != '') {
        matchesRoom = (student.roomName ?? '').contains(_selectedClassroom!);
      }

      if (_selectedTag.isNotEmpty) {
        matchesTag = student.tags.any((tag) => _selectedTag.contains(tag.name));
      }

      return matchesSearch && matchesRoom && matchesTag;
    }).toList();
    setState(() {});
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      // Get the current visible students based on filters, excluding
      // anyone currently signed in — they can't be selected at all.
      final List<StudentEntity> visibleStudents = _getVisibleStudents()
          .where((s) => !_isStudentSignedIn(s.code))
          .toList();

      if (value) {
        // Add all visible students to selection
        selectedStudents.addAll(visibleStudents);
      } else {
        // Remove all visible students from selection
        selectedStudents.removeAll(visibleStudents);
      }
    });
  }

  void _toggleStudentSelection(StudentEntity student, bool? value) {
    if (value == null || _isStudentSignedIn(student.code)) return;

    setState(() {
      if (value) {
        selectedStudents.add(student);
      } else {
        selectedStudents.remove(student);
      }

      // Update select all checkbox based on visible, selectable students.
      final visibleStudents = _getVisibleStudents().where(
        (s) => !_isStudentSignedIn(s.code),
      );
      isSelectAllChecked = visibleStudents.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  List<StudentEntity> _getVisibleStudents() {
    return _filteredStudents.isEmpty &&
            _searchController.text.isEmpty &&
            (_selectedClassroom?.isEmpty ?? true) &&
            _selectedTag.isEmpty
        ? _allStudents
        : _filteredStudents;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Assign to ${widget.selectedRoomName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Students',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SearchBar(
            controller: _searchController,
            constraints: const BoxConstraints(minHeight: 44),
            hintText: 'Search Students',
            hintStyle: WidgetStatePropertyAll(
              TextStyle(fontFamily: 'Manrope', color: AppColors.grey[700]),
            ),
            backgroundColor: const WidgetStatePropertyAll<Color>(
              AppColors.white,
            ),
            surfaceTintColor: const WidgetStatePropertyAll<Color>(
              AppColors.white,
            ),
            elevation: const WidgetStatePropertyAll<double>(0),
            side: const WidgetStatePropertyAll(
              BorderSide(width: 1, color: Color.fromARGB(255, 188, 173, 186)),
            ),
            leading: const Icon(Icons.search, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: CustomDropdown(
                  onSelect: (value) {
                    setState(() {
                      _selectedClassroom = value;
                      _filterStudents();
                    });
                  },
                  hintText: 'Classroom',
                  items: _allRooms
                      .where((name) => name != widget.selectedRoomName)
                      .toList(),
                  isField: true,
                  isEnabled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  showSelectAll: true,
                  items: _allTags,
                  selectedItems: _selectedTag,
                  onChanged: (selectedItems) {
                    setState(() {
                      _selectedTag = selectedItems;
                      _filterStudents();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll, // Add the handler here
                ),
              ),
              const Text('Select All', style: TextStyle(fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: PrimaryCircularLoader())
                : _studentsError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _studentsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadStudentsFromApi,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 72,
                        ),
                    itemCount: _getVisibleStudents().length,
                    itemBuilder: (context, index) {
                      final student = _getVisibleStudents()[index];
                      final isSelected = selectedStudents.contains(student);
                      return StudentListItem(
                        student: student,
                        isSelected: isSelected,
                        isSignedIn: _isStudentSignedIn(student.code),
                        onSelectionChanged: (value) {
                          _toggleStudentSelection(student, value);
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Next',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: () {
              if (selectedStudents.isEmpty) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select at least one student',
                  isWarning: true,
                );
                return;
              } else {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    maxChildSize: 0.95,
                    builder: (_, controller) => StudentConfirmationForm(
                      selectedStudents: selectedStudents,
                      selectedRoomName: widget.selectedRoomName,
                      classroomCode: widget.classroomCode,
                      onStudentsAssigned: widget.onStudentsAssigned,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class StudentConfirmationForm extends StatefulWidget {
  final Set<StudentEntity> selectedStudents;
  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStudentsAssigned;

  const StudentConfirmationForm({
    Key? key,
    required this.selectedStudents,
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStudentsAssigned,
  }) : super(key: key);

  @override
  State<StudentConfirmationForm> createState() =>
      _StudentConfirmationFormState();
}

class _StudentConfirmationFormState extends State<StudentConfirmationForm> {
  late Set<StudentEntity> currentSelectedStudents;
  bool _isSubmitting = false;

  /// Target classroom (with age bounds), loaded once on init. Null while loading
  /// or if the fetch fails — either way the age warning is simply skipped.
  Classroom? _targetClassroom;

  @override
  void initState() {
    super.initState();
    currentSelectedStudents = Set.from(widget.selectedStudents);
    unawaited(_loadTargetClassroom());
  }

  /// Resolves the target classroom's age bounds. Self-contained (uses the
  /// use case directly) so it doesn't depend on a ClassroomCubit being in scope.
  Future<void> _loadTargetClassroom() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (schoolCode.isEmpty) return;
      final classrooms = await serviceLocator<GetActiveClassroomsUseCase>()(
        schoolCode: schoolCode,
      );
      if (!mounted) return;
      for (final c in classrooms) {
        if (c.code.trim() == widget.classroomCode.trim()) {
          setState(() => _targetClassroom = c);
          return;
        }
      }
    } catch (_) {
      // Bounds unknown → the warning is skipped (never blocks the assign).
    }
  }

  /// Shows an amber confirm listing any selected students whose age is outside
  /// the target room. Returns true to proceed (including when there's nothing to
  /// warn about, or the room's bounds/DOBs are unknown).
  Future<bool> _confirmIfAnyOutsideAgeRange() async {
    final classroom = _targetClassroom;
    if (classroom == null) return true; // bounds unknown → don't block

    final outside = studentsOutsideAgeRange(
      classroom: classroom,
      students: currentSelectedStudents
          .map((s) => (name: s.fullName.trim(), dob: _parseDob(s.dob)))
          .toList(),
    );
    if (outside.isEmpty) return true;

    final names = outside.where((n) => n.isNotEmpty).toList();
    final subject = names.isEmpty
        ? '${outside.length} selected student(s)'
        : (names.length == 1 ? names.first : names.join(', '));
    // Same phrasing as the Edit Student flow's classroomAgeRangeWarning(),
    // adapted for a possibly-multiple selection, for consistency.
    final message =
        "$subject ${names.length == 1 ? 'is' : 'are'} outside the "
        "classroom's age range. Do you want to continue?";

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => ConfirmationBottomSheet(
        icon: Icons.warning_amber_rounded,
        title: message,
        confirmText: 'Continue anyway',
        cancelText: 'Cancel',
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result == true;
  }

  /// Parses the raw DOB string; null when empty / unparseable (skip the check).
  DateTime? _parseDob(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }

  void removeStudent(StudentEntity student) {
    setState(() {
      currentSelectedStudents.remove(student);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assign to ${widget.selectedRoomName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentSelectedStudents.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No students selected',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: const Color(0xff573353),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 72,
                ),
                itemCount: currentSelectedStudents.length,
                itemBuilder: (context, index) {
                  final student = currentSelectedStudents.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.themeColor),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(249, 245, 250, 1),
                    ),
                    child: Row(
                      children: [
                        DocumentImageWidget(
                          fileUuid: '',
                          imageUrl: student.profileImageUrl,
                          mediaAssetCode: student.profilePhotoAssetCode,
                          name: student.fullName,
                          studentCode: student.code,
                          size: 32,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: EllipsisTooltipText(
                            text: student.fullName.trim().isEmpty
                                ? 'Student'
                                : student.fullName.trim(),
                            maxLines: 2,
                            preferLongPress: true,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => removeStudent(student),
                          child: SvgPicture.asset(MediaRes.delete_icon),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Submit',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: _isSubmitting
                ? () {}
                : () async {
                    if (currentSelectedStudents.isEmpty) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Please select at least one student',
                        isWarning: true,
                      );
                      return;
                    }

                    // WARN (never block) if any selected student is outside the
                    // target room's age range — matching web "warn but allow".
                    final proceed = await _confirmIfAnyOutsideAgeRange();
                    if (!proceed || !mounted) return;

                    setState(() => _isSubmitting = true);
                    try {
                      final storage = serviceLocator<StorageService>();
                      final schoolCode = await storage.getString(
                        StorageKeys.schoolCode,
                      );
                      if (schoolCode == null || schoolCode.trim().isEmpty) {
                        throw 'Missing schoolCode. Please sign in / select a school again.';
                      }

                      // NOTE: In this UI module we only have the selected room name.
                      // The backend expects classroomCode; we pass the selectedRoomName
                      // as the code until the classroom code is wired into this form.
                      final classroomCode = widget.classroomCode.trim();
                      final studentCodes = currentSelectedStudents
                          .map((s) => s.code.trim())
                          .where((code) => code.isNotEmpty)
                          .toList();

                      final message =
                          await serviceLocator<
                            AssignStudentsToClassroomUseCase
                          >()(
                            schoolCode: schoolCode,
                            classroomCode: classroomCode,
                            studentCodes: studentCodes,
                          );

                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: message.isEmpty
                            ? 'Assigned successfully'
                            : message,
                        isSuccess: true,
                      );

                      widget.onStudentsAssigned();
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: e.toString(),
                        isError: true,
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class StudentListItem extends StatelessWidget {
  final StudentEntity student;
  final bool isSelected;
  final bool isSignedIn;
  final ValueChanged<bool?> onSelectionChanged;

  const StudentListItem({
    Key? key,
    required this.student,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSignedIn = false,
  }) : super(key: key);

  String get _disabledReason =>
      "This Student ${student.fullName.trim().isEmpty ? 'This student' : student.fullName.trim()} is already signed in. Please sign out before assigning to another classroom.";

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: () {
        if (isSignedIn) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: _disabledReason,
            isWarning: true,
          );
          return;
        }
        onSelectionChanged(!isSelected);
      },
      child: Opacity(
        opacity: isSignedIn ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.themeColor),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? const Color.fromARGB(255, 249, 245, 250)
                : AppColors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomCheckbox(
                    borderColor: AppColors.themeColor,
                    value: isSelected,
                    onChanged: isSignedIn ? null : onSelectionChanged,
                  ),
                ),
                DocumentImageWidget(
                  fileUuid: '',
                  imageUrl: student.profileImageUrl,
                  mediaAssetCode: student.profilePhotoAssetCode,
                  name: student.fullName,
                  studentCode: student.code,
                  size: 32,
                  fontSize: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EllipsisTooltipText(
                    text: student.fullName.trim().isEmpty
                        ? 'Student'
                        : student.fullName.trim(),
                    maxLines: 2,
                    preferLongPress: true,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isSignedIn) {
      return Tooltip(message: _disabledReason, child: content);
    }
    return content;
  }
}

// NOTE: Tags multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
