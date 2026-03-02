import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_absent_cubit.dart';

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

class _StaffAttendanceAbsentViewState extends State<StaffAttendanceAbsentView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  String? _selectedClassroom;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int? _expandedStaffIndex;

  late final StaffAttendanceAbsentCubit _cubit;
  final List<_AbsentStaffModel> _absentStaff = [];
  final Map<String, String> _classroomNameToCode = <String, String>{};

  List<String> classrooms = ['All'];
  bool isLoading = false;
  String? errorMessage;

  // Loading state for individual buttons (reserved for future)
  // final Map<int, bool> _loadingButtons = {};

  @override
  void initState() {
    super.initState();
    _initializeClassrooms();
    _initializeDefaultRange();
    _searchController.addListener(_onSearchChanged);

    _cubit = serviceLocator<StaffAttendanceAbsentCubit>();

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsentStaff(reset: true);
    });
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

  void _initializeClassrooms() {
    classrooms = ['All', 'Room 1', 'Room 2', 'Room 3'];
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

    final String? selectedName =
        (_selectedClassroom != null && _selectedClassroom != 'All')
            ? _selectedClassroom
            : null;
    final String? selectedCode =
        selectedName != null ? _classroomNameToCode[selectedName] : null;
    final classroomCodes = selectedCode != null && selectedCode.trim().isNotEmpty
        ? <String>[selectedCode]
        : null;

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

  void _updateClassroomsList() {
    final Set<String> uniqueClassrooms = {'All'};
    for (final staff in _absentStaff) {
      if (staff.roomName.isNotEmpty) {
        uniqueClassrooms.add(staff.roomName);
      }
    }
    classrooms = uniqueClassrooms.toList()..sort();
  }

  List<_AbsentStaffModel> _getFilteredStaff() {
    var filtered = _absentStaff;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((staff) {
        return staff.name.toLowerCase().contains(query) ||
            staff.roomName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply classroom filter
    if (_selectedClassroom != null && _selectedClassroom != 'All') {
      filtered = filtered.where((staff) {
        return staff.roomName == _selectedClassroom;
      }).toList();
    }

    // Apply date range filter
    if (_rangeStart != null && _rangeEnd != null) {
      filtered = filtered.where((staff) {
        return staff.startDate.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
            staff.startDate.isBefore(_rangeEnd!.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
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

    return BlocProvider<StaffAttendanceAbsentCubit>.value(
      value: _cubit,
      child: BlocBuilder<StaffAttendanceAbsentCubit, StaffAttendanceAbsentState>(
        builder: (context, state) {
          final isInitialLoading = state.isLoading && state.items.isEmpty;

          // Map API items → UI model
          _classroomNameToCode.clear();
          for (final it in state.items) {
            final name = it.classroomName.trim();
            final code = it.classroomCode.trim();
            if (name.isNotEmpty && code.isNotEmpty) {
              _classroomNameToCode[name] = code;
            }
          }

          _absentStaff
            ..clear()
            ..addAll(
              state.items.map((it) {
                final date = it.absenceDate.isNotEmpty
                    ? DateTime.tryParse(it.absenceDate) ?? DateTime.now()
                    : DateTime.now();

                final absentTime = it.markedAbsentTime?.formattedHms ?? '';

                return _AbsentStaffModel(
                  id: it.staffCode,
                  name: it.staffName,
                  photoUuid: null,
                  roomName: it.classroomName,
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

          _updateClassroomsList();
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
                vertical: responsive.verticalSpacing / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
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
                              child: CustomDropdown(
                                hintText: 'Select Classroom',
                                items: classrooms,
                                selectedItem: _selectedClassroom ?? 'All',
                                onSelect: (val) {
                                  setState(() {
                                    _selectedClassroom = val;
                                  });
                                  _loadAbsentStaff(reset: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing / 2),
                        CustomDateTimeField(
                          hasLabel: false,
                          isRangePicker: true,
                          initialDate: _rangeStart ?? DateTime.now(),
                          onRangeSelected: (start, end) {
                            if (end == null) {
                              setState(() {
                                _rangeStart = start;
                                _rangeEnd = null;
                              });
                              return;
                            }

                            if (start.isAfter(end)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Start date cannot be after end date'),
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
            ),
          ),
        );
      },
    );
  }
}
