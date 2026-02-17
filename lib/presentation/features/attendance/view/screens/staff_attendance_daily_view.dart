import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_filters.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

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
  bool _hasError = false;
  String? _errorMessage;

  // Summary data (placeholder - will be replaced with actual data)
  int totalStaff = 0;
  int active = 0;
  int upcoming = 0;
  int expected = 0;
  int present = 0;
  int absent = 0;

  // Staff data lists
  final List<StaffAttendanceCardData> _staffMembers = [];
  final List<StaffAbsentCardData> _absentStaff = [];
  int? _expandedStaffIndex;
  int? _expandedAbsentIndex;

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

    // Load initial data
    _loadDummyData();
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
    _loadDummyData();
  }

  void _loadDummyData() {
    // Placeholder for loading attendance data
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          // Generate dummy summary data
          totalStaff = 50;
          active = 45;
          upcoming = 5;
          expected = 48;
          present = 40;
          absent = 8;

          // Generate dummy staff data
          if (_showAbsentOnly) {
            _absentStaff.clear();
            for (int i = 1; i <= 5; i++) {
              _absentStaff.add(StaffAbsentCardData(
                id: 'absent_$i',
                name: 'Absent Staff $i',
                photoUuid: null,
                roomName: 'Room ${(i % 3) + 1}',
                absentTime: '09:00:00 AM',
                absentBy: 'Staff Member',
                note: 'Staff is absent today',
                staffId: 100 + i,
                roomId: (i % 3) + 1,
                schoolId: 1,
                startDate: DateTime.now().toIso8601String(),
                endDate: DateTime.now().toIso8601String(),
                hasSignIn: false,
                expectedToday: true,
              ));
            }
          } else {
            _staffMembers.clear();
            for (int i = 1; i <= 10; i++) {
              _staffMembers.add(StaffAttendanceCardData(
                id: 'staff_$i',
                staffName: 'Staff Member $i',
                staffPhotoUuid: null,
                designationName: 'Teacher',
                roomName: 'Room ${(i % 3) + 1}',
                expectedToday: i <= 8,
                hasSignIn: i <= 6,
                signInTime: i <= 6 ? '08:${30 + i}:00 AM' : null,
                signOutTime: i <= 4 ? '05:${10 + i}:00 PM' : null,
                signInBy: i <= 6 ? 'Admin' : null,
                signOutBy: i <= 4 ? 'Admin' : null,
                signInMethod: i <= 6 ? (i % 4 == 0 ? SignMethod.gps : (i % 4 == 1 ? SignMethod.qr : (i % 4 == 2 ? SignMethod.kiosk : SignMethod.direct))) : null,
                signOutMethod: i <= 4 ? (i % 4 == 0 ? SignMethod.gps : (i % 4 == 1 ? SignMethod.qr : (i % 4 == 2 ? SignMethod.kiosk : SignMethod.direct))) : null,
                staffId: i,
                roomId: (i % 3) + 1,
                schoolId: 1,
              ));
            }
          }
        });
      }
    });
  }

  // Method to load attendance data (backend implementation to be added)
  void _loadAttendanceData(BuildContext context, {bool reset = false}) {
    _loadDummyData();
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
    _loadDummyData();
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

    return CustomRefreshIndicator(
      onRefresh: () async {
        _loadAttendanceData(context, reset: true);
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
            // Summary Cards
            StaffAttendanceSummary(
              totalStaff: totalStaff,
              active: active,
              upcoming: upcoming,
              expected: expected,
              present: present,
              absent: absent,
              isLoading: _isLoading,
              onLegendTap: (status) {
                setState(() {
                  if (status == 'Present') {
                    _statusLegendFilter = _statusLegendFilter == status ? null : status;
                    _showAbsentOnly = false;
                  } else if (status == 'Absent') {
                    _showAbsentOnly = !_showAbsentOnly;
                    _statusLegendFilter = null;
                  }
                });
                _loadDummyData();
              },
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Filters
            StaffAttendanceFilters(
              searchController: _searchController,
              selectedDate: _selectedDate,
              showAbsentOnly: _showAbsentOnly,
              hasActiveFilters: _hasActiveFilters() || _statusLegendFilter != null,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadDummyData();
              },
              onToggleChanged: (value) {
                setState(() {
                  _showAbsentOnly = value;
                  if (_showAbsentOnly) {
                    _statusLegendFilter = null;
                  }
                });
                _loadDummyData();
              },
              onFilterTap: () async {
                // Navigate to filter screen
                // Placeholder - will be implemented when filter screen is ready
              },
              onClearAll: _clearAllFilters,
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Content area
            if (_isLoading)
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
              _buildStaffList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList() {
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
