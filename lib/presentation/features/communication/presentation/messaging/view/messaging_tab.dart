import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
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
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/common/widgets/gradient_add_button.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab>
    with SingleTickerProviderStateMixin {
  static const int _conversationPageSize = 50;
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
                          if (context.mounted) {
                            unawaited(
                              context
                                  .read<CommunicationCubit>()
                                  .refreshConversations(
                                    type: 'STAFF_DIRECT',
                                    size: _conversationPageSize,
                                  ),
                            );
                          }
                        } else {
                          await context.push(
                            CommunicationRoutes.recipientSelection,
                            extra: const RecipientSelectionArgs(
                              isStaffSelection: false,
                              conversationType: 'ROOM_CHAT',
                            ),
                          );
                          if (context.mounted) {
                            unawaited(
                              context
                                  .read<CommunicationCubit>()
                                  .refreshConversations(
                                    type: 'ROOM_CHAT',
                                    size: _conversationPageSize,
                                  ),
                            );
                          }
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
