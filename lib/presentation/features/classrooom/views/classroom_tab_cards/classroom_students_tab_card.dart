import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/activity_status_panel.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_student_list_item.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_students_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_students_state.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart'
    as sign_in_form;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart'
    as sign_out_form;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart'
    as transfer_form;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart'
    as absent_form;

class ClassroomStudentsTabCard extends StatefulWidget {
  const ClassroomStudentsTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;

  @override
  State<ClassroomStudentsTabCard> createState() =>
      _ClassroomStudentsTabCardState();
}

class _ClassroomStudentsTabCardState extends State<ClassroomStudentsTabCard> {
  final TextEditingController _searchController = TextEditingController();
  late final ClassroomStudentsCubit _cubit;
  bool isSelectAllChecked = false;
  Map<String, bool> studentSelections = {};
  List<String> _selectedStatus = [];
  bool _isNappingFilter = false; // Toggle for napping students
  bool _isPresentFilter = false; // Toggle for present students
  StudentPanelType _currentPanel = StudentPanelType.none;
  bool _showActivitiesPanel = false;
  bool _isAttendanceActionLoading = false;
  bool _isPrefetchingAttendanceData = false;
  int _attendancePrefetchToken = 0;
  Map<String, sign_in_form.StudentEntity> _signInEntitiesByCode = {};
  Map<String, sign_out_form.StudentEntity> _signOutEntitiesByCode = {};
  Map<String, transfer_form.StudentEntity> _transferEntitiesByCode = {};
  Map<String, absent_form.StudentEntity> _absentEntitiesByCode = {};
  final Map<String, String> _attendanceStatusByStudentCode = <String, String>{};
  bool _attendanceStatusLoading = false;
  bool _attendanceStatusError = false;

  final List<String> statusDisplayValues = ['Active', 'Upcoming'];
  final List<String> statuses = ['ACTIVE', 'UPCOMING'];

