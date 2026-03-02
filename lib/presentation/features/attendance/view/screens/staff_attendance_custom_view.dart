import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_custom_cubit.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';

class StaffAttendanceCustomView extends StatefulWidget {
  const StaffAttendanceCustomView({
    super.key,
    this.contentOnly = false,
  });

  final bool contentOnly;

  @override
  State<StaffAttendanceCustomView> createState() => _StaffAttendanceCustomViewState();
}

class _StaffAttendanceCustomViewState extends State<StaffAttendanceCustomView> {
  final TextEditingController _customSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String? _customSelectedClassroom;
  DateTime? _customRangeStart;
  DateTime? _customRangeEnd;
  int? _customExpandedStaffIndex;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<_CustomStaffAttendanceRow> _attendanceList = <_CustomStaffAttendanceRow>[];
  List<String> _classrooms = <String>['All'];

  late final StaffAttendanceCustomCubit _cubit;

  @override
  void initState() {
    super.initState();
    _customSelectedClassroom = 'All';
    _customSearchController.addListener(_onSearchChanged);
    _initializeDefaultRange();
    _cubit = serviceLocator<StaffAttendanceCustomCubit>();
    _loadAttendanceData(reset: true);
  }

  @override
  void dispose() {
    _customSearchController.removeListener(_onSearchChanged);
    _customSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeDefaultRange() {
    final now = DateTime.now();
    _customRangeStart = DateTime(now.year, now.month, 1);
    _customRangeEnd = now;
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _customSearchController.text;
    });
    _loadAttendanceData(reset: true);
  }

  // Method to load attendance data from backend
  void _loadAttendanceData({bool reset = false}) {
    if (_customRangeStart == null || _customRangeEnd == null) {
      _initializeDefaultRange();
    }

    final from = _customRangeStart!;
    final to = _customRangeEnd!;

    final classroomCodes = _customSelectedClassroom != null &&
            _customSelectedClassroom != 'All'
        ? <String>[_customSelectedClassroom!]
        : null;

      if (reset) {
        _customExpandedStaffIndex = null;
      _cubit.loadInitial(
        fromDate: from,
        toDate: to,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    } else {
      _cubit.refresh(
        fromDate: from,
        toDate: to,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    }
  }

  List<_CustomStaffAttendanceRow> _buildDummyAttendanceData() {
    final rooms = _classrooms.where((e) => e != 'All').toList();
    if (rooms.isEmpty) {
      rooms.addAll(<String>['Room 1', 'Room 2', 'Room 3']);
    }

    return List<_CustomStaffAttendanceRow>.generate(18, (i) {
      final idx = i + 1;
      final room = rooms[i % rooms.length];
      final expectedToday = idx % 6 != 0; // some are not expected
      final signedIn = expectedToday && idx % 4 != 0;

      return _CustomStaffAttendanceRow(
        id: 'custom_staff_$idx',
        staffId: idx,
        staffName: 'Staff Member $idx',
        designationName: 'Teacher',
        roomName: room,
        daysAttended: '${(idx % 22) + 1}',
        totalHours: '${(idx % 6) + 1} Hrs ${(idx * 7) % 60} Mins',
        expectedToday: expectedToday,
        hasSignIn: signedIn,
        staffPhotoUuid: '',
        schoolId: 1,
        roomId: (i % 3) + 1,
      );
    });
  }

  List<_CustomStaffAttendanceRow> _getFilteredAttendance() {
    var filtered = _attendanceList;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((attendance) {
        return attendance.staffName.toLowerCase().contains(query) ||
            attendance.roomName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply classroom filter
    if (_customSelectedClassroom != null && _customSelectedClassroom != 'All') {
      filtered = filtered.where((attendance) {
        return attendance.roomName == _customSelectedClassroom;
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

    return BlocProvider<StaffAttendanceCustomCubit>.value(
      value: _cubit,
      child: BlocBuilder<StaffAttendanceCustomCubit, StaffAttendanceCustomState>(
        builder: (context, state) {
          final isLoading = state.isLoading;

          final items = state.items;
          _attendanceList
            ..clear()
            ..addAll(
              items.map(
                (item) => _CustomStaffAttendanceRow(
                  id: item.staffCode,
                  staffId: 0,
                  staffName: item.staffName,
                  designationName:
                      item.designation.isNotEmpty ? item.designation.first : null,
                  staffPhotoUuid: '',
                  roomName: item.classroomName,
                  daysAttended: item.attendedDays.toString(),
                  totalHours: item.attendedTime ?? '',
                  expectedToday: item.isExpectedToday,
                  hasSignIn: item.hasSignIn,
                  schoolId: 0,
                  roomId: 0,
                ),
              ),
            );

    final filtered = _getFilteredAttendance();

    return CustomRefreshIndicator(
      onRefresh: () async {
              _loadAttendanceData(reset: false);
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
                          controller: _customSearchController,
                          hintText: 'Search Staff',
                        ),
                      ),
                      SizedBox(width: responsive.horizontalSpacing / 2),
                      Expanded(
                        flex: responsive.isTablet ? 2 : 1,
                        child: CustomDropdown(
                          hintText: 'Select Classroom',
                          items: _classrooms,
                                  selectedItem:
                                      _customSelectedClassroom ?? 'All',
                          onSelect: (val) {
                            setState(() {
                              _customSelectedClassroom = val;
                            });
                            _loadAttendanceData(reset: true);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  CustomDateTimeField(
                    hasLabel: false,
                    isRangePicker: true,
                    initialDate: _customRangeStart,
                    onRangeSelected: (start, end) {
                              if (start != null &&
                                  end != null &&
                                  start.isAfter(end)) {
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
                        _customRangeStart = start;
                        _customRangeEnd = end;
                      });
                      _loadAttendanceData(reset: true);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Content area
                    if (isLoading)
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
                    (index) => ShimmerLoader(
                      height: 80,
                              margin: EdgeInsets.only(
                                  bottom: responsive.verticalSpacing / 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      AppText.body(
                        'No staff attendance found',
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
                    final attendance = entry.value;
                    return _buildCustomStaffCard(attendance, index);
                  }).toList(),
                ],
              ),
            // Add some bottom padding for better scrolling
            SizedBox(height: responsive.verticalSpacing),
          ],
        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomStaffCard(_CustomStaffAttendanceRow attendance, int index) {
    final responsive = ResponsiveHelper(context);
    final bool isExpanded = _customExpandedStaffIndex == index;

    final staffName = attendance.staffName.isNotEmpty
        ? attendance.staffName
        : 'Unknown Staff';
    final roomName = attendance.roomName.isNotEmpty
        ? attendance.roomName
        : 'Unknown Room';
    final daysAttended = attendance.daysAttended.isNotEmpty
        ? attendance.daysAttended
        : '0';
    final totalHours = attendance.totalHours.isNotEmpty
        ? attendance.totalHours
        : '0 Hrs 0 Mins';

    final avatarSize = responsive.isTablet ? 52.0 : 44.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_customExpandedStaffIndex == index) {
            _customExpandedStaffIndex = null;
          } else {
            _customExpandedStaffIndex = index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isTablet ? 16 : 12,
          vertical: responsive.isTablet ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
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
                // Profile photo
                DocumentImageWidget(
                  fileUuid: attendance.staffPhotoUuid,
                  name: staffName,
                  size: avatarSize,
                  fontSize: responsive.isTablet ? 18 : 16,
                ),
                SizedBox(width: responsive.horizontalSpacing / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body(
                        staffName,
                        style: TextStyle(
                          fontSize: responsive.labelFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (attendance.designationName != null &&
                          attendance.designationName!.isNotEmpty) ...[
                        SizedBox(height: responsive.verticalSpacing / 4),
                        AppText.small(
                          attendance.designationName!,
                          style: TextStyle(
                            fontSize: responsive.isTablet ? 14 : 12,
                            color: AppColors.secondaryColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppText.body(
                  'Attended Days: $daysAttended',
                  style: TextStyle(
                    fontSize: responsive.isTablet ? 16 : 15,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(
                responsive,
                'Classroom',
                roomName,
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Attended Time',
                totalHours,
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing / 2,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: responsive.buttonHeight * 0.8,
                  child: CustomCancelButton(
                    onPressedCancel: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffAttendanceProfile(
                            staffCode: attendance.id,
                            staffId: attendance.staffId,
                            staffName: staffName,
                            staffPhotoUuid: attendance.staffPhotoUuid,
                            designationName: attendance.designationName,
                            roomName: roomName,
                            isSignedIn: attendance.hasSignIn,
                            isAbsent: false,
                            isExpectedToday: attendance.expectedToday,
                            isPresentToday: attendance.hasSignIn,
                            profileStatus: 'A',
                          ),
                        ),
                      );
                    },
                    cancelButtonLabel: 'View',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ResponsiveHelper responsive,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: AppText.small(
            label,
            style: TextStyle(
              fontSize: responsive.isTablet ? 14 : 12,
              color: AppColors.secondaryColor.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: AppText.value(
            value,
            style: TextStyle(
              fontSize: responsive.isTablet ? 16 : 14,
            ),
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CustomStaffAttendanceRow {
  final String id;
  final int staffId;
  final String staffName;
  final String? designationName;
  final String staffPhotoUuid;
  final String roomName;
  final String daysAttended;
  final String totalHours;
  final bool expectedToday;
  final bool hasSignIn;
  final int schoolId;
  final int roomId;

  const _CustomStaffAttendanceRow({
    required this.id,
    required this.staffId,
    required this.staffName,
    this.designationName,
    required this.staffPhotoUuid,
    required this.roomName,
    required this.daysAttended,
    required this.totalHours,
    required this.expectedToday,
    required this.hasSignIn,
    required this.schoolId,
    required this.roomId,
  });
}
