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
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/classroom/datasources/classroom_remote_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  static const String routeName = '/staff';

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

   // Cached classrooms for this screen – loaded once and reused.
   final List<String> _classroomNames = <String>[];
   final Map<String, String> _classroomNameByCode = <String, String>{};
   bool _isLoadingClassrooms = false;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms({bool force = false}) async {
    if (_isLoadingClassrooms) return;
    if (!force && _classroomNames.isNotEmpty) return;

    if (force) {
      _classroomNames.clear();
      _classroomNameByCode.clear();
    }

    _isLoadingClassrooms = true;
    try {
      // TEMP: Always use default school code constant, ignore stored prefs.
      final schoolCode = StorageKeys.defaultSchoolCode;

      final classroomRemote = serviceLocator<ClassroomRemoteDataSource>();
      final response = await classroomRemote.getActiveClassrooms(
        schoolCode: schoolCode,
      );

      if (!mounted) return;

      if (response.items.isEmpty) {
        return;
      }

      final names = <String>[];
      final nameByCode = <String, String>{};
      for (final c in response.items) {
        names.add(c.name);
        nameByCode[c.code] = c.name;
      }

      setState(() {
        _classroomNames
          ..clear()
          ..addAll(names);
        _classroomNameByCode
          ..clear()
          ..addAll(nameByCode);
      });
    } catch (e) {
      if (!mounted) return;
      // Surface classroom load errors via CoreUtils so users see what went wrong.
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    } finally {
      _isLoadingClassrooms = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

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
                _loadClassrooms(force: true),
              ]);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  staffCubit.loadNextPage();
                }
                return false;
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
                            initialClassroomNames: _classroomNames,
                            // AddStaffScreen expects a name -> code map.
                            initialClassroomCodeByName: {
                              for (final entry in _classroomNameByCode.entries)
                                entry.value: entry.key,
                            },
                          ),
                        ),
                      );
                      if (!mounted) return;
                      print('[StaffScreen] Received result from AddStaffScreen: ' + result.toString());

                      // After a successful add, refresh the staff list so cache + UI reflect new staff
                      if (result is Map) {
                        await staffCubit.refresh();
                      }

                      if (result is Map && (result['showPostAddPrompt'] == true)) {
                        final staffName = (result['staffName'] as String?) ?? '';
                        WidgetsBinding.instance.addPostFrameCallback((_) {
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
                                Navigator.of(context).pushNamed('/edit-profile-details-screen');
                              },
                            ),
                          );
                        });
                      }
                    },
                    isTablet: MediaQuery.of(context).size.width >= 600,
                    isLargeTablet: MediaQuery.of(context).size.width >= 900,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total Staff stat card
              BlocBuilder<StaffCubit, StaffState>(
                builder: (context, state) {
                  final double active = state.staffCountActive.toDouble();
                  final double upcoming = state.staffCountUpcoming.toDouble();
                  final int totalCount =
                      state.staffCountTotal > 0 ? state.staffCountTotal : (active + upcoming).toInt();

                  final items = [
                    ProgressItemHelper(
                      label: 'Active (${state.staffCountActive})',
                      value: active,
                      color: AppColors.lightBlueProgressBar,
                    ),
                    ProgressItemHelper(
                      label: 'Upcoming (${state.staffCountUpcoming})',
                      value: upcoming,
                      color: AppColors.mustardProgressBar,
                    ),
                  ];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isTablet = constraints.maxWidth >= 600;
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
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Expected Students stat card
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isTablet = constraints.maxWidth >= 600;
                  // Demo values for present/absent
                  final double present = 18.0;
                  final double absent = 3.0;
                  final int expectedTotal = (present + absent).toInt();
                  final String total = '$expectedTotal';
                  final items = [
                    ProgressItemHelper(
                      label: 'Present (${present.toInt()})',
                      value: present,
                      color: AppColors.lightGreenProgressBar,
                    ),
                    ProgressItemHelper(
                      label: 'Absent (${absent.toInt()})',
                      value: absent,
                      color: AppColors.redProgressBar,
                    ),
                  ];
                  return Container(
                    margin: EdgeInsets.only(top: isTablet ? 8 : 8, bottom: isTablet ? 8 : 8),
                    child: CustomStatBarCard(
                      title: 'Expected\nStudents',
                      number: total,
                      items: items,
                      fullWidthBar: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Filter card with search and filter icon
              Container(
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
                            onChanged: (value) {
                              // Apply search to staff list and refresh (also updates cache via repository)
                              staffCubit.updateSearch(value.trim());
                              staffCubit.refresh();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaffFilterScreen(),
                                ),
                              );
                              if (!mounted) return;
                              if (result is Map) {
                                final status = result['status'] as String?;
                                final designation = result['designation'] as String?;
                                // Apply filters and refresh list so cache + UI stay in sync
                                staffCubit.updateFilters(
                                  status: status,
                                  designation: designation,
                                );
                                await staffCubit.refresh();
                              }
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CustomChip(
                              label: 'Active',
                              labelStyle: TextStyle(
                                color: AppColors.secondaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              color: Color.fromRGBO(177, 175, 233, 0.3),
                            ),
                            const SizedBox(width: 8),
                            const CustomClearAllChip(onTap: null),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Show present',
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
                              onToggle: (v) => setState(() => _showInactive = v),
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
                        _selectedStaffCodes
                            .addAll(items.map((e) => e.code));
                      }
                    });
                  },
                ),
              ),
              // Placeholder for staff list content
              const SizedBox(height: 16),
              BlocBuilder<StaffCubit, StaffState>(
                builder: (context, state) {
                  if (state.isLoading && state.items.isEmpty) {
                    return Column(
                      children: List.generate(
                        6,
                        (index) => const StaffCardShimmer(
                          margin: EdgeInsets.only(bottom: 8),
                        ),
                      ),
                    );
                  }

                  if (state.errorMessage != null && state.items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Failed to load staff: ${state.errorMessage}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }

                  if (state.items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No staff found'),
                      ),
                    );
                  }

                  return Column(
                    children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.items.length,
                itemBuilder: (context, index) {
                          final staff = state.items[index];
                          final isActive =
                              (staff.status).toUpperCase() == 'ACTIVE';
                          // Map classroom codes to human-readable names using cached metadata.
                          final allowedClassroomNames = staff.allowedClassroomCodes
                              .map((code) => _classroomNameByCode[code] ?? code)
                              .toList();

                          final primaryClassroomCode =
                              staff.primaryClassroomOrFirstAllowed;
                          final primaryClassroomName = primaryClassroomCode.isNotEmpty
                              ? (_classroomNameByCode[primaryClassroomCode] ??
                                  primaryClassroomCode)
                              : (allowedClassroomNames.isNotEmpty
                                  ? allowedClassroomNames.first
                                  : '');
                          final isSelected =
                              _selectedStaffCodes.contains(staff.code);
                  return Column(
                    children: [
                      StaffCard(
                                name: staff.name,
                                classroom: primaryClassroomName,
                                allowedClassrooms: allowedClassroomNames,
                                schedule: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                                designation: staff.designation,
                                email: staff.email,
                                phoneNumber: staff.phoneNumber,
                                isActive: isActive,
                                availableClassrooms: _classroomNames,
                                classroomCodeByName: _classroomNameByCode,
                                onPrimaryAction: () async {
                                  try {
                                    final message = isActive
                                        ? await staffCubit
                                            .deactivateStaff(staff.code)
                                        : await staffCubit
                                            .activateStaff(staff.code);
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
                                    final message =
                                        ApiErrorHandler.extractErrorMessage(e);
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message: message,
                                      isError: true,
                                    );
                                  }
                                },
                                isSelected: isSelected,
                                onSelected: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedStaffCodes.add(staff.code);
                                    } else {
                                      _selectedStaffCodes.remove(staff.code);
                                    }
                                    _selectAll = _selectedStaffCodes.length ==
                                            state.items.length &&
                                        state.items.isNotEmpty;
                                  });
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
                          child: Center(child: PrimaryCircularLoader()),
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
        ),
          if (anySelected)
            Positioned(
              right: 16,
              bottom: 16,
              child: StaffActionPanel(
                currentPanel: _currentPanel,
                onAttendanceTap: () {
                  setState(() {
                    _currentPanel = _currentPanel == StaffPanelType.attendance
                        ? StaffPanelType.none
                        : StaffPanelType.attendance;
                  });
                },
                onActivitiesTap: () {
                  setState(() {
                    _currentPanel = _currentPanel == StaffPanelType.activities
                        ? StaffPanelType.none
                        : StaffPanelType.activities;
                  });
                },
                onMessageTap: () {},
                onProfileTap: selectedCount == 1
                    ? () {
                        final staffState = staffCubit.state;
                        final selectedCode = _selectedStaffCodes.first;
                        final staff = staffState.items
                            .firstWhere((e) => e.code == selectedCode);
                        final allowedClassroomNames = staff.allowedClassroomCodes
                            .map((code) => _classroomNameByCode[code] ?? code)
                            .toList();
                        final primaryClassroomCode =
                            staff.primaryClassroomOrFirstAllowed;
                        final classroomName = primaryClassroomCode.isNotEmpty
                            ? (_classroomNameByCode[primaryClassroomCode] ??
                                primaryClassroomCode)
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
                                classroomNames: _classroomNames,
                                classroomNameByCode: _classroomNameByCode,
                              ),
                            ),
                          );
                      }
                    : null,
                onClearSelections: () {
                  setState(() {
                    _selectAll = false;
                    _selectedStaffCodes.clear();
                    _currentPanel = StaffPanelType.none;
                  });
                },
                isProfileEnabled: selectedCount == 1,
                activitiesEnabled: selectedCount > 0,
              ),
            ),
        ],
      ),
      showCustomNavigationBar: true,
    );
  }
}