  final List<String> tags = [
    'Tag 1',
    'Tag 2',
    'Tag 3',
  ];

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<ClassroomStudentsCubit>();
    _searchController.addListener(_onSearchChanged);
    _loadForSelectedRoom(refresh: false);
  }

  void _loadForSelectedRoom({required bool refresh}) {
    final classroomCode = widget.selectedRoom?.code ?? '';
    if (classroomCode.trim().isEmpty) return;

    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();

    final status = _selectedStatus.isEmpty ? null : List<String>.from(_selectedStatus);

    if (refresh) {
      _cubit.refresh(
        classroomCode: classroomCode,
        search: search,
        status: status,
      );
    } else {
      _cubit.loadInitial(
        classroomCode: classroomCode,
        search: search,
        status: status,
      );
    }
  }

  @override
  void didUpdateWidget(ClassroomStudentsTabCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoom != widget.selectedRoom) {
      setState(() {
        isSelectAllChecked = false;
        studentSelections.updateAll((key, val) => false);
        _searchController.clear();
        _selectedStatus = [];
        _isNappingFilter = false;
      });
      _loadForSelectedRoom(refresh: false);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce could be added later; for now refresh list from API as user types.
    _loadForSelectedRoom(refresh: false);
  }

  void _toggleSelectAll(
    bool? value,
    List<StudentClassroomItem> visibleStudents,
  ) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      for (final student in visibleStudents) {
        studentSelections[student.studentCode] = value;
      }
    });
    _prefetchAttendanceEntitiesForSelection(visibleStudents);
    _refreshAttendanceStatusForSelection(visibleStudents);
  }

  void _toggleStudentSelection(
    String studentCode,
    bool? value,
    List<StudentClassroomItem> visibleStudents,
  ) {
    if (value == null) return;

    setState(() {
      studentSelections[studentCode] = value;

      isSelectAllChecked = visibleStudents.every(
        (student) => studentSelections[student.studentCode] == true,
      );

      // Reset panel if no students are selected
      if (!hasSelectedStudents) {
        _currentPanel = StudentPanelType.none;
      }
    });
    _prefetchAttendanceEntitiesForSelection(visibleStudents);
    _refreshAttendanceStatusForSelection(visibleStudents);
  }

  bool get hasSelectedStudents {
    return studentSelections.values.any((selected) => selected);
  }

  void _clearAllSelections() {
    setState(() {
      isSelectAllChecked = false;
      studentSelections.updateAll((key, val) => false);
      _searchController.clear();
      _selectedStatus = ['ACTIVE'];
      _isNappingFilter = false;
      _currentPanel = StudentPanelType.none;
    });
    _clearAttendanceEntityCaches();
    _attendanceStatusByStudentCode.clear();
    _attendanceStatusLoading = false;
    _attendanceStatusError = false;
    _loadForSelectedRoom(refresh: false);
  }

  int get _selectedCount {
    return studentSelections.values.where((selected) => selected).length;
  }

  List<StudentClassroomItem> _getSelectedStudents(
    List<StudentClassroomItem> visibleStudents,
  ) {
    return visibleStudents
        .where((student) => studentSelections[student.studentCode] == true)
        .toList();
  }

  /// Same shape as [ChooseActivity.selectedStudents] for class activity list + create flow.
  List<Map<String, dynamic>> _activityStudentMaps(
    List<StudentClassroomItem> selected,
  ) {
    final roomCode = widget.selectedRoom?.code.trim() ?? '';
    return selected
        .map(
          (s) => <String, dynamic>{
            'name': s.fullName,
            'studentCode': s.studentCode,
            'classroomCode': s.classroomCode.trim().isNotEmpty
                ? s.classroomCode.trim()
                : roomCode,
          },
        )
        .toList();
  }

  Map<String, dynamic> _getStudentIcons(StudentClassroomItem student) {
    final icons = <String, dynamic>{};

    if (student.nap) {
      icons["napping"] = {
        "icon": 'assets/images/icons/sleep.png',
        "info": 'Student is napping',
      };
    }
    if (!student.photoPermission) {
      icons["photo"] = {
        "icon": MediaRes.cameraIcon,
        "info": 'No Photo Permission',
      };
    }
    if (student.medication) {
      icons["medication"] = {
        "icon": MediaRes.healthIcon,
        "info": 'Medication'
      };
    }
    if (student.notes) {
      icons["note"] = {"icon": MediaRes.docsIcon, "info": 'Notes'};
    }
    if (student.allergies) {
      icons["allergies"] = {
        "icon": MediaRes.alertIcon,
        "info": 'Allergies'
      };
    }
    if (student.dietaryRestriction) {
      icons["dietRestriction"] = {
        "icon": MediaRes.foodIcon2,
        "info": 'Dietary Restrictions'
      };
    }

    return icons;
  }

  List<String> _getCombinedOngoingActivities(
    List<StudentClassroomItem> selectedStudents,
  ) {
    // Current API entity doesn't expose activity list; keep empty for now.
    return const [];
  }

  bool _canShowActivitiesPanel(List<StudentClassroomItem> selectedStudents) {
    if (!hasSelectedStudents) return false;
    return selectedStudents.every((student) => student.signedIn);
  }

  // Backend disabled
  // Future<List<GuardianEntity>> getGuardianInfoForStudent(String studentId) async { return []; }

  // Backend disabled
  // Future<List<Staff>> fetchAllStaffs() async { return []; }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeStudentCode(String code) => code.trim().toUpperCase();

  String? _todayStatusForStudentCode(String code) {
    final t = code.trim();
    if (t.isEmpty) return null;
    if (_attendanceStatusByStudentCode.containsKey(t)) {
      return _attendanceStatusByStudentCode[t];
    }
    final u = _normalizeStudentCode(t);
    for (final e in _attendanceStatusByStudentCode.entries) {
      if (_normalizeStudentCode(e.key) == u) return e.value;
    }
    return null;
  }

  Future<void> _refreshAttendanceStatusForSelection(
    List<StudentClassroomItem> visibleStudents,
  ) async {
    final selected = _getSelectedStudents(visibleStudents);
    if (selected.isEmpty) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStudentCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      return;
    }

    final codes = selected
        .map((s) => s.studentCode.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    if (codes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStudentCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _attendanceStatusLoading = true;
      _attendanceStatusError = false;
    });

    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusMapUseCase>();
      final map = await useCase(studentCodes: codes);
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStudentCode
          ..clear()
          ..addAll(map);
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStudentCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = true;
      });
    }
  }

  StudentAttendanceActionAvailability _attendanceAvailabilityForSelection(
    List<StudentClassroomItem> selected,
  ) {
    if (selected.isEmpty) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    if (_attendanceStatusLoading || _attendanceStatusError) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    final gates = selected.map((s) {
      final isActive = s.status.trim().toUpperCase() == 'ACTIVE';
      return studentAttendanceGateFromTodayStatus(
        isActiveProfile: isActive,
        todayStatusRaw: _todayStatusForStudentCode(s.studentCode),
      );
    });
    return StudentAttendanceActionAvailability.fromGates(gates);
  }

  void _clearAttendanceEntityCaches() {
    _signInEntitiesByCode = {};
    _signOutEntitiesByCode = {};
    _transferEntitiesByCode = {};
    _absentEntitiesByCode = {};
  }

  Future<void> _prefetchAttendanceEntitiesForSelection(
    List<StudentClassroomItem> visibleStudents,
  ) async {
    final selectedStudents = _getSelectedStudents(visibleStudents);
    final selectedCodes = selectedStudents
        .map((s) => _normalizeStudentCode(s.studentCode))
        .where((c) => c.isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isPrefetchingAttendanceData = false;
        _clearAttendanceEntityCaches();
      });
      return;
    }

    final date = _formatDate(DateTime.now());
    final token = ++_attendancePrefetchToken;
    final roomCode = (widget.selectedRoom?.code ?? '').trim();
    final classroomCodes = roomCode.isEmpty ? null : <String>[roomCode];

    if (mounted) {
      setState(() {
        _isPrefetchingAttendanceData = true;
      });
    }

    try {
      final signInUseCase = serviceLocator<GetStudentSignInFormListUseCase>();
      final signOutUseCase = serviceLocator<GetStudentSignOutFormListUseCase>();
      final transferUseCase = serviceLocator<GetStudentTransferFormListUseCase>();
      final absentUseCase = serviceLocator<GetStudentAbsentFormListUseCase>();

      final signInFuture = signInUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final signOutFuture = signOutUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final transferFuture = transferUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final absentFuture = absentUseCase(
        fromAbsenceDate: date,
        toAbsenceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );

      // Attach listeners to all futures immediately so fast failures are caught.
      await Future.wait([
        signInFuture,
        signOutFuture,
        transferFuture,
        absentFuture,
      ]);
      final signInPage = await signInFuture;
      final signOutPage = await signOutFuture;
      final transferPage = await transferFuture;
      final absentPage = await absentFuture;
      if (!mounted || token != _attendancePrefetchToken) return;

      final signInMap = <String, sign_in_form.StudentEntity>{};
      for (final item in signInPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        signInMap[normalized] = sign_in_form.StudentEntity(
          id: signInMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
          photoUuid: null,
          isExpectedToday: item.isExpectedToday,
        );
      }

      final signOutMap = <String, sign_out_form.StudentEntity>{};
      for (final item in signOutPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        signOutMap[normalized] = sign_out_form.StudentEntity(
          id: signOutMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
        );
      }

      final transferMap = <String, transfer_form.StudentEntity>{};
      for (final item in transferPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        transferMap[normalized] = transfer_form.StudentEntity(
          id: transferMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
          tags: item.tagNames
              .map((name) => transfer_form.TagEntity(name: name))
              .toList(),
        );
      }

      final absentMap = <String, absent_form.StudentEntity>{};
      for (final item in absentPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        absentMap[normalized] = absent_form.StudentEntity(
          id: absentMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
        );
      }

      if (!mounted) return;
      setState(() {
        _signInEntitiesByCode = signInMap;
        _signOutEntitiesByCode = signOutMap;
        _transferEntitiesByCode = transferMap;
        _absentEntitiesByCode = absentMap;
      });
    } catch (_) {
      if (!mounted || token != _attendancePrefetchToken) return;
      setState(() {
        _clearAttendanceEntityCaches();
      });
    } finally {
      if (mounted && token == _attendancePrefetchToken) {
        setState(() {
          _isPrefetchingAttendanceData = false;
        });
      }
    }
  }

  Future<void> _openAttendanceActionFlow({
    required List<StudentClassroomItem> allStudents,
    required String actionName,
  }) async {
    final selectedStudents = _getSelectedStudents(allStudents);
    if (selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select at least one student',
        isError: true,
      );
      return;
    }

    final selectedCodes = selectedStudents
        .map((s) => _normalizeStudentCode(s.studentCode))
        .where((c) => c.isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected students are missing codes',
        isError: true,
      );
      return;
    }

    if (_isPrefetchingAttendanceData) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Preparing selected students. Please wait...',
        isError: true,
      );
      return;
    }

    setState(() {
      _isAttendanceActionLoading = true;
    });
    try {
      if (actionName == 'sign_in') {
        var entities = selectedCodes
            .map((code) => _signInEntitiesByCode[code])
            .whereType<sign_in_form.StudentEntity>()
            .toList();
        if (entities.isEmpty) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
          entities = selectedCodes
              .map((code) => _signInEntitiesByCode[code])
              .whereType<sign_in_form.StudentEntity>()
              .toList();
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-In');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_in_form.StudentSignInForm(
              students: entities,
              refreshCallback: () => _loadForSelectedRoom(refresh: true),
            ),
          ),
        );
        return;
      }

      if (actionName == 'sign_out') {
        var entities = selectedCodes
            .map((code) => _signOutEntitiesByCode[code])
            .whereType<sign_out_form.StudentEntity>()
            .toList();
        if (entities.isEmpty) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
          entities = selectedCodes
              .map((code) => _signOutEntitiesByCode[code])
              .whereType<sign_out_form.StudentEntity>()
              .toList();
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-Out');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_out_form.StudentSignOutForm(
              students: entities,
              refreshCallback: () => _loadForSelectedRoom(refresh: true),
            ),
          ),
        );
        return;
      }

      if (actionName == 'transfer') {
        var entities = selectedCodes
            .map((code) => _transferEntitiesByCode[code])
            .whereType<transfer_form.StudentEntity>()
            .toList();
        if (entities.isEmpty) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
          entities = selectedCodes
              .map((code) => _transferEntitiesByCode[code])
              .whereType<transfer_form.StudentEntity>()
              .toList();
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Transfer');
        }

        ClassroomCubit? classroomCubit;
        try {
          classroomCubit = context.read<ClassroomCubit>();
        } catch (_) {
          classroomCubit = null;
        }
        final classroomNameToCode = <String, String>{
          for (final c in (classroomCubit?.state.classrooms ?? const []))
            c.name: c.code,
        };

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => transfer_form.StudentTransferForm(
              students: entities,
              classroomNameToCode: classroomNameToCode,
              refreshCallback: () => _loadForSelectedRoom(refresh: true),
            ),
          ),
        );
        return;
      }

      var entities = selectedCodes
          .map((code) => _absentEntitiesByCode[code])
          .whereType<absent_form.StudentEntity>()
          .toList();
      if (entities.isEmpty) {
        await _prefetchAttendanceEntitiesForSelection(allStudents);
        entities = selectedCodes
            .map((code) => _absentEntitiesByCode[code])
            .whereType<absent_form.StudentEntity>()
            .toList();
      }
      if (entities.isEmpty) {
        throw Exception('No selected students are eligible for Mark Absent');
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => absent_form.StudentMarkAbsentForm(
            students: entities,
            refreshCallback: () => _loadForSelectedRoom(refresh: true),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAttendanceActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ClassroomStudentsCubit, ClassroomStudentsState>(
        builder: (context, state) {
          final visibleStudents = ClassroomStudentsCubit.applyClientFilters(
            state.students,
            presentOnly: _isPresentFilter,
            nappingOnly: _isNappingFilter,
            searchText: _searchController.text,
          )..sort((a, b) => a.fullName.compareTo(b.fullName));

          final selectedStudents = _getSelectedStudents(visibleStudents);

          return Stack(
            children: [
              Card(
                elevation: 0,
                margin: const EdgeInsets.all(0),
                shape: const Border(
                  left: BorderSide(color: AppColors.themeColor),
                  top: BorderSide(color: AppColors.themeColor),
                  right: BorderSide(color: AppColors.themeColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SearchBar(
                              controller: _searchController,
                              constraints: const BoxConstraints(minHeight: 36),
                              hintText: 'Search',
                              hintStyle: const WidgetStatePropertyAll(
                                TextStyle(
                                  fontFamily: 'Manrope',
                                  color: Color.fromRGBO(87, 51, 83, 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              leading: const Icon(
                                Icons.search,
                                color: AppColors.primaryColor,
                                size: 18,
                              ),
                              elevation: const WidgetStatePropertyAll(0),
                              side: const WidgetStatePropertyAll(
                                BorderSide(
                                  width: 1,
                                  color: Color.fromARGB(255, 188, 173, 186),
                                ),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // TODO: open filter modal
                            },
                            icon: SvgPicture.asset(
                              MediaRes.filterIcon,
                              height: 22,
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CustomCheckbox(
                              borderColor:
                                  AppColors.primaryColor.withValues(alpha: 0.2),
                              value: isSelectAllChecked,
                              onChanged: (val) =>
                                  _toggleSelectAll(val, visibleStudents),
                            ),
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      const Color.fromRGBO(177, 175, 233, 0.3),
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 3,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color.fromRGBO(27, 35, 126, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: AppColors.buildPrimaryGradient(),
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 3,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _clearAllSelections,
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(fontFamily: 'Manrope', fontSize: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Information'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              details.entries.map((entry) {
                                            bool isSvg =
                                                entry.key.endsWith('.svg');
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              child: Row(
                                                children: [
                                                  isSvg
                                                      ? SvgPicture.asset(
                                                          entry.key,
                                                          width: 24,
                                                          height: 24,
                                                        )
                                                      : Image.asset(
                                                          entry.key,
                                                          width: 24,
                                                          height: 24,
                                                        ),
                                                  const SizedBox(width: 20),
                                                  Expanded(
                                                    child: Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                          fontFamily: 'Manrope', fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CustomToggle(
                            label: 'Present',
                            isToggled: _isPresentFilter,
                            onToggle: (value) {
                              setState(() {
                                _isPresentFilter = value;
                              });
                            },
                            labelStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
                          CustomToggle(
                            label: 'Napping',
                            isToggled: _isNappingFilter,
                            onToggle: (value) {
                              setState(() {
                                _isNappingFilter = value;
                              });
                            },
                            labelStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                          if (state.isLoading && visibleStudents.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (visibleStudents.isEmpty) {
                            return CustomRefreshIndicator(
                              onRefresh: () async {
                                _loadForSelectedRoom(refresh: true);
                              },
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ListView(
                                    children: [
                                      SizedBox(
                                        height: constraints.maxHeight,
                                        child: Center(
                                          child: Text(
                                            _isNappingFilter
                                                ? 'No students are napping.'
                                                : 'No students assigned.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.6),
                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }

                          return CustomRefreshIndicator(
                            onRefresh: () async {
                              _loadForSelectedRoom(refresh: true);
                            },
                            child: ListView.builder(
                              itemCount: visibleStudents.length,
                              itemBuilder: (context, index) {
                                final student = visibleStudents[index];
                              return ClassroomStudentListItem(
                                    studentId: student.studentCode.hashCode,
                                    isSignedIn: student.signedIn,
                                    isAbsent: student.absent,
                                    isExpectedToday: student.expectedToday,
                                    studentStatus: student.status,
                                    name: student.fullName,
                                    imageUrl: student.profilePictureUrl ?? '',
                                    icons: _getStudentIcons(student),
                                    isSelected:
                                    studentSelections[student.studentCode] ?? false,
                                    onSelectionChanged: (bool? value) {
                                      _toggleStudentSelection(
                                        student.studentCode,
                                        value,
                                        visibleStudents,
                                      );
                                    },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // StudentActionPanel shown when students are selected
          if (hasSelectedStudents)
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  if (_showActivitiesPanel &&
                      _canShowActivitiesPanel(selectedStudents))
                    ActivityStatusPanel(
                      onGoingActivities:
                          _getCombinedOngoingActivities(selectedStudents),
                      isSignedIN: true,
                    ),
                  const SizedBox(width: 10),
                  StudentActionPanel(
                    currentPanel: _currentPanel,
                    activityStudentMaps: _canShowActivitiesPanel(selectedStudents)
                        ? _activityStudentMaps(selectedStudents)
                        : null,
                    attendanceAvailability:
                        _attendanceAvailabilityForSelection(selectedStudents),
                    onAttendanceTap: () {
                      setState(() {
                        final open =
                            _currentPanel == StudentPanelType.attendance;
                        _currentPanel =
                            open ? StudentPanelType.none : StudentPanelType.attendance;
                        _showActivitiesPanel = false;
                      });
                    },
                    onMessageTap: () {},
                    onActivitiesTap: _canShowActivitiesPanel(selectedStudents)
                        ? () {
                            setState(() {
                              _showActivitiesPanel = !_showActivitiesPanel;
                              _currentPanel = _showActivitiesPanel
                                  ? StudentPanelType.activities
                                  : StudentPanelType.none;
                            });
                          }
                        : null,
                    onProfileTap: _selectedCount == 1
                        ? () {
                            if (selectedStudents.isNotEmpty) {
                              final student = selectedStudents.first;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentProfileScreen(
                                    name: student.fullName,
                                    classroom:
                                        widget.selectedRoom?.name ?? 'Unknown Class',
                                    tags: const [],
                                    schedule: const [
                                      'Monday',
                                      'Tuesday',
                                      'Wednesday',
                                      'Thursday',
                                      'Friday'
                                    ],
                                    sibling: const {
                                      'name': [],
                                      'relation': [],
                                      'status': []
                                    },
                                    studentCode: student.studentCode,
                                    initialEnrollmentStatus: student.status,
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    onClearSelections: () {
                      setState(() {
                        isSelectAllChecked = false;
                        studentSelections.updateAll((key, val) => false);
                        _showActivitiesPanel = false;
                        _currentPanel = StudentPanelType.none;
                      });
                    },
                    isProfileEnabled: _selectedCount == 1,
                    activitiesEnabled: _canShowActivitiesPanel(selectedStudents),
                    showAttendanceActions:
                        _currentPanel == StudentPanelType.attendance,
                    isAttendanceActionLoading:
                        _isAttendanceActionLoading ||
                            _isPrefetchingAttendanceData,
                    onSignInTap: () => _openAttendanceActionFlow(
                      allStudents: state.students,
                      actionName: 'sign_in',
                    ),
                    onSignOutTap: () => _openAttendanceActionFlow(
                      allStudents: state.students,
                      actionName: 'sign_out',
                    ),
                    onTransferTap: () => _openAttendanceActionFlow(
                      allStudents: state.students,
                      actionName: 'transfer',
                    ),
                    onMarkAbsentTap: () => _openAttendanceActionFlow(
                      allStudents: state.students,
                      actionName: 'mark_absent',
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
        },
      ),
    );
  }
}

class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdown> createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  late List<String> _localSelectedItems;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(CustomMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      _localSelectedItems = List.from(widget.selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : '${_localSelectedItems.length} selected';

    return Container(
      height: 32,
      width: widget.width,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.primaryColor.withValues(alpha: 0.1),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconSize: 24,
        elevation: 2,
        style: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xff573353),
          fontSize: 16,
        ),
        dropdownColor: Colors.white,
        items: widget.items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            enabled: false,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                final isSelected = _localSelectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _localSelectedItems.remove(item);
                      } else {
                        _localSelectedItems.add(item);
                      }
                    });
                    widget.onChanged(_localSelectedItems);
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomCheckbox(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _localSelectedItems.add(item);
                              } else {
                                _localSelectedItems.remove(item);
                              }
                            });
                            widget.onChanged(_localSelectedItems);
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: Color(0xff573353),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        onChanged: (_) {},
        isExpanded: true,
        hint: Text(
          displayText,
          style: TextStyle(
            fontFamily: 'Manrope',
            color:
                _localSelectedItems.isEmpty ? Colors.grey[600] : const Color(0xff573353),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

Map<String, String> details = {
  'assets/images/icons/sleep.png': 'Student is napping',
  MediaRes.cameraIcon: 'No Photo',
  MediaRes.healthIcon: 'Medication',
  MediaRes.docsIcon: 'Notes',
  MediaRes.alertIcon: 'Allergies',
  MediaRes.foodIcon2: 'Dietary Restrictions',
};
