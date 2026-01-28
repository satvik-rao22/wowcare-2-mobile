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
import 'package:wowcare/presentation/features/staff/view/add_staff_screen.dart';
import 'package:wowcare/shared/common/widgets/post_add_staff_bottom_sheet.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

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
  final List<bool> _selectedDemo = [false, false, false];
  bool _selectAll = false;
  StaffPanelType _currentPanel = StaffPanelType.none;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    final staffCubit = context.read<StaffCubit>();

    final bool anySelected = _selectedDemo.any((e) => e);
    final int selectedCount = _selectedDemo.where((e) => e).length;

    return GlobalScaffold(
      body: Stack(
        children: [
          CustomRefreshIndicator(
            onRefresh: () async {
              await staffCubit.refresh();
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
                        MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                      );
                      if (!mounted) return;
                      print('[StaffScreen] Received result from AddStaffScreen: ' + result.toString());
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isTablet = constraints.maxWidth >= 600;
                  // Static values for now
                  final double active = 21.0;
                  final double upcoming = 4.0;
                  final int totalCount = (active + upcoming).toInt();
                  final String total = '$totalCount';
                  final items = [
                    ProgressItemHelper(
                      label: 'Active (${active.toInt()})',
                      value: active,
                      color: AppColors.lightBlueProgressBar,
                    ),
                    ProgressItemHelper(
                      label: 'Upcoming (${upcoming.toInt()})',
                      value: upcoming,
                      color: AppColors.mustardProgressBar,
                    ),
                  ];
                  return Container(
                    margin: EdgeInsets.only(top: isTablet ? 16 : 12, bottom: isTablet ? 8 : 8),
                    child: CustomStatBarCard(
                      title: 'Total\nStaff',
                      number: total,
                      items: items,
                      fullWidthBar: false,
                    ),
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
                                // TODO: apply filters to list
                                setState(() {});
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
                      for (int i = 0; i < _selectedDemo.length; i++) {
                        _selectedDemo[i] = newVal;
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
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
                          return Column(
                            children: [
                              StaffCard(
                                name: staff.name,
                                classroom: staff.primaryClassroom,
                                allowedClassrooms: staff.classroomCodes,
                                schedule: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                                designation: staff.designation,
                                phoneNumber: staff.phoneNumber,
                                isSelected: false,
                              ),
                              if (index != state.items.length - 1)
                                const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(),
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
                        final idx = _selectedDemo.indexWhere((e) => e);
                        if (idx != -1) {
                          final demo = [
                            {
                              'name': 'Aarav Sharma',
                              'classroom': 'Nursery A',
                              'designation': 'Teacher',
                              'phone': '5551234567',
                            },
                            {
                              'name': 'Isha Verma',
                              'classroom': 'Nursery B',
                              'designation': 'Assistant Teacher',
                              'phone': '2125557890',
                            },
                            {
                              'name': 'Rahul Singh',
                              'classroom': 'Daycare',
                              'designation': 'Caretaker',
                              'phone': '4155559876',
                            },
                          ][idx];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffProfileScreen(
                                name: demo['name'] as String,
                                classroom: demo['classroom'] as String,
                                designation: demo['designation'] as String,
                                phoneNumber: demo['phone'] as String,
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                onClearSelections: () {
                  setState(() {
                    for (int i = 0; i < _selectedDemo.length; i++) {
                      _selectedDemo[i] = false;
                    }
                    _selectAll = false;
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