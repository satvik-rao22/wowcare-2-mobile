import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';

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

  void _clearAllFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _showAbsentOnly = false;
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
                    // Filters: keep the same date-field UI (CustomDateTimeField) but layout like StaffScreen
                    _buildFilterCard(
                      responsive,
                      hasActiveFilters: _hasActiveFilters() ||
                          _statusLegendFilter != null ||
                          _searchController.text.trim().isNotEmpty,
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

  Widget _buildFilterCard(
    ResponsiveHelper responsive, {
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search Staff',
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Placeholder: wire to attendance filter screen when ready
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          MediaRes.filterIcon,
                          height: 20,
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(179, 38, 30, 1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  isRangePicker: false,
                  isTime: false,
                  fetchInitialTime: false,
                  initialDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                    _loadAttendanceData(context, reset: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomClearAllChip(
                onTap: hasActiveFilters ? _clearAllFiltersAndSearch : null,
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing / 2),
          Align(
            alignment: Alignment.centerRight,
            child: CustomToggle(
              label: 'Show Absent',
              isToggled: _showAbsentOnly,
              onToggle: (value) {
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
            ),
          ),
        ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffEditAttendanceForm(
                  staffAttendance: staff,
                  attendanceDate: _selectedDate,
                ),
              ),
            );
          },
          onDelete: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) {
                return DeleteConfirmationBottomSheet(
                  name: staff.staffName,
                  type: 'attendance',
                  onDelete: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance deleted'),
                      ),
                    );
                  },
                  onCancel: () {
                    Navigator.of(ctx).pop();
                  },
                );
              },
            );
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
