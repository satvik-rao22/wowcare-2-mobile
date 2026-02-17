import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_tab_cards/student_about_tab_card.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/app/di/di.dart';

import '../student_profile_tab_cards/student_family_tab_card.dart';
import '../student_profile_tab_cards/student_pickup_tab_card.dart';


class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({
    super.key,
    this.initialTabIndex = 0,
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.studentCode,
  });

  final int initialTabIndex;
  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, dynamic> sibling;
  final String? studentCode;



  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _aboutScrollController = ScrollController();
  final ScrollController _familyScrollController = ScrollController();
  final ScrollController _pickupScrollController = ScrollController();
  late Future _profileFuture;

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

    // Fetch student profile if studentCode is provided
    if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
      final dataSource = serviceLocator<StudentRemoteDataSource>();
      _profileFuture = dataSource.getStudentProfile(widget.studentCode!);
    } else {
      _profileFuture = Future.value(null);
    }
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
            child: FutureBuilder(
              future: _profileFuture,
              builder: (context, snapshot) {
                // If no studentCode provided, use existing data
                if (widget.studentCode == null || widget.studentCode!.isEmpty) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      StudentAboutTabCard(
                        scrollController: _aboutScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        tags: widget.tags,
                        schedule: widget.schedule,
                        sibling: widget.sibling,
                      ),
                      StudentFamilyTabCard(
                        scrollController: _familyScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                      ),
                      StudentPickupTabCard(
                        scrollController: _pickupScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                      ),
                    ],
                  );
                }

                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load student profile',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              final dataSource = serviceLocator<StudentRemoteDataSource>();
                              _profileFuture = dataSource.getStudentProfile(widget.studentCode!);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Success state - use API data
                final profile = snapshot.data;
                if (profile == null) {
                  // Fallback to existing data if API returns null
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      StudentAboutTabCard(
                        scrollController: _aboutScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        tags: widget.tags,
                        schedule: widget.schedule,
                        sibling: widget.sibling,
                      ),
                      StudentFamilyTabCard(
                        scrollController: _familyScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                      ),
                      StudentPickupTabCard(
                        scrollController: _pickupScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                      ),
                    ],
                  );
                }

                // Use API data - profile is StudentProfileModel
                final profileData = profile as StudentProfileModel;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    StudentAboutTabCard(
                      scrollController: _aboutScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                      tags: widget.tags,
                      schedule: widget.schedule,
                      sibling: widget.sibling,
                      studentProfile: profileData,
                    ),
                    StudentFamilyTabCard(
                      scrollController: _familyScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                    ),
                    StudentPickupTabCard(
                      scrollController: _pickupScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                    ),
                  ],
                );
              },
            ),
          ),
        ],




    );
  }
}

