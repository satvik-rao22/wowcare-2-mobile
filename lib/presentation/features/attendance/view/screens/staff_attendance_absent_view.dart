import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_absent_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

// Dummy data model for UI-only implementation
class _AbsentStaffModel {
  final String id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final int absentDays;
  final DateTime startDate;
  final DateTime endDate;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int staffId;
  final int roomId;
  final int schoolId;
  final String? status;
  final bool hasSignIn;
  final bool expectedToday;

  _AbsentStaffModel({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentDays,
    required this.startDate,
    required this.endDate,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.staffId,
    required this.roomId,
    required this.schoolId,
    this.status,
    this.hasSignIn = false,
    this.expectedToday = true,
  });
}

class StaffAttendanceAbsentView extends StatefulWidget {
  const StaffAttendanceAbsentView({
    super.key,
    this.contentOnly = false,
  });

  final bool contentOnly;

  @override
  State<StaffAttendanceAbsentView> createState() => _StaffAttendanceAbsentViewState();
}

class _StaffAttendanceAbsentViewState extends State<StaffAttendanceAbsentView>
    implements AttendanceTabRefresh {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  List<String> _selectedClassroomNames = <String>[];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int? _expandedStaffIndex;
  bool _isClassroomDataReady = false;

  late final StaffAttendanceAbsentCubit _cubit;
  late final ClassroomCubit _classroomCubit;
  final GetClassroomByCodeUseCase _getClassroomByCode =
      serviceLocator<GetClassroomByCodeUseCase>();
  final Map<String, String> _classroomNameByCode = {};
  final Set<String> _classroomFetchInFlight = {};
  final List<_AbsentStaffModel> _absentStaff = [];
  bool isLoading = false;
  String? errorMessage;

  // Loading state for individual buttons (reserved for future)
  // final Map<int, bool> _loadingButtons = {};

  @override
  void initState() {
    super.initState();
    _initializeDefaultRange();
    _searchController.addListener(_onSearchChanged);

    _cubit = serviceLocator<StaffAttendanceAbsentCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>();
    // Staff screens intentionally load all ACTIVE locations (not just type=CLASSROOM).
    // Guard for "data not loaded yet" so name->code resolution is reliable.
    _loadClassroomData();

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsentStaff(reset: true);
    });
  }

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    _loadAbsentStaff(reset: true);
  }

  Future<void> _loadClassroomData() async {
    final hadClassroomSelection = _selectedClassroomNames.isNotEmpty;
    _classroomCubit.loadActiveClassrooms(
      force: true,
      onlyTypeClassroom: false,
      applyAttendanceStaffScope: true,
    );

    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isClassroomDataReady = true);
      if (hadClassroomSelection) {
        _loadAbsentStaff(reset: true);
      }
      return;
    }

    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {
      _isClassroomDataReady = !_classroomCubit.state.isLoading &&
          _classroomCubit.state.classrooms.isNotEmpty;
    });
    if (hadClassroomSelection && _isClassroomDataReady) {
      _loadAbsentStaff(reset: true);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  String? _resolveClassroomNameByCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    for (final c in _classroomCubit.state.classrooms) {
      if (c.code.trim() == trimmed) return c.name;
    }
    final cached = _classroomNameByCode[trimmed]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> _fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCode(code: code);
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _classroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep code when lookup fails.
    } finally {
      _classroomFetchInFlight.remove(code);
    }
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    if (apiName.isNotEmpty) return apiName;
    final code = classroomCode.trim();
    if (code.isEmpty) return '';
    final resolved = _resolveClassroomNameByCode(code);
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    if (!_classroomFetchInFlight.contains(code)) {
      _classroomFetchInFlight.add(code);
      // ignore: discarded_futures
      _fetchClassroomName(code);
    }
    return code;
  }

  List<String>? _resolveSelectedClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) return null;
    if (_classroomCubit.state.classrooms.isEmpty) return null;
    final nameToCode = <String, String>{
      for (final c in _classroomCubit.state.classrooms) c.name: c.code,
    };
    final knownCodes = {
      for (final c in _classroomCubit.state.classrooms) c.code.trim(),
    };
    final codes = <String>[];
    for (final selected in _selectedClassroomNames) {
      final trimmed = selected.trim();
      final fromName = nameToCode[selected]?.trim();
      if (fromName != null && fromName.isNotEmpty) {
        codes.add(fromName);
      } else if (knownCodes.contains(trimmed)) {
        codes.add(trimmed);
      }
    }
    return codes.isEmpty ? null : codes;
  }

  void _initializeDefaultRange() {
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text;
    setState(() {
      _searchQuery = newQuery;
    });

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _loadAbsentStaff(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _cubit.loadNextPage();
    }
  }

  Future<void> _loadAbsentStaff({bool reset = false}) async {
    if (_rangeStart == null || _rangeEnd == null) {
      _initializeDefaultRange();
    }

    final from = _rangeStart!;
    final to = _rangeEnd!;

    final classroomCodes = _resolveSelectedClassroomCodes();

    if (reset) {
      _expandedStaffIndex = null;
      await _cubit.loadInitial(
        fromDate: from,
        toDate: to,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    } else {
      await _cubit.refresh(
        fromDate: from,
        toDate: to,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
    }
  }

  List<_AbsentStaffModel> _getFilteredStaff() {
    // Classroom, date range, and search are applied server-side via classroomCodes.
    return _absentStaff;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return _buildContent();
    }

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffAttendanceAbsentCubit>.value(value: _cubit),
        BlocProvider<ClassroomCubit>.value(value: _classroomCubit),
      ],
      child: BlocBuilder<StaffAttendanceAbsentCubit, StaffAttendanceAbsentState>(
        builder: (context, state) {
          final isInitialLoading = state.isLoading && state.items.isEmpty;

          // Map API items → UI model
          _absentStaff
            ..clear()
            ..addAll(
              state.items.map((it) {
                final date = it.absenceDate.isNotEmpty
                    ? DateTime.tryParse(it.absenceDate) ?? DateTime.now()
                    : DateTime.now();

                final absentTime = it.markedAbsentTime?.formatted12h ?? '';

                return _AbsentStaffModel(
                  id: it.staffCode,
                  name: it.staffName,
                  photoUuid: null,
                  roomName: _classroomDisplay(
                    classroomCode: it.classroomCode,
                    classroomName: it.classroomName,
                  ),
                  absentDays: it.absentDays,
                  startDate: date,
                  endDate: date,
                  absentTime: absentTime,
                  absentBy: it.markedAbsentByName,
                  note: it.absenceNote,
                  staffId: 0,
                  roomId: 0,
                  schoolId: 0,
                  status: null,
                  hasSignIn: false,
                  expectedToday: true,
                );
              }),
            );

          final filtered = _getFilteredStaff();

          return CustomRefreshIndicator(
            onRefresh: () async {
              await _loadAbsentStaff(reset: false);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding.left,
                vertical: responsive.verticalSpacing / 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Filters Section
                  CustomSectionCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: responsive.isTablet ? 3 : 2,
                              child: CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Search Staff',
                              ),
                            ),
                            SizedBox(width: responsive.horizontalSpacing / 2),
                            Expanded(
                              flex: responsive.isTablet ? 2 : 1,
                              child: BlocBuilder<ClassroomCubit, ClassroomState>(
                                builder: (context, classroomState) {
                                  final items = classroomState.classrooms
                                      .map((c) => c.name)
                                      .toList();
                                  final isLoading = classroomState.isLoading ||
                                      !_isClassroomDataReady;
                                  if (isLoading && items.isEmpty) {
                                    return ShimmerLoader(
                                      height: 40,
                                      borderRadius: BorderRadius.circular(12),
                                    );
                                  }

                                  return CustomMultiSelectDropdown(
                                    hintText: 'Classroom',
                                    items: items,
                                    selectedItems: _selectedClassroomNames,
                                    onChanged: (values) {
                                      if (isLoading) return;
                                      setState(() {
                                        _selectedClassroomNames =
                                            List<String>.from(values);
                                      });
                                      _loadAbsentStaff(reset: true);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing / 2),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDateTimeField(
                                hasLabel: false,
                                isRangePicker: true,
                                fetchInitialTime: true,
                                onRangeSelected: (start, end) {
                                  if (end == null) {
                                    setState(() {
                                      _rangeStart = start;
                                      _rangeEnd = null;
                                    });
                                    return;
                                  }
                                  if (start.isAfter(end)) {
                                    CoreUtils.showTopSnackBarFromSnackBar(
                                      context: context,
                                      snackBar: 
                                      SnackBar(
                                        content: const Text('Start date cannot be after end date'),
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _rangeStart = start;
                                    _rangeEnd = end;
                                  });
                                  _loadAbsentStaff(reset: true);
                                },
                              ),
                            ),
                            SizedBox(width: responsive.horizontalSpacing / 2),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedClassroomNames = <String>[];
                                  final now = DateTime.now();
                                  _rangeStart = DateTime(now.year, now.month, 1);
                                  _rangeEnd = DateTime(now.year, now.month + 1, 0);
                                });
                                _loadAbsentStaff(reset: true);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  // Content area
                  if (isInitialLoading)
                    Column(
                      children: [
                        ShimmerLoader(
                          height: 100,
                          margin: EdgeInsets.only(
                              bottom: responsive.verticalSpacing / 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        ...List.generate(
                          6,
                          (index) => const StaffAbsentCardShimmer(),
                        ),
                      ],
                    )
                  else if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            AppText.body(
                              'No absent staff found',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...filtered.asMap().entries.map((entry) {
                          final index = entry.key;
                          final staff = entry.value;
                          return _buildAbsentStaffCard(staff, index);
                        }).toList(),
                        if (state.isLoadingMore)
                          Padding(
                            padding:
                                EdgeInsets.all(responsive.verticalSpacing / 2),
                            child: const PrimaryCircularLoader(),
                          ),
                      ],
                    ),
                  SizedBox(height: responsive.verticalSpacing),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbsentStaffCard(_AbsentStaffModel staff, int index) {
    final bool isExpanded = _expandedStaffIndex == index;

    // Convert to StaffAbsentCardData
    final cardData = StaffAbsentCardData(
      id: staff.id,
      name: staff.name,
      photoUuid: staff.photoUuid,
      roomName: staff.roomName,
      absentTime: staff.absentTime,
      absentBy: staff.absentBy,
      note: staff.note,
      staffId: staff.staffId,
      roomId: staff.roomId,
      schoolId: staff.schoolId,
      startDate: staff.startDate.toIso8601String(),
      endDate: staff.endDate.toIso8601String(),
      hasSignIn: staff.hasSignIn,
      expectedToday: staff.expectedToday,
    );

    return StaffAbsentCard(
      staff: cardData,
      index: index,
      isExpanded: isExpanded,
      onTap: () {
        setState(() {
          if (_expandedStaffIndex == index) {
            _expandedStaffIndex = null;
          } else {
            _expandedStaffIndex = index;
          }
        });
      },
      onView: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffAttendanceProfile(
              staffCode: staff.id,
              staffId: staff.staffId,
              staffName: staff.name,
              staffPhotoUuid: staff.photoUuid,
              roomName: staff.roomName,
              isSignedIn: staff.hasSignIn,
              isAbsent: true,
              isExpectedToday: staff.expectedToday,
              isPresentToday: false,
              profileStatus: 'A',
              initialShowAbsentDays: true,
            ),
          ),
        );
      },
    );
  }
}
