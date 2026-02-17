import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

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
  final String? signInTime;
  final String? signOutTime;

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
    this.signInTime,
    this.signOutTime,
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

  // Pagination & list state
  bool _isInitialLoadingStaff = true;
  bool _isLoadingStaff = false;
  bool _isBackgroundFetchingStaff = false;
  int _staffPage = 0;
  bool _staffHasMore = true;
  final int _pageSize = 10;
  final List<_AbsentStaffModel> _absentStaff = [];

  List<String> classrooms = ['All'];
  bool isLoading = false;
  String? errorMessage;

  // Loading state for individual buttons
  final Map<int, bool> _loadingButtons = {};

  @override
  void initState() {
    super.initState();
    _initializeClassrooms();
    _initializeDefaultRange();
    _searchController.addListener(_onSearchChanged);
    
    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
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
    if (!_scrollController.hasClients ||
        _isLoadingStaff ||
        _isInitialLoadingStaff) return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;
    if (!_isBackgroundFetchingStaff &&
        _staffHasMore &&
        position.pixels >= threshold) {
      setState(() => _isBackgroundFetchingStaff = true);
      _loadAbsentStaff(fromBackground: true);
    }
  }

  Future<void> _loadInitialData({bool reset = false, bool fromBackground = false}) async {
    if ((_selectedClassroom != null && _selectedClassroom != 'All') ||
        (_rangeStart != null && _rangeEnd != null)) {
      await _loadAbsentStaff(
        reset: reset,
        fromBackground: fromBackground,
      );
      return;
    }

    // Load all absent staff (no filters)
    await _loadAbsentStaff(
      reset: reset,
      fromBackground: fromBackground,
    );
  }

  Future<void> _loadAbsentStaff({bool reset = false, bool fromBackground = false}) async {
    if (_isLoadingStaff && !reset) return;

    setState(() {
      _isLoadingStaff = true;
      isLoading = true;
      errorMessage = null;
      if (reset || _staffPage == 0) {
        if (reset || !fromBackground) {
          _isInitialLoadingStaff = true;
        }
        _isBackgroundFetchingStaff = false;
        if (reset) {
          _absentStaff.clear();
        }
      }
      if (reset) {
        _staffPage = 0;
        _staffHasMore = true;
      }
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Generate dummy data
      final newData = _buildDummyAbsentStaffData();
      
      setState(() {
        if (reset) {
          _absentStaff.clear();
        }
        _absentStaff.addAll(newData);
        _staffHasMore = newData.length == _pageSize;
        if (newData.isNotEmpty && !reset) {
          _staffPage++;
        }
        _isInitialLoadingStaff = false;
        _isLoadingStaff = false;
        isLoading = false;
        _isBackgroundFetchingStaff = false;
      });

      // Update classrooms list
      _updateClassroomsList();
    });
  }

  List<_AbsentStaffModel> _buildDummyAbsentStaffData() {
    final rooms = classrooms.where((e) => e != 'All').toList();
    if (rooms.isEmpty) {
      rooms.addAll(['Room 1', 'Room 2', 'Room 3']);
    }

    return List<_AbsentStaffModel>.generate(
      _pageSize,
      (i) {
        final idx = i + 1;
        final room = rooms[i % rooms.length];
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: idx % 30));
        final endDate = startDate.add(Duration(days: idx % 5));

        return _AbsentStaffModel(
          id: 'absent_staff_$idx',
          name: 'Absent Staff $idx',
          photoUuid: null,
          roomName: room,
          absentDays: (idx % 10) + 1,
          startDate: startDate,
          endDate: endDate,
          absentTime: '09:${(idx * 5) % 60}:00 AM',
          absentBy: 'Admin',
          note: idx % 3 == 0 ? 'Staff is on leave' : null,
          staffId: 100 + idx,
          roomId: (i % 3) + 1,
          schoolId: 1,
          status: 'A',
          hasSignIn: false,
          expectedToday: true,
        );
      },
    );
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
    final filtered = _getFilteredStaff();

    return CustomRefreshIndicator(
      onRefresh: () async {
        await _loadAbsentStaff(reset: true);
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
                    initialDate: _rangeStart,
                    onRangeSelected: (start, end) {
                      if (start != null && end != null && start.isAfter(end)) {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                ],
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Content area
            if (_isInitialLoadingStaff)
              Column(
                children: [
                  ShimmerLoader(
                    height: 100,
                    margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
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
                  // Show loading indicator at bottom when loading more
                  if (_isLoadingStaff &&
                      _staffHasMore &&
                      _staffPage > 0 &&
                      !_isInitialLoadingStaff)
                    Padding(
                      padding: EdgeInsets.all(responsive.verticalSpacing / 2),
                      child: const PrimaryCircularLoader(),
                    ),
                ],
              ),
            // Add some bottom padding for better scrolling
            SizedBox(height: responsive.verticalSpacing),
          ],
        ),
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
      signInTime: staff.signInTime,
      signOutTime: staff.signOutTime,
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
