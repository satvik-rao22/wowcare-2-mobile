import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_custom_cubit.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_responsive_detail_row.dart';

class StaffAttendanceCustomView extends StatefulWidget {
  const StaffAttendanceCustomView({super.key, this.contentOnly = false});

  final bool contentOnly;

  @override
  State<StaffAttendanceCustomView> createState() =>
      _StaffAttendanceCustomViewState();
}

class _StaffAttendanceCustomViewState extends State<StaffAttendanceCustomView>
    implements AttendanceTabRefresh {
  final TextEditingController _customSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  List<String> _selectedClassroomNames = <String>[];
  List<String>? _selectedClassroomCodes;
  DateTime? _customRangeStart;
  DateTime? _customRangeEnd;
  int? _customExpandedStaffIndex;
  bool _isClassroomDataReady = false;

  final List<_CustomStaffAttendanceRow> _attendanceList =
      <_CustomStaffAttendanceRow>[];

  late final StaffAttendanceCustomCubit _cubit;
  late final ClassroomCubit _classroomCubit;
  final Map<String, String> _classroomNameByCode = {};
  final Set<String> _classroomFetchInFlight = {};

  @override
  void initState() {
    super.initState();
    _customSearchController.addListener(_onSearchChanged);
    _initializeDefaultRange();
    _cubit = serviceLocator<StaffAttendanceCustomCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>();
    // Staff screens intentionally load all ACTIVE locations (not just type=CLASSROOM).
    // Guard for "data not loaded yet" so name->code resolution is reliable.
    _loadClassroomData();
    _loadAttendanceData(reset: true);
    // Resolve the school timezone, then re-seed the default range to the school
    // month if it differs (handles a device in a different zone on cold start).
    _initSchoolTimezone();
  }

  Future<void> _initSchoolTimezone() async {
    final beforeStart = _customRangeStart;
    final beforeEnd = _customRangeEnd;
    await bootstrapAttendanceSchoolTimezone();
    if (!mounted) return;
    final now = attendanceSchoolToday();
    final schoolStart = DateTime(now.year, now.month, 1);
    // Re-seed only if the range is still the initial default (untouched).
    if (beforeStart == _customRangeStart &&
        beforeEnd == _customRangeEnd &&
        (_customRangeStart != schoolStart || _customRangeEnd != now)) {
      setState(() {
        _customRangeStart = schoolStart;
        _customRangeEnd = now;
      });
      _loadAttendanceData(reset: true);
    }
  }

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    _loadAttendanceData(reset: true);
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
        _syncClassroomFilterCodes();
        if (_selectedClassroomCodes != null) {
          _loadAttendanceData(reset: true);
        }
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
      _isClassroomDataReady =
          !_classroomCubit.state.isLoading &&
          _classroomCubit.state.classrooms.isNotEmpty;
    });
    if (hadClassroomSelection && _isClassroomDataReady) {
      _syncClassroomFilterCodes();
      if (_selectedClassroomCodes != null) {
        _loadAttendanceData(reset: true);
      }
    }
  }

  @override
  void dispose() {
    _customSearchController.removeListener(_onSearchChanged);
    _customSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _resolveClassroomNameByCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final classrooms = _classroomCubit.state.classrooms;
    for (final c in classrooms) {
      if (c.code.trim() == trimmed) return c.name;
    }
    final cached = _classroomNameByCode[trimmed]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> _fetchClassroomName(String code) async {
    try {
      final name = await _cubit.fetchClassroomName(code);
      if (!mounted) return;
      if (name != null && name.isNotEmpty) {
        setState(() {
          _classroomNameByCode[code] = name;
        });
      }
    } finally {
      _classroomFetchInFlight.remove(code);
    }
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    final code = classroomCode.trim();
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;
    if (code.isEmpty) return '';
    final fromCubit = _resolveClassroomNameByCode(code);
    if (fromCubit != null && fromCubit.trim().isNotEmpty)
      return fromCubit.trim();
    if (!_classroomFetchInFlight.contains(code)) {
      _classroomFetchInFlight.add(code);
      // ignore: discarded_futures
      _fetchClassroomName(code);
    }
    return code;
  }

  void _initializeDefaultRange() {
    final now = attendanceSchoolToday();
    _customRangeStart = DateTime(now.year, now.month, 1);
    _customRangeEnd = now;
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _customSearchController.text;
    });
    _loadAttendanceData(reset: true);
  }

  void _syncClassroomFilterCodes() {
    _selectedClassroomCodes = resolveClassroomNamesToCodes(
      selectedNamesOrCodes: _selectedClassroomNames,
      classrooms: _classroomCubit.state.classrooms,
    );
  }

  List<String>? _effectiveClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) {
      _selectedClassroomCodes = null;
      return null;
    }
    _syncClassroomFilterCodes();
    return _selectedClassroomCodes;
  }

  void _reloadIfPendingClassroomFilter() {
    if (_selectedClassroomNames.isEmpty) return;
    _syncClassroomFilterCodes();
    if (_selectedClassroomCodes == null) return;
    _loadAttendanceData(reset: true);
  }

  // Method to load attendance data from backend
  void _loadAttendanceData({bool reset = false}) {
    if (_customRangeStart == null || _customRangeEnd == null) {
      _initializeDefaultRange();
    }

    final from = _customRangeStart!;
    final to = _customRangeEnd!;

    final classroomCodes = _effectiveClassroomCodes();
    if (_selectedClassroomNames.isNotEmpty && classroomCodes == null) {
      return;
    }

    if (reset) {
      _customExpandedStaffIndex = null;
    }

    _cubit.refresh(
      fromDate: from,
      toDate: to,
      classroomCodes: classroomCodes,
      tagCodes: null,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  List<_CustomStaffAttendanceRow> _getFilteredAttendance() {
    // Classroom and search filters are applied server-side via classroomCodes/search.
    return _attendanceList;
  }

  String? _formatDesignation(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll('_', ' ').toLowerCase();
    if (cleaned.isEmpty) return null;
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final formatted = words
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    final Widget content = MultiBlocProvider(
      providers: [
        BlocProvider<StaffAttendanceCustomCubit>.value(value: _cubit),
        BlocProvider<ClassroomCubit>.value(value: _classroomCubit),
      ],
      child: BlocListener<ClassroomCubit, ClassroomState>(
        bloc: _classroomCubit,
        listenWhen: (previous, current) =>
            previous.classrooms.isEmpty && current.classrooms.isNotEmpty,
        listener: (_, __) => _reloadIfPendingClassroomFilter(),
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
                    designationName: _formatDesignation(
                      item.designation.isNotEmpty
                          ? item.designation.first
                          : null,
                    ),
                    staffPhotoUuid: '',
                    classroomCode: item.classroomCode,
                    classroomName: item.classroomName,
                    roomName: _classroomDisplay(
                      classroomCode: item.classroomCode,
                      classroomName: item.classroomName,
                    ),
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
                    vertical: responsive.verticalSpacing / 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
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
                                SizedBox(
                                  width: responsive.horizontalSpacing / 2,
                                ),
                                Expanded(
                                  flex: responsive.isTablet ? 2 : 1,
                                  child:
                                      BlocBuilder<
                                        ClassroomCubit,
                                        ClassroomState
                                      >(
                                        builder: (context, classroomState) {
                                          final items = classroomState
                                              .classrooms
                                              .map((c) => c.name)
                                              .toList();
                                          final isLoading =
                                              classroomState.isLoading ||
                                              !_isClassroomDataReady;
                                          if (isLoading && items.isEmpty) {
                                            return ShimmerLoader(
                                              height: 40,
                                              borderRadius: AppRadius.allMd,
                                            );
                                          }

                                          return CustomMultiSelectDropdown(
                                            hintText: 'Classroom',
                                            items: items,
                                            selectedItems:
                                                _selectedClassroomNames,
                                            onChanged: (values) {
                                              setState(() {
                                                _selectedClassroomNames =
                                                    List<String>.from(values);
                                                _syncClassroomFilterCodes();
                                              });
                                              if (_selectedClassroomNames
                                                      .isNotEmpty &&
                                                  _selectedClassroomCodes ==
                                                      null) {
                                                return;
                                              }
                                              _loadAttendanceData(reset: true);
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
                                      if (end != null && start.isAfter(end)) {
                                        CoreUtils.showTopSnackBarFromSnackBar(
                                          context: context,
                                          snackBar: SnackBar(
                                            content: const Text(
                                              'Start date cannot be after end date',
                                            ),
                                            backgroundColor:
                                                AppColors.errorColor,
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
                                ),
                                SizedBox(
                                  width: responsive.horizontalSpacing / 2,
                                ),
                                CustomClearAllChip(
                                  onTap: () {
                                    setState(() {
                                      _customSearchController.clear();
                                      _searchQuery = '';
                                      _selectedClassroomNames = <String>[];
                                      _selectedClassroomCodes = null;
                                      final now = attendanceSchoolToday();
                                      _customRangeStart = DateTime(
                                        now.year,
                                        now.month,
                                        1,
                                      );
                                      _customRangeEnd = DateTime(
                                        now.year,
                                        now.month + 1,
                                        0,
                                      );
                                    });
                                    _loadAttendanceData(reset: true);
                                  },
                                ),
                              ],
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
                                bottom: responsive.verticalSpacing / 2,
                              ),
                              borderRadius: AppRadius.allLg,
                            ),
                            ...List.generate(
                              6,
                              (index) => ShimmerLoader(
                                height: 80,
                                margin: EdgeInsets.only(
                                  bottom: responsive.verticalSpacing / 2,
                                ),
                                borderRadius: AppRadius.allLg,
                              ),
                            ),
                          ],
                        )
                      else if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color:
                                      AppColors.attendanceEmptyStateIconColor,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppText.body(
                                  'No staff attendance found',
                                  style: const TextStyle(
                                    color:
                                        AppColors.attendanceDialogHintTextColor,
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
                              return _CustomStaffCardItem(
                                attendance: attendance,
                                isExpanded: _customExpandedStaffIndex == index,
                                onTap: () {
                                  setState(() {
                                    _customExpandedStaffIndex =
                                        _customExpandedStaffIndex == index
                                        ? null
                                        : index;
                                  });
                                },
                              );
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
      ),
    );

    if (widget.contentOnly) {
      return content;
    }

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: content,
    );
  }
}

class _CustomStaffCardItem extends StatelessWidget {
  const _CustomStaffCardItem({
    required this.attendance,
    required this.isExpanded,
    required this.onTap,
  });

  final _CustomStaffAttendanceRow attendance;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

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
      onTap: onTap,
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
              color: AppColors.attendanceCardShadowLightColor,
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
                  staffCode: attendance.id,
                  name: staffName,
                  size: avatarSize,
                  fontSize: responsive.isTablet ? 18 : 16,
                  disableAttendanceStatusLookup: true,
                ),
                SizedBox(width: responsive.horizontalSpacing / 2),
                // Header matches staff_card.dart: name (left) + classroom (right).
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          staffName,
                          style: AppTextStyles.body.copyWith(
                            fontSize: responsive.isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          roomName,
                          style: AppTextStyles.body.copyWith(
                            fontSize: responsive.isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              AttendanceResponsiveDetailRow(
                responsive: responsive,
                label: 'Attended Time',
                value: totalHours,
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              AttendanceResponsiveDetailRow(
                responsive: responsive,
                label: 'Attended Days',
                value: daysAttended,
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
                      context.push(
                        StaffAttendanceProfile.routeName,
                        extra: {
                          'staffCode': attendance.id,
                          'staffId': attendance.staffId,
                          'staffName': staffName,
                          'staffPhotoUuid': attendance.staffPhotoUuid,
                          'designationName': attendance.designationName,
                          'roomName': roomName,
                          'isSignedIn': attendance.hasSignIn,
                          'isAbsent': false,
                          'isExpectedToday': attendance.expectedToday,
                          'isPresentToday': attendance.hasSignIn,
                          'profileStatus': 'A',
                        },
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
}

class _CustomStaffAttendanceRow {
  final String id;
  final int staffId;
  final String staffName;
  final String? designationName;
  final String staffPhotoUuid;
  final String classroomCode;
  final String classroomName;
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
    required this.classroomCode,
    required this.classroomName,
    required this.roomName,
    required this.daysAttended,
    required this.totalHours,
    required this.expectedToday,
    required this.hasSignIn,
    required this.schoolId,
    required this.roomId,
  });
}
