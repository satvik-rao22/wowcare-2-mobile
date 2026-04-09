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
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_absent_toggle_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';

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
  int? _expandedStaffIndex;
  int? _expandedAbsentIndex;

  late final StaffAttendanceDailyCubit _cubit;
  late final StaffAttendanceAbsentToggleCubit _absentToggleCubit;
  late final ClassroomCubit _classroomCubit;

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
    _absentToggleCubit = serviceLocator<StaffAttendanceAbsentToggleCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>();

    // Load initial data from API
    _loadAttendanceData(context, reset: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _absentToggleCubit.close();
    _classroomCubit.close();
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
    final classroomCodes = _staffFilters?.classrooms;
    // For now, designation is filtered on the frontend only (no backend API filter),
    // so we do NOT send designation/tagCodes to the attendance APIs.
    final List<String>? tagCodes = null;
    final search = _searchQuery.isEmpty ? null : _searchQuery;

    if (_showAbsentOnly) {
      debugPrint(
        '[StaffDaily] Loading ABSENT toggle list | date=$_selectedDate | '
        'classrooms=$classroomCodes | tags=$tagCodes | search=$search | reset=$reset',
      );
      if (reset) {
        // Match student implementation: reset → refresh first page
        _absentToggleCubit.refresh(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      } else {
        _absentToggleCubit.loadInitial(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      }
      return;
    }

    debugPrint(
      '[StaffDaily] Loading DAILY list (non-absent) | date=$_selectedDate | '
      'classrooms=$classroomCodes | tags=$tagCodes | search=$search | reset=$reset',
    );

    if (reset) {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      );
    } else {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
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
    // Start with the full list from state.
    var filtered = List<StaffAttendanceCardData>.from(_staffMembers);

    // Apply legend filter first (Present, etc.).
    if (_statusLegendFilter != null) {
      if (_statusLegendFilter == 'Present') {
        filtered = filtered.where((staff) => staff.hasSignIn).toList();
      }
      // Other legend statuses (Absent, etc.) are handled via _showAbsentOnly toggle.
    }

    // Apply designation filter (frontend-only) when provided via StaffFilterScreen.
    final designationFilters = _staffFilters?.tags ?? const <String>[];
    if (designationFilters.isNotEmpty) {
      final selectedDesignation = designationFilters.first.trim().toUpperCase();
      if (selectedDesignation.isNotEmpty) {
        filtered = filtered.where((staff) {
          final name = staff.designationName?.trim().toUpperCase() ?? '';
          return name == selectedDesignation;
        }).toList();
      }
    }

    return filtered;
  }

  String? _formatDesignation(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll('_', ' ').toLowerCase();
    if (cleaned.isEmpty) return null;
    // Title-case each word
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final formatted = words
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
    return formatted;
  }

  void _clearAllFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDate = DateTime.now();
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffAttendanceDailyCubit>.value(value: _cubit),
        BlocProvider<StaffAttendanceAbsentToggleCubit>.value(
          value: _absentToggleCubit,
        ),
      ],
      child: BlocBuilder<StaffAttendanceAbsentToggleCubit,
          StaffAttendanceAbsentToggleState>(
        builder: (context, absentState) {
          return BlocBuilder<StaffAttendanceDailyCubit,
              StaffAttendanceDailyState>(
            builder: (context, state) {
              final isAbsentMode = _showAbsentOnly;
              final isLoading = isAbsentMode
                  ? absentState.isLoading
                  : (state.isLoading || state.isSummaryLoading);
              final isLoadingMore =
                  isAbsentMode ? absentState.isLoadingMore : state.isLoadingMore;
              final hasMore =
                  isAbsentMode ? absentState.hasMore : state.hasMore;

              return CustomRefreshIndicator(
                onRefresh: () async {
                  _loadAttendanceData(context, reset: false);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                      if (!isLoading && !isLoadingMore && hasMore) {
                        if (isAbsentMode) {
                          _absentToggleCubit.loadNextPage();
                        } else {
                          _cubit.loadNextPage();
                        }
                      }
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
                        // Summary Cards - expected stats from API, total/active/upcoming still placeholders
                        StaffAttendanceSummary(
                          totalStaff: totalStaff,
                          active: active,
                          upcoming: upcoming,
                          expected: state.expectedCount ?? expected,
                          present: state.presentCount ?? present,
                          absent: state.absentCount ?? absent,
                          signedOut: state.signedOutCount ?? signedOut,
                          notMarked: state.notMarkedCount ?? notMarked,
                          isLoading: (state.isLoading ||
                                  state.isSummaryLoading) &&
                              !_showAbsentOnly,
                          onLegendTap: (status) {
                            setState(() {
                              if (status == 'Present') {
                                _statusLegendFilter =
                                    _statusLegendFilter == status
                                        ? null
                                        : status;
                                _showAbsentOnly = false;
                              } else if (status == 'Absent') {
                                _showAbsentOnly = !_showAbsentOnly;
                                _statusLegendFilter = null;
                              }
                            });
                            _loadAttendanceData(context, reset: false);
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
                          _buildAbsentStaffList(absentState)
                        else
                          _buildStaffListFromState(state),
                      ],
                    ),
                  ),
                ),
              );
            },
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
                    final result =
                        await Navigator.push<Map<String, dynamic>?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: _classroomCubit,
                          child: StaffFilterScreen(
                            initialFilters: _staffFilters,
                            selectedDate: _selectedDate,
                            sections: const [
                              StaffFilterSection.classroom,
                              StaffFilterSection.designation,
                            ],
                          ),
                        ),
                      ),
                    );

                    if (!mounted || result == null) return;

                    final String? status =
                        (result['status'] as String?)?.trim();
                    final String? designation =
                        (result['designation'] as String?)?.trim();
                    final List<String> classCodes =
                        (result['classCodes'] as List?)?.cast<String>() ??
                            const <String>[];
                    final String? sortBy =
                        (result['sortBy'] as String?)?.trim();

                    setState(() {
                      _staffFilters = FilterData(
                        classroomIds: const <int>[],
                        classrooms: classCodes,
                        statuses: status == null || status.isEmpty
                            ? const <String>[]
                            : <String>[status],
                        // NOTE: StaffFilterScreen uses "designation" for this field.
                        // We keep it in `tags` because the existing daily view already
                        // treats `tags` as the second API filter list.
                        tags: designation == null || designation.isEmpty
                            ? const <String>[]
                            : <String>[designation],
                        sortBy: sortBy,
                      );
                    });

                    _loadAttendanceData(context, reset: true);
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
                  if (value) {
                    // When toggling to Absent, clear legend filters so only absent view applies.
                    _statusLegendFilter = 'Absent';
                  } else if (_statusLegendFilter == 'Absent') {
                    _statusLegendFilter = null;
                  }
                });
                debugPrint('[StaffDaily] Show Absent toggled: $_showAbsentOnly');
                _loadAttendanceData(context, reset: true);
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
      // Compute effective sign-in/sign-out display for transfer sequences.
      String? effectiveSignIn;
      String? effectiveSignOut;
      bool transferSignIn = false;
      bool transferSignOut = false;
      final int seq = item.sequenceNumber ?? 1;
      final int totalSeq = item.totalSequenceCount ?? 1;

      if (totalSeq <= 1) {
        effectiveSignIn = item.formattedSignInTime;
        effectiveSignOut = item.formattedSignOutTime;
      } else {
        final isFirst = seq == 1;
        final isLast = seq == totalSeq;

        if (isFirst && !isLast) {
          effectiveSignIn = item.formattedSignInTime;
          effectiveSignOut = item.nextActionTime?.formattedTime;
          transferSignOut = effectiveSignOut != null;
        } else if (!isFirst && !isLast) {
          effectiveSignIn = item.transferTime?.formattedTime;
          effectiveSignOut = item.nextActionTime?.formattedTime;
          transferSignIn = effectiveSignIn != null;
          transferSignOut = effectiveSignOut != null;
        } else if (isLast) {
          effectiveSignIn =
              isFirst ? item.formattedSignInTime : item.transferTime?.formattedTime;
          effectiveSignOut = item.formattedSignOutTime;
          transferSignIn = !isFirst && effectiveSignIn != null;
        }
      }

      final String? rawDesignation =
          item.designation.isNotEmpty ? item.designation.first : null;
      final String? formattedDesignation = _formatDesignation(rawDesignation);

      _staffMembers.add(
        StaffAttendanceCardData(
          attendanceRecordCode: item.attendanceRecordCode,
          id: item.staffCode,
          staffName: item.staffName,
          staffPhotoUuid: null,
          designationName: formattedDesignation,
          roomName: item.classroomName,
          expectedToday: item.isExpectedToday,
          hasSignIn: item.hasSignIn,
          signInTime: effectiveSignIn ?? item.formattedSignInTime,
          signOutTime: effectiveSignOut ?? item.formattedSignOutTime,
          signInBy: _normalizeByName(item.signedInBy),
          signOutBy: _normalizeByName(item.signedOutBy),
          // Map backend method codes (GPS, PIN, QR, APP, etc.) to UI enum.
          signInMethod: _mapMethodStringToEnum(item.signedInMethod),
          signOutMethod: _mapMethodStringToEnum(item.signedOutMethod),
          staffId: 0,
          roomId: 0,
          schoolId: 0,
          sequenceNumber: item.sequenceNumber,
          totalSequenceCount: item.totalSequenceCount,
          isTransferSignIn: transferSignIn,
          isTransferSignOut: transferSignOut,
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
          onEdit: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => StaffEditAttendanceForm(
                  staffAttendance: staff,
                  attendanceDate: _selectedDate,
                ),
              ),
            );
            if (updated == true) {
              _loadAttendanceData(context, reset: true);
            }
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
                  onDelete: () async {
                    Navigator.of(ctx).pop();
                    if (staff.attendanceRecordCode == null ||
                        staff.attendanceRecordCode!.isEmpty) {
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: const SnackBar(
                          content: Text(
                            'Unable to delete: missing attendance record code.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final normalizedAttendanceCode =
                          _normalizeAttendanceRecordCodeForMutation(
                        staff.attendanceRecordCode!,
                      );
                      if (normalizedAttendanceCode.isEmpty) {
                        CoreUtils.showTopSnackBarFromSnackBar(
                          context: context,
                          snackBar: const SnackBar(
                            content: Text(
                              'Unable to delete: invalid attendance record code.',
                            ),
                          ),
                        );
                        return;
                      }

                      final storageService = serviceLocator<StorageService>();
                      final staffCode =
                          (await storageService.getString(
                                    StorageKeys.staffCode,
                                  ) ??
                                  '')
                              .trim();
                      if (staffCode.isEmpty) {
                        if (!context.mounted) return;
                        CoreUtils.showTopSnackBarFromSnackBar(
                          context: context,
                          snackBar: const SnackBar(
                            content: Text(
                              'Unable to resolve staffCode. Please re-login.',
                            ),
                          ),
                        );
                        return;
                      }

                      final apiClient = serviceLocator<ApiClient>().client;
                      final endpoint = ApiPaths.urlWithBase(
                        '/api/v1/staff-attendance-records/$normalizedAttendanceCode',
                        ApiConstants.attendanceBaseUrl,
                      );

                      await apiClient.delete<dynamic>(
                        endpoint,
                        queryParameters: <String, dynamic>{
                          'staffCode': staffCode,
                        },
                      );

                      if (!context.mounted) return;
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: const SnackBar(
                          content: Text('Attendance deleted'),
                        ),
                      );
                      _loadAttendanceData(context, reset: true);
                    } catch (e) {
                      if (!context.mounted) return;
                      final message = ApiErrorHandler.extractErrorMessage(e);
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: SnackBar(
                          content: Text(message),
                        ),
                      );
                    }
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

  String? _normalizeByName(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  SignMethod? _mapMethodStringToEnum(String? method) {
    if (method == null) return null;
    final normalized = method.trim().toUpperCase();
    switch (normalized) {
      case 'GPS':
        return SignMethod.gps;
      case 'PIN':
      case 'KIOSK':
        // PIN entry is effectively via kiosk device.
        return SignMethod.kiosk;
      case 'QR':
        return SignMethod.qr;
      case 'APP':
        return SignMethod.direct;
      default:
        return null;
    }
  }

  String _normalizeAttendanceRecordCodeForMutation(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return trimmed;
    final tildeIndex = trimmed.indexOf('~');
    if (tildeIndex <= 0) return trimmed;
    return trimmed.substring(0, tildeIndex);
  }

  Widget _buildAbsentStaffList(
    StaffAttendanceAbsentToggleState absentState,
  ) {
    if (absentState.items.isEmpty) {
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

    final items = absentState.items;

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final it = entry.value;
        final roomName =
            it.classroomName.isNotEmpty ? it.classroomName : it.classroomCode;
        final absenceDate = it.absenceDate;
        final absentTime = it.markedAbsentTime?.formattedHms ?? '';
        final staff = StaffAbsentCardData(
          id: it.staffCode,
          name: it.staffName,
          photoUuid: null,
          roomName: roomName,
          absentTime: absentTime,
          absentBy: it.markedAbsentByName,
          note: it.absenceNote,
          staffId: index,
          roomId: 0,
          schoolId: 0,
          startDate: absenceDate,
          endDate: absenceDate,
          hasSignIn: false,
          expectedToday: true,
          signInTime: null,
          signOutTime: null,
        );
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
