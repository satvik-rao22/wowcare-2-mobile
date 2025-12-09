import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

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
      body: Column(
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
                    Tab(text: 'Custom'),
                    // Billing settings can be added based on role
                  ],
                ),
               Row(
                 children: [
                   GradientAddButton(
                     onTap: () async {},
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
                ActivityDailyTab(),
                Card(
                )
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
