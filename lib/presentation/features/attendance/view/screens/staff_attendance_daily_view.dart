import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_filters.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';

class StaffAttendanceDailyViewScreen extends StatefulWidget {
  const StaffAttendanceDailyViewScreen({
    super.key,
    this.incomingFilter,
    this.contentOnly = false,
    this.classroomFilter,
  });

  final String? incomingFilter;
  final bool contentOnly;
  final FilterData? classroomFilter;

  @override
  State<StaffAttendanceDailyViewScreen> createState() => _StaffAttendanceDailyViewScreenState();
}

class _StaffAttendanceDailyViewScreenState extends State<StaffAttendanceDailyViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showAbsentOnly = false;
  String? _statusLegendFilter;
  FilterData? _staffFilters;

  // Summary data (placeholder - will be replaced with actual data)
  int totalStaff = 0;
  int active = 0;
  int upcoming = 0;
  int expected = 0;
  int present = 0;
  int absent = 0;
  int signedOut = 0;
  int notMarked = 0;

  // Staff data lists
  final List<StaffAttendanceCardData> _staffMembers = [];
  final List<StaffAbsentCardData> _absentStaff = [];
  int? _expandedStaffIndex;
  int? _expandedAbsentIndex;

  late final StaffAttendanceDailyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Handle incoming filter
    if (widget.incomingFilter != null) {
      _statusLegendFilter = widget.incomingFilter;
      if (widget.incomingFilter == 'Absent') {
        _showAbsentOnly = true;
      }
    }

    // Handle classroom filter
    if (widget.classroomFilter != null) {
      _staffFilters = widget.classroomFilter;
    }

    _cubit = serviceLocator<StaffAttendanceDailyCubit>();

    // Load initial data from API
    _loadAttendanceData(context, reset: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadAttendanceData(context, reset: true);
  }

  // Method to load attendance data from backend
  void _loadAttendanceData(BuildContext context, {bool reset = false}) {
    if (reset) {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: _staffFilters?.classrooms,
        tagCodes: _staffFilters?.tags,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    } else {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: _staffFilters?.classrooms,
        tagCodes: _staffFilters?.tags,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    }
  }

  bool _hasActiveFilters() {
    if (_staffFilters == null) return false;
    return _staffFilters!.classrooms.isNotEmpty ||
        _staffFilters!.statuses.isNotEmpty ||
        _staffFilters!.tags.isNotEmpty;
  }

  List<StaffAttendanceCardData> _getFilteredStaff() {
    if (_statusLegendFilter == null) {
      return _staffMembers;
    }

    if (_statusLegendFilter == 'Present') {
      return _staffMembers.where((staff) => staff.hasSignIn).toList();
    }

    return _staffMembers;
  }

  void _clearAllFilters() {
    setState(() {
      _statusLegendFilter = null;
      _staffFilters = null;
    });
    _loadAttendanceData(context, reset: true);
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

    return BlocProvider<StaffAttendanceDailyCubit>.value(
      value: _cubit,
      child: BlocBuilder<StaffAttendanceDailyCubit, StaffAttendanceDailyState>(
        builder: (context, state) {
          final isLoading = state.isLoading && !_showAbsentOnly;

          return CustomRefreshIndicator(
            onRefresh: () async {
              _loadAttendanceData(context, reset: false);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                  _cubit.loadNextPage();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: contentPadding.left,
                  vertical: responsive.verticalSpacing / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Summary Cards (still using placeholder values for now)
                    StaffAttendanceSummary(
                      totalStaff: totalStaff,
                      active: active,
                      upcoming: upcoming,
                      expected: expected,
                      present: present,
                      absent: absent,
                      signedOut: signedOut,
                      notMarked: notMarked,
                      isLoading: isLoading,
                      onLegendTap: (status) {
                        setState(() {
                          if (status == 'Present') {
                            _statusLegendFilter =
                                _statusLegendFilter == status ? null : status;
                            _showAbsentOnly = false;
                          } else if (status == 'Absent') {
                            _showAbsentOnly = !_showAbsentOnly;
                            _statusLegendFilter = null;
                          }
                        });
                        if (!_showAbsentOnly) {
                          _loadAttendanceData(context, reset: false);
                        }
                      },
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    // Filters
                    StaffAttendanceFilters(
                      searchController: _searchController,
                      selectedDate: _selectedDate,
                      showAbsentOnly: _showAbsentOnly,
                      hasActiveFilters:
                          _hasActiveFilters() || _statusLegendFilter != null,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                        _loadAttendanceData(context, reset: true);
                      },
                      onToggleChanged: (value) {
                        setState(() {
                          _showAbsentOnly = value;
                          if (_showAbsentOnly) {
                            _statusLegendFilter = null;
                          }
                        });
                        if (!_showAbsentOnly) {
                          _loadAttendanceData(context, reset: true);
                        }
                      },
                      onFilterTap: () async {
                        // Navigate to filter screen
                        // Placeholder - will be implemented when filter screen is ready
                      },
                      onClearAll: _clearAllFilters,
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    // Content area
                    if (isLoading)
                      Column(
                        children: List.generate(
                          6,
                          (index) => _showAbsentOnly
                              ? const StaffAbsentCardShimmer()
                              : const StaffAttendanceCardShimmer(),
                        ),
                      )
                    else if (_showAbsentOnly)
                      _buildAbsentStaffList()
                    else
                      _buildStaffListFromState(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffListFromState(StaffAttendanceDailyState state) {
    _staffMembers.clear();

    for (final item in state.items) {
      final signInTime = item.formattedSignInTime;
      final signOutTime = item.formattedSignOutTime;

      _staffMembers.add(
        StaffAttendanceCardData(
          id: item.staffCode,
          staffName: item.staffName,
          staffPhotoUuid: null,
          designationName:
              item.designation.isNotEmpty ? item.designation.first : null,
          roomName: item.classroomName,
          expectedToday: item.isExpectedToday,
          hasSignIn: item.hasSignIn,
          signInTime: signInTime,
          signOutTime: signOutTime,
          signInBy: item.signedInBy,
          signOutBy: item.signedOutBy,
          signInMethod: null,
          signOutMethod: null,
          staffId: 0,
          roomId: 0,
          schoolId: 0,
        ),
      );
    }

    final filtered = _getFilteredStaff();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              AppText.body(
                'No staff attendance records found for the selected date',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filtered.asMap().entries.map((entry) {
        final index = entry.key;
        final staff = entry.value;
        return StaffAttendanceCard(
          staff: staff,
          index: index,
          isExpanded: _expandedStaffIndex == index,
          onTap: () {
            setState(() {
              _expandedStaffIndex = _expandedStaffIndex == index ? null : index;
            });
          },
          onEdit: () {
            // Placeholder for edit action
          },
          onDelete: () {
            // Placeholder for delete action
          },
          onView: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffAttendanceProfile(
                  staffCode: staff.id,
                  staffId: staff.staffId,
                  staffName: staff.staffName,
                  staffPhotoUuid: staff.staffPhotoUuid,
                  designationName: staff.designationName,
                  roomName: staff.roomName,
                  isSignedIn: staff.hasSignIn,
                  isAbsent: false,
                  isExpectedToday: staff.expectedToday,
                  isPresentToday: staff.hasSignIn,
                  profileStatus: 'A',
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAbsentStaffList() {
    if (_absentStaff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                'No absent staff found for the selected date',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _absentStaff.asMap().entries.map((entry) {
        final index = entry.key;
        final staff = entry.value;
        return StaffAbsentCard(
          staff: staff,
          index: index,
          isExpanded: _expandedAbsentIndex == index,
          onTap: () {
            setState(() {
              _expandedAbsentIndex = _expandedAbsentIndex == index ? null : index;
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
      }).toList(),
    );
  }
}
