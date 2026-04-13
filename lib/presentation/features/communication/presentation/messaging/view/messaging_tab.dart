import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_tab.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_or_student_selection_bulk_messaging.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';

import '../../../../../../app/theme/colors.dart';
import '../../../../../../shared/common/widgets/gradient_add_button.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isStaffTab = _tabController.index == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
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
                      : const EdgeInsets.only(left: 4),
                  splashFactory: NoSplash.splashFactory,
                  tabs: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildTab(
                        label: 'Staff Messaging',
                        color: AppColors.classroomStudentTabColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _buildTab(
                        label: 'Parent Messaging',
                        color: AppColors.classroomStaffTabColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15,),
              GradientAddButton(
                onTap: () {
                  if(isStaffTab){
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => serviceLocator<StaffCubit>()),
                        BlocProvider(create: (_) => serviceLocator<ClassroomCubit>()),
                        BlocProvider(create: (_) => serviceLocator<StudentCubit>()),
                      ],
                      child: StaffOrStudentSelectionBulkMessaging(),
                    )));
                  }else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => serviceLocator<StaffCubit>()),
                        BlocProvider(create: (_) => serviceLocator<ClassroomCubit>()),
                        BlocProvider(create: (_) => serviceLocator<StudentCubit>()),
                      ],
                      child: StaffOrStudentSelectionBulkMessaging(isStaffSelection: false,),
                    )));
                  }
                },
                //isTablet: MediaQuery.of(context).size.width >= 600,
                //isLargeTablet: MediaQuery.of(context).size.width >= 900,
              ),
              const SizedBox(width: 5,),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StaffMessagingTab(),
                StaffMessagingTab(isStaffMessaging: false,)
              ],
            ),
          ),
        ],




      ),
    );
  }
}
