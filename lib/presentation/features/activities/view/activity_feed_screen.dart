import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import 'choose_activity.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.allowActivityWrite = true,
    this.highlightCode,
    this.highlightDate,
  });

  final bool fromStudentProfile;
  final Map<String, dynamic>? studentName;

  /// Activity code from a notification deep-link, forwarded to the Daily tab.
  final String? highlightCode;

  /// Date of the deep-linked activity, forwarded so the Daily tab opens on it.
  final DateTime? highlightDate;
  /// When false, hide add / edit / delete (from [DAILY_ACTIVITY] `write` permission).
  final bool allowActivityWrite;

  static const String routeName = '/activityFeed';

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>  with TickerProviderStateMixin{
  late TabController _tabController;
  final ScrollController _dailyScrollController = ScrollController();
  final ScrollController _customScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2 , vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dailyScrollController.dispose();
    _customScrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final staffLike = !role.isParent;
    final allowWrite = widget.allowActivityWrite &&
        ModuleAccess.mayWrite(role, AppAccessModules.dailyActivity);

    return GlobalScaffold(
      //hasBackButton: true,
      showCustomNavigationBar: true,
      isParent: role.isParent,
      body: staffLike
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      height: 50,
                      child: Row(
                        children: [
                          _buildTabToggleButton(
                            isSelected: _tabController.index == 0,
                            onPressed: () => _tabController.animateTo(0),
                            text: 'Daily',
                          ),
                          _buildTabToggleButton(
                            isSelected: _tabController.index == 1,
                            onPressed: () => _tabController.animateTo(1),
                            text: 'Custom',
                          ),
                        ],
                      ),
                    ),
                    if (allowWrite)
                      Row(
                        children: [
                          GradientAddButton(
                            onTap: () {
                              if (widget.fromStudentProfile) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                      name: CoreUtils.chooseActivityRouteName,
                                    ),
                                    builder: (_) => ChooseActivity(
                                      selectedStudents: widget.studentName != null
                                          ? [Map<String, dynamic>.from(widget.studentName!)]
                                          : <Map<String, dynamic>>[],
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                      name: CoreUtils
                                          .activityStudentSelectionRouteName,
                                    ),
                                    builder: (_) => ActivityStudentSelection(),
                                  ),
                                );
                              }
                            },
                            isTablet: MediaQuery.of(context).size.width >= 600,
                            isLargeTablet: MediaQuery.of(context).size.width >= 900,
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                  ],
                ),
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ActivityDailyTab(
                        fromStudentProfile: widget.fromStudentProfile,
                        studentName: widget.studentName?['name']?.toString(),
                        studentProfile: widget.fromStudentProfile
                            ? widget.studentName
                            : null,
                        isNotParent: true,
                        allowActivityWrite: allowWrite,
                        highlightCode: widget.highlightCode,
                        highlightDate: widget.highlightDate,
                      ),
                      ActivityCustomTab(
                        fromStudentProfile: widget.fromStudentProfile,
                        studentName: widget.studentName?['name']?.toString(),
                        studentProfile: widget.fromStudentProfile
                            ? widget.studentName
                            : null,
                        isNotParent: true,
                        allowActivityWrite: allowWrite,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      _buildTabToggleButton(
                        isSelected: _tabController.index == 0,
                        onPressed: () => _tabController.animateTo(0),
                        text: 'Daily',
                      ),
                      _buildTabToggleButton(
                        isSelected: _tabController.index == 1,
                        onPressed: () => _tabController.animateTo(1),
                        text: 'Custom',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ActivityDailyTab(
                        isNotParent: false,
                        allowActivityWrite: allowWrite,
                        highlightCode: widget.highlightCode,
                        highlightDate: widget.highlightDate,
                      ),
                      ActivityCustomTab(
                        isNotParent: false,
                        allowActivityWrite: allowWrite,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabToggleButton({
    required bool isSelected,
    required VoidCallback onPressed,
    required String text,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.themeColor,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.themeColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
