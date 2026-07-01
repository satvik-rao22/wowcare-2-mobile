import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/communication_launcher_button.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/src/app_router.dart';

/// Communication Launcher — opens from the message icon in [CustomAppBar].
///
/// Presentation-only navigation screen: renders the communication options
/// the current role may access, shows their realtime unread badges, and
/// routes to the corresponding existing module. No messaging/business logic
/// lives here.
class MessagingEntryScreen extends StatelessWidget {
  const MessagingEntryScreen({super.key});

  static const String routeName = '/messaging-entry';

  @override
  Widget build(BuildContext context) {
    final isParent = context.watch<RoleCubit>().isParent;
    final responsive = ResponsiveHelper(context);

    return BlocProvider<UnreadBadgeCubit>.value(
      value: serviceLocator<UnreadBadgeCubit>()..startWatching(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onClose: () => context.pop(), responsive: responsive),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      responsive.horizontalSpacing,
                      responsive.verticalSpacing,
                      responsive.horizontalSpacing,
                      responsive.horizontalSpacing,
                    ),
                    child: BlocBuilder<UnreadBadgeCubit, UnreadBadgeState>(
                      builder: (context, unread) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isParent) ...[
                              CommunicationLauncherButton(
                                label: 'Staff Messaging',
                                iconAsset: MediaRes.staffMessaging,
                                unreadCount: unread.unreadFor(
                                  ConversationType.staffDirect,
                                ),
                                iconSize: responsive.isTablet ? 30 : 26,
                                fontSize: responsive.buttonFontSize,
                                verticalPadding: responsive.isTablet ? 26 : 22,
                                onTap: () => context.push(AppRoutes.messaging),
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CommunicationLauncherButton(
                                    label: 'Admin Chat',
                                    iconAsset: MediaRes.classroomIcon,
                                    unreadCount: unread.unreadFor(
                                      ConversationType.adminChat,
                                    ),
                                    iconSize: responsive.isTablet ? 30 : 26,
                                    fontSize: responsive.labelFontSize + 2,
                                    verticalPadding: responsive.isTablet
                                        ? 26
                                        : 22,
                                    horizontalPadding: 12,
                                    onTap: () =>
                                        context.push(AppRoutes.adminChat),
                                  ),
                                ),
                                SizedBox(width: responsive.horizontalSpacing),
                                Expanded(
                                  child: CommunicationLauncherButton(
                                    label: 'Room Chats',
                                    iconAsset: MediaRes.classroomIcon,
                                    unreadCount: unread.unreadFor(
                                      ConversationType.roomChat,
                                    ),
                                    iconSize: responsive.isTablet ? 30 : 26,
                                    fontSize: responsive.labelFontSize + 2,
                                    verticalPadding: responsive.isTablet
                                        ? 26
                                        : 22,
                                    horizontalPadding: 12,
                                    // Reuses the existing Parent Messaging
                                    // sub-tab inside MessagingScreen — the
                                    // same Room Chat surface the drawer's
                                    // "Parent Messaging" item already opens.
                                    onTap: () => context.push(
                                      MessagingScreen.parentMessagingRoute,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.responsive});

  final VoidCallback onClose;
  final ResponsiveHelper responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalSpacing,
        vertical: responsive.isTablet ? 30 : 25,
      ),
      decoration: const BoxDecoration(color: Color(0xFFF1F1FB)),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pop(), //  Back to the previous screen
            child: Container(
              padding: const EdgeInsets.all(10),

              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Text(
            'Messaging',
            style: TextStyle(
              fontSize: responsive.isTablet ? 25 : 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Manrope',
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
