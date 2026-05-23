import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_card.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/staff/view/add_staff_screen.dart';
import 'package:wowcare/shared/common/widgets/post_add_staff_bottom_sheet.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({
    super.key,
    this.incomingStatusFilter,
  });

  static const String routeName = '/dashboard/staff';
  final String? incomingStatusFilter;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showInactive = false;
  final Set<String> _selectedStaffCodes = <String>{};
  bool _selectAll = false;
  StaffPanelType _currentPanel = StaffPanelType.none;
  // Tracks if the current refresh was triggered by changing filters/search,
  // so we only show the shimmer loader in that case.
  bool _refreshTriggeredByFilters = false;
  final Map<String, String> _attendanceStatusByStaffCode = <String, String>{};
  bool _attendanceStatusLoading = false;
  bool _attendanceStatusError = false;

  int _expectedStaffTotal = 0;
  int _expectedSignedIn = 0;
  int _expectedAbsent = 0;
  int _expectedSignedOut = 0;
  int _expectedNotMarked = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Staff list must resolve names for all ACTIVE locations (e.g. admin/office).
      // Uses GET .../classroom/classroom/all?school=...&status=ACTIVE with no type= filter.
      // (Add-staff keeps type=CLASSROOM via its own ClassroomCubit instance.)
      context.read<ClassroomCubit>().loadActiveClassrooms(
        force: true,
        onlyTypeClassroom: false,
      );
      _applyIncomingStatusFilter();
      _loadExpectedStaffSummary();
    });
  }

  Future<void> _applyIncomingStatusFilter() async {
    final incoming = (widget.incomingStatusFilter ?? '').trim().toUpperCase();
    if (incoming != 'ACTIVE' && incoming != 'UPCOMING' && incoming != 'INACTIVE') {
      return;
    }

    final staffCubit = context.read<StaffCubit>();
    final currentState = staffCubit.state;
    staffCubit.updateFilters(
      status: incoming,
      designation: currentState.designationFilter,
      primaryClassroomCodes: currentState.primaryClassroomCodes,
      classCodes: currentState.classCodes,
      sortBy: currentState.sortBy,
    );

    if (!mounted) return;
    setState(() {
      _showInactive = incoming == 'INACTIVE';
      _refreshTriggeredByFilters = true;
    });
    await staffCubit.refresh();
  }

  void _onScroll() {
    _maybeLoadNextPage();
  }

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<StaffCubit>();
    final state = cubit.state;
    // Debug: log scroll + pagination state
    final position = _scrollController.position;
    // ignore: avoid_print
    print(
      '[StaffScreen] scroll pixels=${position.pixels}, '
      'max=${position.maxScrollExtent}, '
      'hasMore=${state.hasMore}, '
      'isLoadingMore=${state.isLoadingMore}, '
      'items=${state.items.length}',
    );
    if (state.isLoadingMore || !state.hasMore) return;
    // When content doesn't fill the viewport but we have more data, load next page
    if (position.maxScrollExtent <= 0) {
      // ignore: avoid_print
      print('[StaffScreen] maxScrollExtent <= 0, forcing loadNextPage');
      cubit.loadNextPage();
      return;
    }
    // Load next page when within 400px of the bottom
    if (position.pixels >= position.maxScrollExtent - 400) {
      // ignore: avoid_print
      print('[StaffScreen] near bottom, requesting next page');
      cubit.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // (Unused for now) Helper that can detect active filters/search on staff list.
  // bool _hasActiveFilters(StaffState state) {
  //   final status = (state.statusFilter ?? '').trim().toUpperCase();
  //   final designation = (state.designationFilter ?? '').trim();
  //   final hasClassroomFilter =
  //       (state.primaryClassroomCodes?.isNotEmpty ?? false) ||
  //       (state.classCodes?.isNotEmpty ?? false);
  //   final hasNonDefaultStatus =
  //       status.isNotEmpty && status != 'ACTIVE'; // ACTIVE is the default
  //   final hasDesignation = designation.isNotEmpty;
  //   final hasSearch = (state.searchQuery ?? '').trim().isNotEmpty;
  //
  //   return hasNonDefaultStatus ||
  //       hasDesignation ||
  //       hasClassroomFilter ||
  //       hasSearch;
  // }

  // Helper to get classroom names and code mapping from cubit state
  List<String> _getClassroomNames(ClassroomState state) {
    return state.classrooms.map((c) => c.name).toList();
  }

  Map<String, String> _getClassroomNameByCode(ClassroomState state) {
    return {for (final c in state.classrooms) c.code: c.name};
  }

  /// Merges `classroom/all` (no type filter on staff screen) with names embedded
  /// in the staff list API so admin / non-classroom codes still show a label.
  Map<String, String> _mergedClassroomNameByCode({
    required Map<String, String> fromClassroomCubit,
    required List<StaffMember> staffItems,
  }) {
    final out = Map<String, String>.from(fromClassroomCubit);
    for (final s in staffItems) {
      final pc = s.primaryClassroomCode.trim();
      final pn = s.primaryClassroomName.trim();
      if (pc.isNotEmpty && pn.isNotEmpty) {
        out.putIfAbsent(pc, () => pn);
      }
      for (final e in s.allowedClassroomNameByCode.entries) {
        final k = e.key.trim();
        final v = e.value.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          out.putIfAbsent(k, () => v);
        }
      }
    }
    return out;
  }

  List<String> _classroomDisplayNamesForStaffScreen({
    required ClassroomState classroomState,
    required Map<String, String> mergedCodeToName,
  }) {
    final fromCubit = _getClassroomNames(classroomState);
    final seen = fromCubit.map((e) => e.trim()).toSet();
    final out = List<String>.from(fromCubit);
    for (final n in mergedCodeToName.values) {
      final t = n.trim();
      if (t.isNotEmpty && !seen.contains(t)) {
        seen.add(t);
        out.add(t);
      }
    }
    out.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return out;
  }

  String _resolveStaffPrimaryClassroomLabel(
    StaffMember staff,
    Map<String, String> codeToName,
  ) {
    final code = staff.primaryClassroomOrFirstAllowed.trim();
    if (code.isEmpty) return '';
    final fromCubit = (codeToName[code] ?? '').trim();
    if (fromCubit.isNotEmpty) return fromCubit;
    if (staff.primaryClassroomCode.trim() == code) {
      final fromList = staff.primaryClassroomName.trim();
      if (fromList.isNotEmpty) return fromList;
    }
    final fromAllowedMap =
        (staff.allowedClassroomNameByCode[code] ?? '').trim();
    if (fromAllowedMap.isNotEmpty) return fromAllowedMap;
    return code;
  }

  List<String> _allowedClassroomDisplayNames(
    StaffMember staff,
    Map<String, String> codeToName,
  ) {
    return staff.allowedClassroomCodes
        .map((c) {
          final t = c.trim();
          if (t.isEmpty) return '';
          return (codeToName[t] ?? '').trim().isNotEmpty
              ? (codeToName[t] ?? '').trim()
              : (staff.allowedClassroomNameByCode[t] ?? '').trim().isNotEmpty
                  ? (staff.allowedClassroomNameByCode[t] ?? '').trim()
                  : t;
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExpectedStaffSummary() async {
    if (!mounted) return;
    try {
      final useCase =
          serviceLocator<GetStaffAttendanceExpectedSummaryUseCase>();
      final primary =
          context.read<StaffCubit>().state.primaryClassroomCodes ?? const [];
      final code =
          primary.isEmpty ? null : primary.first.trim();
      final summary = await useCase(
        classroomCode: (code != null && code.isNotEmpty) ? code : null,
      );
      if (!mounted) return;
      setState(() {
        _expectedStaffTotal = summary.expected;
        _expectedSignedIn = summary.present;
        _expectedAbsent = summary.absent;
        _expectedSignedOut = summary.signOut;
        _expectedNotMarked = summary.notMarked;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _expectedStaffTotal = 0;
        _expectedSignedIn = 0;
        _expectedAbsent = 0;
        _expectedSignedOut = 0;
        _expectedNotMarked = 0;
      });
    }
  }

  void _openStaffAttendanceWithLegendFilter(String status) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StaffAttendanceTabbedView(
          initialTabIndex: 0,
          dailyIncomingFilter: status,
        ),
      ),
    );
  }

  Future<void> _refreshAttendanceStatusForSelection() async {
    if (_selectedStaffCodes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      return;
    }

    setState(() {
      _attendanceStatusLoading = true;
      _attendanceStatusError = false;
    });

    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusMapUseCase>();
      final map = await useCase(staffCodes: _selectedStaffCodes.toList());
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode
          ..clear()
          ..addAll(map);
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = true;
      });
    }
  }

  StaffAttendanceActionAvailability _attendanceAvailabilityForSelection(
    StaffState staffState,
  ) {
    if (_selectedStaffCodes.isEmpty) {
      return StaffAttendanceActionAvailability.allDisabled;
    }
    if (_attendanceStatusLoading || _attendanceStatusError) {
      return StaffAttendanceActionAvailability.allDisabled;
    }

    final gates = <StaffAttendanceGate>[];
    for (final code in _selectedStaffCodes) {
      StaffMember? member;
      for (final s in staffState.items) {
        if (s.code == code) {
          member = s;
          break;
        }
      }
      final status = _attendanceStatusByStaffCode[code];
      gates.add(
        staffAttendanceGateFromTodayStatus(
          isActiveProfile:
              member != null && member.status.trim().toUpperCase() == 'ACTIVE',
          todayStatusRaw: status,
        ),
      );
    }

    return StaffAttendanceActionAvailability.fromGates(gates);
  }

  Future<void> _openAttendanceActionFlow(String actionName) async {
    if (_selectedStaffCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select at least one staff',
        isError: true,
      );
      return;
    }

    final selectedCodes = Set<String>.from(
      _selectedStaffCodes,
    ).where((c) => c.trim().isNotEmpty).toSet();
    if (selectedCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected staff are missing staff codes',
        isError: true,
      );
      return;
    }

    final date = _formatDate(DateTime.now());
    try {
      List<StaffEntity> targets = <StaffEntity>[];

      if (actionName == 'sign_in') {
        final useCase = serviceLocator<GetStaffSignInFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        targets = eligible.asMap().entries.map((entry) {
          final item = entry.value;
          return StaffEntity(
            id: entry.key + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            classroomCode: item.classroomCode,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
            isExpectedToday: item.isExpectedToday,
          );
        }).toList();
      } else if (actionName == 'sign_out') {
        final useCase = serviceLocator<GetStaffSignOutFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        targets = eligible.asMap().entries.map((entry) {
          final item = entry.value;
          return StaffEntity(
            id: entry.key + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
          );
        }).toList();
      } else if (actionName == 'transfer') {
        final useCase = serviceLocator<GetStaffTransferFormListUseCase>();
        final page = await useCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        targets = eligible.asMap().entries.map((entry) {
          final item = entry.value;
          return StaffEntity(
            id: entry.key + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
          );
        }).toList();
      } else {
        final useCase = serviceLocator<GetStaffAbsentFormListUseCase>();
        final page = await useCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        targets = eligible.asMap().entries.map((entry) {
          final item = entry.value;
          return StaffEntity(
            id: entry.key + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: 'Staff',
            staffCode: item.staffCode,
          );
        }).toList();
      }

      if (!mounted) return;
      if (targets.isEmpty) {
        throw Exception('No selected staff is eligible for this action');
      }

      if (actionName == 'sign_in') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffSignInForm(staffList: targets),
          ),
        );
      } else if (actionName == 'sign_out') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffSignOutForm(staffList: targets),
          ),
        );
      } else if (actionName == 'transfer') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffTransferForm(staffList: targets),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffMarkAbsentForm(staffList: targets),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        final staffState = context.watch<StaffCubit>().state;
        final baseNameByCode = _getClassroomNameByCode(classroomState);
        final classroomNameByCode = _mergedClassroomNameByCode(
          fromClassroomCubit: baseNameByCode,
          staffItems: staffState.items,
        );
        final classroomNames = _classroomDisplayNamesForStaffScreen(
          classroomState: classroomState,
          mergedCodeToName: classroomNameByCode,
        );

        // Log error if classroom loading failed (no UI display - core_utils only)
        if (classroomState.errorMessage != null &&
            classroomState.classrooms.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CoreUtils.logApiError(classroomState.errorMessage!);
            context.read<ClassroomCubit>().clearError();
          });
        }

        final double titleFontSize = ResponsiveSizing.titleFontSize(context);
        final double titleLineHeight = ResponsiveSizing.titleLineHeight(
          context,
        );

        final staffCubit = context.read<StaffCubit>();

        final bool anySelected = _selectedStaffCodes.isNotEmpty;
        final int selectedCount = _selectedStaffCodes.length;

        return GlobalScaffold(
          body: Stack(
            children: [
              CustomRefreshIndicator(
                onRefresh: () async {
                  // Refresh staff list and classrooms cache so newly added classrooms
                  // (or changes from other flows) are reflected.
                  await Future.wait([
                    staffCubit.refresh(),
                    context.read<ClassroomCubit>().loadActiveClassrooms(
                      force: true,
                      onlyTypeClassroom: false,
                    ),
                    _loadExpectedStaffSummary(),
                  ]);
                  if (mounted && _selectedStaffCodes.isNotEmpty) {
                    await _refreshAttendanceStatusForSelection();
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: ResponsiveSizing.contentPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Staff',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff573353),
                                  height: titleLineHeight,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            GradientAddButton(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddStaffScreen(
                                      initialClassroomNames: classroomNames,
                                      // AddStaffScreen expects a name -> code map.
                                      initialClassroomCodeByName: {
                                        for (final entry
                                            in classroomNameByCode.entries)
                                          entry.value: entry.key,
                                      },
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                print(
                                  '[StaffScreen] Received result from AddStaffScreen: ' +
                                      result.toString(),
                                );

                                // After a successful add, refresh the staff list so cache + UI reflect new staff
                                if (result is Map) {
                                  await staffCubit.refresh();
                                }

                                if (result is Map &&
                                    (result['showPostAddPrompt'] == true)) {
                                  final staffName =
                                      (result['staffName'] as String?) ?? '';
                                  final editArgs = Map<String, dynamic>.from(
                                    result,
                                  );
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (ctx) => PostAddStaffBottomSheet(
                                        staffName: staffName,
                                        onLater: () => Navigator.of(ctx).pop(),
                                        onYes: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context)
                                              .pushNamed(
                                                '/edit-profile-details-screen',
                                                arguments: editArgs,
                                              )
                                              .then((_) {
                                                if (mounted)
                                                  staffCubit.refresh();
                                              });
                                        },
                                      ),
                                    );
                                  });
                                }
                              },
                              isTablet:
                                  MediaQuery.of(context).size.width >= 600,
                              isLargeTablet:
                                  MediaQuery.of(context).size.width >= 900,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Total Staff stat card
                        BlocBuilder<StaffCubit, StaffState>(
                          builder: (context, state) {
                            final double active = state.staffCountActive
                                .toDouble();
                            final double upcoming = state.staffCountUpcoming
                                .toDouble();
                            // Status bar distribution should reflect only Active + Upcoming,
                            // so the total displayed here is the sum of those two buckets,
                            // regardless of any other statuses (e.g. Inactive) in the system.
                            final int totalCount = (active + upcoming).toInt();

                            final items = [
                              ProgressItemHelper(
                                label: 'Active (${state.staffCountActive})',
                                value: active,
                                color: AppColors.lightBlueProgressBar,
                                filterValue: 'ACTIVE',
                              ),
                              ProgressItemHelper(
                                label: 'Upcoming (${state.staffCountUpcoming})',
                                value: upcoming,
                                color: AppColors.mustardProgressBar,
                                filterValue: 'UPCOMING',
                              ),
                            ];

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final bool isTablet =
                                    constraints.maxWidth >= 600;
                                return Container(
                                  margin: EdgeInsets.only(
                                    top: isTablet ? 16 : 12,
                                    bottom: isTablet ? 8 : 8,
                                  ),
                                  child: CustomStatBarCard(
                                    title: 'Total\nStaff',
                                    number: '$totalCount',
                                    items: items,
                                    fullWidthBar: false,
                                    onLegendTap: (label, filterValue) async {
                                      if (filterValue == null ||
                                          filterValue.trim().isEmpty)
                                        return;
                                      final staffCubit = context
                                          .read<StaffCubit>();
                                      final staffState = context
                                          .read<StaffCubit>()
                                          .state;
                                      staffCubit.updateFilters(
                                        status: filterValue.trim(),
                                        designation:
                                            staffState.designationFilter,
                                      );
                                      if (!context.mounted) return;
                                      setState(() {
                                        _showInactive =
                                            filterValue.trim().toUpperCase() ==
                                            'INACTIVE';
                                        _refreshTriggeredByFilters = true;
                                      });
                                      await staffCubit.refresh();
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Expected Staff (same breakdown as Staff Attendance daily summary)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isTablet = constraints.maxWidth >= 600;
                            final present = _expectedSignedIn.toDouble();
                            final absent = _expectedAbsent.toDouble();
                            final signedOut = _expectedSignedOut.toDouble();
                            final notMarked = _expectedNotMarked.toDouble();
                            final items = [
                              ProgressItemHelper(
                                label: 'Signed-In (${present.toInt()})',
                                value: present,
                                color: AppColors.lightGreenProgressBar,
                                filterValue: 'Signed-In',
                              ),
                              ProgressItemHelper(
                                label: 'Absent (${absent.toInt()})',
                                value: absent,
                                color: AppColors.redProgressBar,
                                filterValue: 'Absent',
                              ),
                              ProgressItemHelper(
                                label: 'Signed Out (${signedOut.toInt()})',
                                value: signedOut,
                                color: AppColors.lightBlueProgressBar,
                                filterValue: 'Signed Out',
                              ),
                              ProgressItemHelper(
                                label: 'Not Marked (${notMarked.toInt()})',
                                value: notMarked,
                                color: AppColors.mustardProgressBar,
                                filterValue: 'Not Marked',
                              ),
                            ];
                            return Container(
                              margin: EdgeInsets.only(
                                top: isTablet ? 8 : 8,
                                bottom: isTablet ? 8 : 8,
                              ),
                              child: CustomStatBarCard(
                                title: 'Expected\nStaff',
                                number: '$_expectedStaffTotal',
                                items: items,
                                fullWidthBar: false,
                                normalizeBarByItemSum: true,
                                onLegendTap: (String label, String? filterValue) {
                                  final status = label.split(' ').first;
                                  if (status == 'Signed-In' ||
                                      status == 'Absent' ||
                                      status == 'Signed' ||
                                      status == 'Not') {
                                    if (status == 'Signed') {
                                      _openStaffAttendanceWithLegendFilter(
                                        'Signed Out',
                                      );
                                    } else if (status == 'Not') {
                                      _openStaffAttendanceWithLegendFilter(
                                        'Not Marked',
                                      );
                                    } else {
                                      _openStaffAttendanceWithLegendFilter(
                                        status,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Filter card with search and filter icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                            ),
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
                                      onChanged: (value) {
                                        final query = value.trim();
                                        final classroomCubit = context
                                            .read<ClassroomCubit>();
                                        // Keep classrooms in sync while searching.
                                        classroomCubit.loadActiveClassrooms(
                                          force: true,
                                          onlyTypeClassroom: false,
                                        );

                                        // For empty query, reset to full data (staff + counts).
                                        if (query.isEmpty) {
                                          staffCubit.updateSearch('');
                                          _refreshTriggeredByFilters = true;
                                          staffCubit.refresh(
                                            ignoreRefreshingGuard: true,
                                          );
                                        } else {
                                          // Rapid search: only hit the staff list API on each keystroke.
                                          staffCubit.searchStaff(query);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final classroomCubit = context
                                            .read<ClassroomCubit>();
                                        // Build initial filters from current staff state so the
                                        // filter screen reflects the active status/designation.
                                        final rawStatus =
                                            (staffState.statusFilter ?? '')
                                                .trim()
                                                .toUpperCase();
                                        String? initialStatus;
                                        if (rawStatus == 'UPCOMING') {
                                          initialStatus = 'UPCOMING';
                                        } else {
                                          // For no explicit status filter or statuses not exposed in
                                          // the filter (e.g. INACTIVE/ARCHIVE), show nothing selected.
                                          initialStatus = null;
                                        }

                                        final String? initialDesignation =
                                            (staffState.designationFilter ?? '')
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : staffState.designationFilter;

                                        // Initial primary vs allowed classroom names so filter UI shows correct dropdowns
                                        final primaryCodes =
                                            staffState.primaryClassroomCodes ??
                                            const [];
                                        final allowedCodes =
                                            staffState.classCodes ?? const [];
                                        final initialPrimaryNames = primaryCodes
                                            .map(
                                              (c) =>
                                                  classroomNameByCode[c]?.trim(),
                                            )
                                            .whereType<String>()
                                            .where((n) => n.isNotEmpty)
                                            .toList();
                                        final initialAllowedNames = allowedCodes
                                            .map(
                                              (c) =>
                                                  classroomNameByCode[c]?.trim(),
                                            )
                                            .whereType<String>()
                                            .where((n) => n.isNotEmpty)
                                            .toList();

                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BlocProvider<
                                                  ClassroomCubit
                                                >.value(
                                                  value: classroomCubit,
                                                  child: StaffFilterScreen(
                                                    initialFilters: FilterData(
                                                      classroomIds: const [],
                                                      classrooms: const [],
                                                      primaryClassrooms:
                                                          initialPrimaryNames,
                                                      allowedClassrooms:
                                                          initialAllowedNames,
                                                      statuses:
                                                          initialStatus != null
                                                          ? <String>[
                                                              initialStatus,
                                                            ]
                                                          : const <String>[],
                                                      tags:
                                                          initialDesignation !=
                                                              null
                                                          ? <String>[
                                                              initialDesignation,
                                                            ]
                                                          : const <String>[],
                                                      attendanceStatuses:
                                                          const <String>[],
                                                      sortBy: staffState.sortBy,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        );
                                        if (!mounted) return;
                                        if (result is Map) {
                                          final status =
                                              result['status'] as String?;
                                          final designation =
                                              result['designation'] as String?;
                                          final primaryClassroomCodes =
                                              result['primaryClassroomCodes']
                                                  as List<String>?;
                                          final classCodes =
                                              result['classCodes']
                                                  as List<String>?;
                                          final sortBy =
                                              result['sortBy'] as String?;
                                          staffCubit.updateFilters(
                                            status: status,
                                            designation: designation,
                                            primaryClassroomCodes:
                                                primaryClassroomCodes,
                                            classCodes: classCodes,
                                            sortBy: sortBy,
                                          );
                                          setState(() {
                                            _showInactive =
                                                (status ?? '').toUpperCase() ==
                                                'INACTIVE';
                                            _refreshTriggeredByFilters = true;
                                          });
                                          await staffCubit.refresh();
                                        }
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
                                          Builder(
                                            builder: (context) {
                                              // Show a badge when any non-default filters are applied.
                                              final status =
                                                  (staffState.statusFilter ??
                                                          '')
                                                      .trim();
                                              final designation =
                                                  (staffState.designationFilter ??
                                                          '')
                                                      .trim();
                                              final hasClassroomFilter =
                                                  (staffState
                                                          .primaryClassroomCodes
                                                          ?.isNotEmpty ??
                                                      false) ||
                                                  (staffState
                                                          .classCodes
                                                          ?.isNotEmpty ??
                                                      false);

                                              final statusUpper = status
                                                  .toUpperCase();
                                              // Treat both ACTIVE and INACTIVE as "base" views so they
                                              // don't show a filter badge; only other statuses (e.g. UPCOMING)
                                              // should contribute to the badge count.
                                              final bool hasNonDefaultStatus =
                                                  statusUpper.isNotEmpty &&
                                                  statusUpper != 'ACTIVE' &&
                                                  statusUpper != 'INACTIVE';
                                              final bool hasDesignation =
                                                  designation.isNotEmpty;

                                              final int badgeCount =
                                                  (hasNonDefaultStatus
                                                      ? 1
                                                      : 0) +
                                                  (hasDesignation ? 1 : 0) +
                                                  (hasClassroomFilter ? 1 : 0);

                                              if (badgeCount == 0)
                                                return const SizedBox.shrink();

                                              return Positioned(
                                                right: 2,
                                                top: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromRGBO(
                                                      179,
                                                      38,
                                                      30,
                                                      1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    badgeCount > 99
                                                        ? '99+'
                                                        : '$badgeCount',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomChip(
                                        label: (() {
                                          final raw =
                                              (staffState.statusFilter ?? '')
                                                  .trim();
                                          final normalized = raw.isEmpty
                                              ? 'ACTIVE'
                                              : raw.toUpperCase();
                                          // Keep display friendly: "Active", "Upcoming", "Inactive", etc.
                                          return normalized.substring(0, 1) +
                                              normalized
                                                  .substring(1)
                                                  .toLowerCase();
                                        })(),
                                        labelStyle: const TextStyle(
                                          color: AppColors.secondaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        color: const Color.fromRGBO(
                                          177,
                                          175,
                                          233,
                                          0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CustomClearAllChip(
                                        onTap: () async {
                                          // Clear search field
                                          _searchController.clear();
                                          // Clear all filters and refresh atomically (updates cache)
                                          _refreshTriggeredByFilters = true;
                                          await staffCubit
                                              .clearAllFiltersAndRefresh();
                                          if (!mounted) return;
                                          setState(() => _showInactive = false);
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Show inactive',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xff573353),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CustomToggle(
                                        label: '',
                                        isToggled: _showInactive,
                                        onToggle: (v) async {
                                          setState(() => _showInactive = v);

                                          // Implement API: staff list supports `status` query param.
                                          staffCubit.updateFilters(
                                            status: v ? 'INACTIVE' : 'ACTIVE',
                                            designation:
                                                staffState.designationFilter,
                                          );
                                          _refreshTriggeredByFilters = true;
                                          await staffCubit.refresh();

                                          if (!mounted) return;
                                          final err =
                                              staffCubit.state.errorMessage;
                                          if (err != null && err.isNotEmpty) {
                                            CoreUtils.logApiError(err);
                                          } else {
                                            CoreUtils.showTopSnackBar(
                                              context: context,
                                              message: v
                                                  ? 'Showing inactive staff'
                                                  : 'Showing active staff',
                                              isSuccess: true,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Select All outside the search box
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomCheckbox(
                            label: 'Select All',
                            value: _selectAll,
                            onChanged: (v) {
                              final newVal = v ?? false;
                              setState(() {
                                _selectAll = newVal;
                                _selectedStaffCodes.clear();
                                if (newVal) {
                                  final items = staffCubit.state.items;
                                  _selectedStaffCodes.addAll(
                                    items.map((e) => e.code),
                                  );
                                }
                              });
                              _refreshAttendanceStatusForSelection();
                            },
                          ),
                        ),
                        // Placeholder for staff list content
                        const SizedBox(height: 16),
                        BlocBuilder<StaffCubit, StaffState>(
                          builder: (context, state) {
                            // Reset flag once a filter-triggered refresh finishes.
                            if (!state.isRefreshing &&
                                _refreshTriggeredByFilters) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _refreshTriggeredByFilters = false;
                                  });
                                }
                              });
                            }

                            // Show shimmer on initial load, or when a refresh was
                            // explicitly triggered by changing filters/search.
                            final bool showFilteredRefreshLoader =
                                state.isRefreshing &&
                                _refreshTriggeredByFilters;
                            if ((state.isLoading && state.items.isEmpty) ||
                                showFilteredRefreshLoader) {
                              return Column(
                                children: List.generate(
                                  6,
                                  (index) => const StaffCardShimmer(
                                    margin: EdgeInsets.only(bottom: 8),
                                  ),
                                ),
                              );
                            }

                            if (state.errorMessage != null &&
                                state.items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'Unable to load staff. Please try again.',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              );
                            }

                            if (state.items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(child: Text('No staff found')),
                              );
                            }

                            // After list is built, check if we're near bottom and should load more
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _maybeLoadNextPage();
                            });

                            return Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.items.length,
                                  itemBuilder: (context, index) {
                                    final staff = state.items[index];
                                    final isActive =
                                        (staff.status).toUpperCase() ==
                                        'ACTIVE';
                                    final allowedClassroomNames =
                                        _allowedClassroomDisplayNames(
                                      staff,
                                      classroomNameByCode,
                                    );

                                    final primaryClassroomName =
                                        _resolveStaffPrimaryClassroomLabel(
                                      staff,
                                      classroomNameByCode,
                                    );
                                    final primaryClassroomNameForCard =
                                        primaryClassroomName.isNotEmpty
                                            ? primaryClassroomName
                                            : (allowedClassroomNames.isNotEmpty
                                                  ? allowedClassroomNames.first
                                                  : '');
                                    final isSelected = _selectedStaffCodes
                                        .contains(staff.code);
                                    return Column(
                                      children: [
                                        StaffCard(
                                          staffCode: staff.code,
                                          name: staff.name,
                                          classroom: primaryClassroomNameForCard,
                                          profilePhotoAssetCode:
                                              staff.profilePhotoAssetCode,
                                          allowedClassrooms:
                                              allowedClassroomNames,
                                          // Days with any work/break schedule from staff list API.
                                          schedule: const [
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                          ],
                                          designation: staff.designation,
                                          email: staff.email,
                                          phoneNumber: staff.phoneNumber,
                                          isActive: isActive,
                                          status: staff.status,
                                          availableClassrooms: classroomNames,
                                          classroomCodeByName:
                                              classroomNameByCode,
                                          workScheduleByDay:
                                              staff.workScheduleByDay,
                                          breakScheduleByDay:
                                              staff.breakScheduleByDay,
                                          onPrimaryAction: () async {
                                            try {
                                              final message = isActive
                                                  ? await staffCubit
                                                        .deactivateStaff(
                                                          staff.code,
                                                        )
                                                  : await staffCubit
                                                        .activateStaff(
                                                          staff.code,
                                                        );
                                              if (!mounted) return;
                                              CoreUtils.showTopSnackBar(
                                                context: context,
                                                message: message,
                                                isSuccess: true,
                                              );
                                              // Close the bottom sheet after success if it's open.
                                              Navigator.of(context).maybePop();
                                            } catch (e) {
                                              if (!mounted) return;
                                              CoreUtils.logApiError(
                                                ApiErrorHandler.extractErrorMessage(
                                                  e,
                                                ),
                                              );
                                            }
                                          },
                                          isSelected: isSelected,
                                          onSelected: (checked) {
                                            setState(() {
                                              if (checked == true) {
                                                _selectedStaffCodes.add(
                                                  staff.code,
                                                );
                                              } else {
                                                _selectedStaffCodes.remove(
                                                  staff.code,
                                                );
                                              }
                                              _selectAll =
                                                  _selectedStaffCodes.length ==
                                                      state.items.length &&
                                                  state.items.isNotEmpty;
                                            });
                                            _refreshAttendanceStatusForSelection();
                                          },
                                        ),
                                        if (index != state.items.length - 1)
                                          const SizedBox(height: 8),
                                      ],
                                    );
                                  },
                                ),
                                if (state.isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: PrimaryCircularLoader(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (anySelected)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: StaffActionPanel(
                    currentPanel: _currentPanel,
                    attendanceAvailability: _attendanceAvailabilityForSelection(
                      staffState,
                    ),
                    onAttendanceTap: () {
                      setState(() {
                        _currentPanel =
                            _currentPanel == StaffPanelType.attendance
                            ? StaffPanelType.none
                            : StaffPanelType.attendance;
                      });
                    },
                    onActivitiesTap: () {
                      setState(() {
                        _currentPanel =
                            _currentPanel == StaffPanelType.activities
                            ? StaffPanelType.none
                            : StaffPanelType.activities;
                      });
                    },
                    onMessageTap: () {},
                    onProfileTap: selectedCount == 1
                        ? () {
                            final staffState = staffCubit.state;
                            final selectedCode = _selectedStaffCodes.first;
                            final staff = staffState.items.firstWhere(
                              (e) => e.code == selectedCode,
                            );
                            final allowedClassroomNames =
                                _allowedClassroomDisplayNames(
                              staff,
                              classroomNameByCode,
                            );
                            final primaryResolved =
                                _resolveStaffPrimaryClassroomLabel(
                              staff,
                              classroomNameByCode,
                            );
                            final classroomName =
                                primaryResolved.isNotEmpty
                                ? primaryResolved
                                : (allowedClassroomNames.isNotEmpty
                                      ? allowedClassroomNames.first
                                      : '');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaffProfileScreen(
                                  staffCode: staff.code,
                                  name: staff.name,
                                  classroom: classroomName,
                                  designation: staff.designation,
                                  phoneNumber: staff.phoneNumber,
                                  employmentStatus: staff.status,
                                  classroomNames: classroomNames,
                                  classroomNameByCode: classroomNameByCode,
                                ),
                              ),
                            );
                          }
                        : null,
                    onSignIn: () => _openAttendanceActionFlow('sign_in'),
                    onSignOut: () => _openAttendanceActionFlow('sign_out'),
                    onTransfer: () => _openAttendanceActionFlow('transfer'),
                    onAbsent: () => _openAttendanceActionFlow('mark_absent'),
                    onClearSelections: () {
                      setState(() {
                        _selectAll = false;
                        _selectedStaffCodes.clear();
                        _currentPanel = StaffPanelType.none;
                      });
                      _refreshAttendanceStatusForSelection();
                    },
                    isProfileEnabled: selectedCount == 1,
                    activitiesEnabled: selectedCount > 0,
                    ),
                  ),
                ),
            ],
          ),
          showCustomNavigationBar: true,
        );
      },
    );
  }
}
