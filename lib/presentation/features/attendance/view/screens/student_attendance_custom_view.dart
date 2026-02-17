import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';

class StudentAttendanceCustomView extends StatefulWidget {
  const StudentAttendanceCustomView({
    super.key,
    this.contentOnly = false,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
  });

  final bool contentOnly;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;

  @override
  State<StudentAttendanceCustomView> createState() => _StudentAttendanceCustomViewState();
}

class _StudentAttendanceCustomViewState extends State<StudentAttendanceCustomView> {
  final TextEditingController _customSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String? _customSelectedClassroom;
  DateTime? _customRangeStart;
  DateTime? _customRangeEnd;
  int? _customExpandedStudentIndex;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<_CustomAttendanceRow> _attendanceList = <_CustomAttendanceRow>[];
  List<String> _classrooms = <String>['All'];

  // Optional: show a small spinner on "View" action (UI-only)
  final Map<String, bool> _loadingButtons = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _customSelectedClassroom = 'All';
    _customSearchController.addListener(_onSearchChanged);
    _initializeClassrooms();
    _initializeDefaultRange();
    _loadAttendanceData(reset: true);
  }

  @override
  void dispose() {
    _customSearchController.removeListener(_onSearchChanged);
    _customSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        _loadAttendanceData(reset: true);
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
            SizedBox(height: responsive.verticalSpacing),
            // Tabs row + popup (only meaningful in non-embedded mode, but safe in embedded too)
            if (!widget.contentOnly) ...[
              _buildHeaderTabsRow(),
              const SizedBox(height: 10),
              _buildTabIndicator(selectedTab: 1),
              SizedBox(height: responsive.verticalSpacing),
            ],
            _buildFilterSection(),
            SizedBox(height: responsive.verticalSpacing),
            _buildContentSection(_getFilteredAttendance()),
            SizedBox(height: responsive.verticalSpacing),
          ],
        ),
      ),
    );
  }

  void _initializeClassrooms() {
    final fromWidget = (widget.staffAllowedClassrooms ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // If nothing provided, keep a small default set for UI rendering
    final fallback = <String>['Room 1', 'Room 2', 'Room 3'];

    _classrooms = <String>[
      'All',
      ...((fromWidget.isNotEmpty) ? fromWidget : fallback),
    ];
  }

  void _initializeDefaultRange() {
    final now = DateTime.now();
    _customRangeStart ??= DateTime(now.year, now.month, 1);
    _customRangeEnd ??= DateTime(now.year, now.month + 1, 0);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _customSearchController.text;
    });
  }

  // Method to load attendance data (UI-only, backend removed)
  void _loadAttendanceData({bool reset = false}) {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      if (reset) {
        _attendanceList.clear();
        _customExpandedStudentIndex = null;
      }
    });

    // Simulate loading + populate dummy data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Keep dummy data stable once loaded unless reset requested
      final next = reset || _attendanceList.isEmpty
          ? _buildDummyAttendanceData()
          : _attendanceList;

      setState(() {
        _attendanceList
          ..clear()
          ..addAll(next);
        _isLoading = false;
      });
    });
  }

  List<_CustomAttendanceRow> _buildDummyAttendanceData() {
    final rooms = _classrooms.where((e) => e != 'All').toList();
    if (rooms.isEmpty) {
      rooms.addAll(<String>['Room 1', 'Room 2', 'Room 3']);
    }

    return List<_CustomAttendanceRow>.generate(18, (i) {
      final idx = i + 1;
      final room = rooms[i % rooms.length];
      final expectedToday = idx % 6 != 0; // some are not expected
      final signedIn = expectedToday && idx % 4 != 0;
      final signedOut = signedIn && idx % 5 == 0;

      return _CustomAttendanceRow(
        id: 'custom_student_$idx',
        studentId: idx,
        studentName: 'Student $idx',
        roomName: room,
        daysAttended: '${(idx % 22) + 1}',
        totalHours: '${(idx % 6) + 1} Hrs ${(idx * 7) % 60} Mins',
        expectedToday: expectedToday,
        hasSignIn: signedIn,
        signOutTime: signedOut ? '05:${(10 + idx) % 60} PM' : null,
        studentPhotoUuid: '',
      );
    });
  }

  List<_CustomAttendanceRow> _getFilteredAttendance() {
    final q = _searchQuery.trim().toLowerCase();
    final selected = (_customSelectedClassroom ?? 'All').trim();

    return _attendanceList.where((row) {
      final matchesSearch =
          q.isEmpty || row.studentName.toLowerCase().contains(q);

      final matchesClassroom =
          selected == 'All' || selected.isEmpty || row.roomName == selected;

      return matchesSearch && matchesClassroom;
    }).toList();
  }

  Widget _buildHeaderTabsRow() {
    // This matches the reference UI layout; navigation is intentionally disabled (UI-only).
    int selectedTab = 1; // 0: Daily, 1: Custom, 2: Absent
    void onTabTap(int index) {}

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTabButton('Daily', 0, selectedTab, onTabTap),
                const SizedBox(width: 16),
                _buildTabButton('Custom', 1, selectedTab, onTabTap),
                const SizedBox(width: 16),
                _buildTabButton('Absent', 2, selectedTab, onTabTap),
              ],
            ),
          ),
        ),
        StudentAttendanceVerticalPopUp(
          students: const [],
          refreshCallback: () => _loadAttendanceData(reset: true),
        ),
      ],
    );
  }

  Widget _buildTabIndicator({required int selectedTab}) {
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Positioned(
            left: _getTabIndicatorPosition(selectedTab),
            child: Container(
              height: 2,
              width: _getTabIndicatorWidth(selectedTab),
              color: const Color(0xFF3B5BDB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final responsive = ResponsiveHelper(context);
    final spacing = responsive.horizontalSpacing / 2;

    return CustomSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              if (isNarrow) {
                return Column(
                  children: [
                    CustomSearchBar(
                      controller: _customSearchController,
                      hintText: 'Search Students',
                    ),
                    SizedBox(height: spacing),
                    CustomDropdown(
                      hintText: 'Select Classroom',
                      items: _classrooms,
                      selectedItem: _customSelectedClassroom ?? 'All',
                      onSelect: (val) {
                        setState(() {
                          _customSelectedClassroom = (val == null || val.isEmpty) ? 'All' : val;
                        });
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomSearchBar(
                      controller: _customSearchController,
                      hintText: 'Search Students',
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    flex: 2,
                    child: CustomDropdown(
                      hintText: 'Select Classroom',
                      items: _classrooms,
                      selectedItem: _customSelectedClassroom ?? 'All',
                      onSelect: (val) {
                        setState(() {
                          _customSelectedClassroom = (val == null || val.isEmpty) ? 'All' : val;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          CustomDateTimeField(
            hasLabel: false,
            isRangePicker: true,
            fetchInitialTime: false,
            initialDate: _customRangeStart,
            onRangeSelected: (start, end) {
              setState(() {
                _customRangeStart = start;
                _customRangeEnd = end;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(List<_CustomAttendanceRow> filtered) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (filtered.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        ...filtered.asMap().entries.map((entry) {
          return _buildCustomStudentCard(entry.value, entry.key);
        }),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    final responsive = ResponsiveHelper(context);
    return Column(
      children: List.generate(
        8,
        (index) => AttendanceCardShimmer(
          margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorColor, size: 48),
            const SizedBox(height: 16),
            AppText.title(
              'Error loading attendance data',
              style: TextStyle(color: AppColors.errorColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText.body(
              _errorMessage.isNotEmpty ? _errorMessage : 'Please try again.',
              style: TextStyle(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadAttendanceData(reset: true),
              icon: const Icon(Icons.refresh),
              label: AppText.body('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                color: AppColors.secondaryColor, size: 48),
            const SizedBox(height: 16),
            AppText.title(
              'No attendance data found',
              style: TextStyle(color: AppColors.secondaryColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppText.body(
              'Try adjusting your search criteria or date range',
              style: TextStyle(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
      String label, int index, int selectedTab, void Function(int) onTap) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AppText.body(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? const Color(0xFF222B45) : const Color(0xFF8F9BB3),
        ),
      ),
    );
  }

  Widget _buildCustomStudentCard(_CustomAttendanceRow attendance, int index) {
    final responsive = ResponsiveHelper(context);
    final bool isExpanded = _customExpandedStudentIndex == index;

    final studentName =
        attendance.studentName.isNotEmpty ? attendance.studentName : 'Unknown Student';
    final roomName = attendance.roomName.isNotEmpty ? attendance.roomName : 'Unknown Room';
    final daysAttended = attendance.daysAttended.isNotEmpty ? attendance.daysAttended : '0';
    final totalHours = attendance.totalHours.isNotEmpty ? attendance.totalHours : '0 Hrs 0 Mins';

    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final dotSize = responsive.isTablet ? 14.0 : 12.0;

    final bool showGreenDot =
        attendance.hasSignIn && (attendance.signOutTime == null || attendance.signOutTime!.isEmpty);
    final bool showRedDot = !attendance.hasSignIn && attendance.expectedToday == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _customExpandedStudentIndex =
              (_customExpandedStudentIndex == index) ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DocumentImageWidget(
                      fileUuid: attendance.studentPhotoUuid,
                      size: avatarSize,
                      name: studentName,
                      fontSize: responsive.isTablet ? 18 : 16,
                    ),
                    if (showGreenDot)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 177, 21, 1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      )
                    else if (showRedDot)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(200, 32, 32, 1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppText.body(
                    studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                AppText.body(
                  'Attended Days : $daysAttended',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  AppText.small(
                    'Classroom',
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                  const Spacer(),
                  Flexible(
                    child: AppText.value(
                      roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  AppText.small(
                    'Attended Time',
                    style: TextStyle(color: AppColors.secondaryColor),
                  ),
                  const Spacer(),
                  AppText.value(totalHours),
                ],
              ),
              SizedBox(height: responsive.verticalSpacing / 1.2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _loadingButtons[attendance.id] == true
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CustomCancelButton(
                          cancelButtonLabel: 'View',
                          onPressedCancel: () async {
                            setState(() => _loadingButtons[attendance.id] = true);
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (!mounted) return;
                            setState(() => _loadingButtons[attendance.id] = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentId: attendance.studentId,
                                  studentName: attendance.studentName,
                                  studentPhotoUuid: attendance.studentPhotoUuid,
                                  roomName: attendance.roomName,
                                  isSignedIn: attendance.hasSignIn,
                                  isAbsent: !attendance.hasSignIn && attendance.expectedToday,
                                  isExpectedToday: attendance.expectedToday,
                                  isPresentToday: attendance.hasSignIn,
                                  profileStatus: 'A',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Simple positioning methods for tab indicator (matches reference implementation)
  double _getTabIndicatorPosition(int selectedTab) {
    double position = 0;
    for (int i = 0; i < selectedTab; i++) {
      position += _getTabWidth(i) + 13;
    }
    return position;
  }

  double _getTabIndicatorWidth(int selectedTab) {
    return _getTabWidth(selectedTab);
  }

  double _getTabWidth(int tabIndex) {
    switch (tabIndex) {
      case 0: // Daily
        return 45.0;
      case 1: // Custom
        return 55.0;
      case 2: // Absent
        return 50.0;
      default:
        return 45.0;
    }
  }
}

class _CustomAttendanceRow {
  final String id;
  final int studentId;
  final String studentName;
  final String studentPhotoUuid;
  final String roomName;
  final String daysAttended;
  final String totalHours;
  final bool expectedToday;
  final bool hasSignIn;
  final String? signOutTime;

  const _CustomAttendanceRow({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentPhotoUuid,
    required this.roomName,
    required this.daysAttended,
    required this.totalHours,
    required this.expectedToday,
    required this.hasSignIn,
    required this.signOutTime,
  });
}
