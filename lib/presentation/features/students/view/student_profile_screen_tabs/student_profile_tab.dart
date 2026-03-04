import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_tab_cards/student_about_tab_card.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

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
  late Future<StudentProfileModel?> _profileFuture;

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
      _profileFuture = Future<StudentProfileModel?>.value(null);
    }
  }

  Future<void> _refreshProfile() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) return;
    final dataSource = serviceLocator<StudentRemoteDataSource>();
    // Create new future and update state to force FutureBuilder rebuild
    final newFuture = dataSource.getStudentProfile(code);
    setState(() {
      _profileFuture = newFuture;
    });
    try {
      // Wait for the future to complete to ensure data is loaded
      await newFuture;
    } catch (_) {
      // UI handles errors via FutureBuilder
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
            child: FutureBuilder<StudentProfileModel?>(
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
                        onRefresh: _refreshProfile,
                        studentCode: widget.studentCode,
                      ),
                      StudentFamilyTabCard(
                        scrollController: _familyScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        studentCode: widget.studentCode,
                        schoolCode: '', // schoolCode unknown in this path
                        onRefresh: _refreshProfile,
                      ),
                      StudentPickupTabCard(
                        scrollController: _pickupScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        studentCode: widget.studentCode,
                        onRefresh: _refreshProfile,
                      ),
                    ],
                  );
                }

                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CustomRefreshIndicator(
                    onRefresh: _refreshProfile,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: PrimaryCircularLoader()),
                      ],
                    ),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return CustomRefreshIndicator(
                    onRefresh: _refreshProfile,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshProfile,
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
                        onRefresh: _refreshProfile,
                        studentCode: widget.studentCode,
                      ),
                      StudentFamilyTabCard(
                        scrollController: _familyScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        studentCode: widget.studentCode,
                        schoolCode: '', // schoolCode unknown in this path
                        onRefresh: _refreshProfile,
                      ),
                      StudentPickupTabCard(
                        scrollController: _pickupScrollController,
                        name: widget.name,
                        classroom: widget.classroom,
                        studentCode: widget.studentCode,
                      onRefresh: _refreshProfile,
                      ),
                    ],
                  );
                }

                // Use API data - profile is StudentProfileModel
                final profileData = profile;

                // Derive tags list from profile API (tags[].name)
                final apiTags = (profileData.tags)
                    .whereType<Map<String, dynamic>>()
                    .map((t) => (t['name'] ?? '').toString().trim())
                    .where((name) => name.isNotEmpty)
                    .toList();

                // Derive schedule short-day list from regularSchedules[].dayOfWeek
                final apiSchedule = (profileData.regularSchedules)
                    .whereType<Map<String, dynamic>>()
                    .map((s) => (s['dayOfWeek'] ?? '').toString().toUpperCase())
                    .map((day) {
                      switch (day) {
                        case 'MONDAY':
                          return 'Mon';
                        case 'TUESDAY':
                          return 'Tue';
                        case 'WEDNESDAY':
                          return 'Wed';
                        case 'THURSDAY':
                          return 'Thu';
                        case 'FRIDAY':
                          return 'Fri';
                        case 'SATURDAY':
                          return 'Sat';
                        case 'SUNDAY':
                          return 'Sun';
                        default:
                          return '';
                      }
                    })
                    .where((d) => d.isNotEmpty)
                    .toList();

                // Derive sibling display map from profile API siblings[]
                final siblingNames = <String>[];
                final siblingRelations = <String>[];
                final siblingStatuses = <String>[];
                for (final raw in profileData.siblings) {
                  if (raw is! Map<String, dynamic>) continue;
                  final first = (raw['firstName'] ?? '').toString().trim();
                  final last = (raw['lastName'] ?? '').toString().trim();
                  final name = ('$first $last').trim();
                  if (name.isEmpty) continue;
                  siblingNames.add(name);
                  siblingRelations.add('Sibling');
                  final status = (raw['status'] ?? '').toString().toLowerCase();
                  siblingStatuses.add(status);
                }
                final apiSiblingMap = <String, dynamic>{
                  'name': siblingNames,
                  'relation': siblingRelations,
                  'status': siblingStatuses,
                };

                return TabBarView(
                  controller: _tabController,
                  children: [
                    StudentAboutTabCard(
                      scrollController: _aboutScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                      tags: apiTags,
                      schedule: apiSchedule,
                      sibling: apiSiblingMap,
                      studentProfile: profileData,
                      onRefresh: _refreshProfile,
                      studentCode: profileData.code,
                    ),
                    StudentFamilyTabCard(
                      scrollController: _familyScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                      studentCode: profileData.code,
                      schoolCode: profileData.schoolCode,
                      onRefresh: _refreshProfile,
                    ),
                    StudentPickupTabCard(
                      scrollController: _pickupScrollController,
                      name: profileData.fullName.isNotEmpty 
                          ? profileData.fullName 
                          : widget.name,
                      classroom: profileData.classroom ?? widget.classroom,
                      studentCode: widget.studentCode,
                      onRefresh: _refreshProfile,
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

