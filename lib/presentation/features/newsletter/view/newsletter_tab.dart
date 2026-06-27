import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/newsletter/view/sent_newsletter_tab.dart';

class NewsLatterTab extends StatefulWidget {
  const NewsLatterTab({super.key});

  @override
  State<NewsLatterTab> createState() => _NewsLatterTabState();
}

class _NewsLatterTabState extends State<NewsLatterTab>
    with SingleTickerProviderStateMixin {
  late TabController newsLetterTabController;

  @override
  void initState() {
    super.initState();
    newsLetterTabController = TabController(
      length: 1, // Only Sent tab is currently available
      vsync: this,
    );
    newsLetterTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    newsLetterTabController.dispose();
    super.dispose();
  }

  Tab _buildSingleMessagingTab({
    required String label,
    required int index,
  }) {
    return Tab(
      child: Container(
        height: 40,
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          color: newsLetterTabController.index == index
              ? AppColors.classroomStudentTabColor
              : const Color.fromARGB(102, 203, 246, 255),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border.all(
            color: newsLetterTabController.index == index
                ? AppColors.themeColor
                : Colors.transparent,
            width: 1.25,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: newsLetterTabController.index == index
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsLatterTabs() {
    final List<Widget> tabs = [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _buildSingleMessagingTab(
          label: 'Sent',
          index: 0,
        ),
      ),
    ];

    final TabBar tabBar = TabBar(
      tabs: tabs,
      controller: newsLetterTabController,
      isScrollable: true,
      labelColor: Colors.black,
      unselectedLabelColor: const Color.fromARGB(50, 36, 22, 49),
      tabAlignment: TabAlignment.center,
      indicatorColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 0),
      dividerHeight: 0,
      indicator: const BoxDecoration(),
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [tabBar],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: _buildNewsLatterTabs(),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: newsLetterTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SentNewsLetterTab(),
            ],
          ),
        ),
      ],
    );
  }
}
