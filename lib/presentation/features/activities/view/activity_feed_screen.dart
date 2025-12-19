import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({
    super.key,
    this.fromStudentProfile = false,
    this.studentName = '',
  });

  final bool fromStudentProfile;
  final String studentName;

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
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: isNotParent ?
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                isScrollable: true,
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.themeColor),
                ),
                indicatorPadding: const EdgeInsets.only(bottom: 8),
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.primaryColor.withOpacity(0.5),
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Custom',)
                ],
              ),
              Row(
                children: [
                  GradientAddButton(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityStudentSelection()));
                    },
                    isTablet: MediaQuery.of(context).size.width >= 600,
                    isLargeTablet: MediaQuery.of(context).size.width >= 900,
                  ),
                  SizedBox(width: 10,)
                ],
              ),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ActivityDailyTab(fromStudentProfile: widget.fromStudentProfile, studentName: widget.studentName,),
                ActivityCustomTab(fromStudentProfile: widget.fromStudentProfile, studentName: widget.studentName,)

              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      )
      : ActivityDailyTab(),
    );
  }
}
