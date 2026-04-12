import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import 'choose_activity.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({
    super.key,
    this.fromStudentProfile = false,
    this.studentName ,
  });

  final bool fromStudentProfile;
  final Map<String, dynamic>? studentName;

  static const String routeName = '/activityFeed';

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>  with TickerProviderStateMixin{
  late TabController _tabController;
  final ScrollController _dailyScrollController = ScrollController();
  final ScrollController _customScrollController = ScrollController();
  final bool isNotParent = true; // if false than parent persona screen will be shown

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
    return GlobalScaffold(
      //hasBackButton: true,
      showCustomNavigationBar: true,
      isParent: !isNotParent,
      body: isNotParent ?
      Column(
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
              Row(
                children: [
                  GradientAddButton(
                    onTap: () {
                      if(widget.fromStudentProfile){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChooseActivity(
                              selectedStudents: widget.studentName != null
                                  ? [Map<String, dynamic>.from(widget.studentName!)]
                                  : <Map<String, dynamic>>[],
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityStudentSelection()));
                      }


                    },
                    isTablet: MediaQuery.of(context).size.width >= 600,
                    isLargeTablet: MediaQuery.of(context).size.width >= 900,
                  ),
                  SizedBox(width: 10,)
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
                ),
                ActivityCustomTab(
                  fromStudentProfile: widget.fromStudentProfile,
                  studentName: widget.studentName?['name']?.toString(),
                )

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
                ActivityDailyTab(isNotParent: isNotParent,),
                ActivityCustomTab(isNotParent: isNotParent,)

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
