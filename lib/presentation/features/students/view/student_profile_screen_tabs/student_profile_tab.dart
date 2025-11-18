import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_tab_cards/student_about_tab_card.dart';
import 'package:wowcare/app/theme/colors.dart';


class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({
    super.key,
    this.initialTabIndex = 0,
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags
  });

  final int initialTabIndex;
  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;



  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _aboutScrollController = ScrollController();
  final ScrollController _familyScrollController = ScrollController();
  final ScrollController _pickupScrollController = ScrollController();


  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }




  @override
  void dispose() {
    _tabController.dispose();
    _aboutScrollController.dispose();
    _familyScrollController.dispose();
    _pickupScrollController.dispose();
    super.dispose();
  }

  Tab _buildTab({
    required String label,
    required Color color,
  }) {
    return Tab(
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Text(
            label,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Transform.translate(
            offset: const Offset(0, 4),
            child: TabBar(
              controller: _tabController,
              dividerHeight: 0,
              indicator: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border.all(
                  color: AppColors.classroomStudentTabColor
                      .withValues(alpha: 1),
                ),
              ),
              labelStyle: TextTheme.of(context).titleSmall!.copyWith(
                color: AppColors.primaryColor,
                fontSize: 15,
              ),
              unselectedLabelStyle: TextTheme.of(context)
                  .titleSmall!
                  .copyWith(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                fontSize: 15,
              ),
              labelPadding: const EdgeInsets.all(0),
              indicatorPadding: _tabController.index == 0
                  ? const EdgeInsets.only(right: 4)
                  : _tabController.index == 1
                  ? const EdgeInsets.symmetric(horizontal: 2)
                  : const EdgeInsets.only(left: 4),
              splashFactory: NoSplash.splashFactory,
              tabs: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildTab(
                    label: 'About',
                    color: AppColors.classroomStudentTabColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildTab(
                    label: 'Family',
                    color: AppColors.classroomStaffTabColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _buildTab(
                    label: 'Pickup',
                    color: AppColors.classroomNotesTabColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentAboutTabCard(
                    scrollController: _aboutScrollController,
                    name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,
                ),
                StudentAboutTabCard(
                  scrollController: _aboutScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,
                ),
                StudentAboutTabCard(
                  scrollController: _aboutScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,
                )
              ],
            ),
          ),
        ],




    );
  }
}

