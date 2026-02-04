import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_tab.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../../../app/theme/colors.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key, required this.userPersona, this.initialTabIndex = 0});
  final UserPersona userPersona;
  final int initialTabIndex;

  static const String routeName = '/messageFeed';

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: !isLandscape,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.themeColor),
                ),
                indicatorPadding: const EdgeInsets.only(bottom: 8),
                labelStyle: const TextStyle(
                  color: const Color(0xFF241631),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: TextStyle(
                  //color: AppColors.primaryColor.withOpacity(0.5),
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                ),
                labelColor: const Color(0xFF241631),
                //unselectedLabelColor: AppColors.primaryColor.withOpacity(0.5),
                unselectedLabelColor: AppColors.primaryColor.withValues(alpha: 0.5),
                tabs: const [
                  Tab(text: 'Messaging',),
                  Tab(text: 'Newsletter')
                ]
            ),
            //const SizedBox(height: 16,),
            Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  MessagingTab(initialTabIndex: widget.initialTabIndex,),
                  MessagingTab(initialTabIndex: widget.initialTabIndex,)

                ]
            ),)

          ],
        )
    );
  }
}
