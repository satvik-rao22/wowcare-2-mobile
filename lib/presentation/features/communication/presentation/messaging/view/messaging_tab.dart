import 'package:flutter/material.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/communication_providers.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_tab.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Tab _buildTab({required String label, required Color color}) {
    return Tab(
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffCubit>(create: (_) => resolveStaffCubit()),
        BlocProvider<StudentCubit>(
          create: (_) => resolveStudentCubit(),
        ),
        BlocProvider<ClassroomCubit>(
          create: (_) => resolveClassroomCubit(),
        ),
        BlocProvider<CommunicationCubit>(
          create: (_) => resolveCommunicationCubit(),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            // Rebuild only this header row on tab change (index-dependent
            // indicator padding + add-button target), not the whole widget.
            ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) {
                final bool isStaffTab = _tabController.index == 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: TabBar(
                        // lenght of tabs
                        // isScrollable: true, // <-- makes tabs scrollable
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
                        unselectedLabelStyle: TextTheme.of(context).titleSmall!
                            .copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.5,
                              ),
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
                    const SizedBox(width: 15),
                    GradientAddButton(
                      onTap: () async {
                        if (isStaffTab) {
                          await context.push(
                            CommunicationRoutes.recipientSelection,
                            extra: const RecipientSelectionArgs(
                              isStaffSelection: true,
                              conversationType: 'STAFF_DIRECT',
                            ),
                          );
                          // Reload through the tab that owns the filter
                          // selection rather than refetching here: this
                          // screen doesn't know which Status/Classroom/
                          // Designation filters are active, so refreshing
                          // from here replaced the filtered list with an
                          // unscoped one (active AND upcoming staff) while
                          // the filter chips still claimed otherwise.
                          MessagingEventService.instance
                              .notifyConversationListChanged('STAFF_DIRECT');
                        } else {
                          await context.push(
                            CommunicationRoutes.recipientSelection,
                            extra: const RecipientSelectionArgs(
                              isStaffSelection: false,
                              conversationType: 'ROOM_CHAT',
                            ),
                          );
                          // Same as the staff branch above — the Room Chat
                          // tab owns its own Classroom/Status/Tags filters.
                          MessagingEventService.instance
                              .notifyConversationListChanged('ROOM_CHAT');
                        }
                      },
                    ),
                    const SizedBox(width: 5),
                  ],
                );
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StaffMessagingTab(),
                  StaffMessagingTab(isStaffMessaging: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
