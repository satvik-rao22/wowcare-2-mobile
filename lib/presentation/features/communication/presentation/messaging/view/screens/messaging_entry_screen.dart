import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/communication_launcher_button.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/src/app_router.dart';

import '../../../../../../../app/theme/colors.dart';

/// Communication Launcher — opened from the message icon in [CustomAppBar].
///
/// Presented as a bottom sheet (an overlay on top of whatever screen is
/// currently showing) rather than a pushed page — picking which messaging
/// area to open is a quick, dismissible choice, not a destination in its
/// own right, so it shouldn't cost a full page transition/back-stack entry.
/// Renders the communication options the current role may access with
/// their realtime unread badges, and routes to the corresponding existing
/// module. No messaging/business logic lives here.
class MessagingEntryScreen {
  const MessagingEntryScreen._();

  /// Shows the launcher as a modal bottom sheet anchored to the bottom of
  /// [context]'s screen.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider<UnreadBadgeCubit>.value(
        value: serviceLocator<UnreadBadgeCubit>()..startWatching(),
        child: const _MessagingLauncherSheetContent(),
      ),
    );
  }
}

class _MessagingLauncherSheetContent extends StatelessWidget {
  const _MessagingLauncherSheetContent();

  @override
  Widget build(BuildContext context) {
    final roleCubit = context.watch<RoleCubit>();
    final isParent = roleCubit.isParent;
    // `RoleCubit.isAdmin` conflates staff into "admin" (role == 'admin' ||
    // role == 'staff') — use `isStaff` directly to tell a true admin/
    // director apart from staff for the Admin Chat button below, which
    // staff must NOT see (Admin: Staff, Admin, Students, Classroom Notes.
    // Staff: Staff, Students, Classroom Notes — no Admin. Parent: Admin,
    // Staff).
    final isStaff = roleCubit.isStaff;
    final responsive = ResponsiveHelper(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalSpacing,
                4,
                responsive.horizontalSpacing,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Messaging',
                      style: TextStyle(
                        fontSize: responsive.isTablet ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalSpacing,
                0,
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
                          label: 'Staff',
                          // Same chat-bubble icon as the Admin/Students
                          // buttons below, not the people/avatars icon —
                          // every launcher button uses one consistent icon.
                          iconAsset: MediaRes.chatsIcon,
                          unreadCount: unread.unreadFor(
                            ConversationType.staffDirect,
                          ),
                          iconSize: responsive.isTablet ? 30 : 26,
                          fontSize: responsive.buttonFontSize,
                          verticalPadding: responsive.isTablet ? 26 : 22,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(MessagingScreen.staffMessagingRoute);
                          },
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hidden for pure Staff — Admin Chat is
                          // admin/director + parent only.
                          if (!isStaff) ...[
                            Expanded(
                              child: CommunicationLauncherButton(
                                label: 'Admin',
                                iconAsset: MediaRes.chatsIcon,
                                unreadCount: unread.unreadFor(
                                  ConversationType.adminChat,
                                ),
                                iconSize: responsive.isTablet ? 30 : 26,
                                fontSize: responsive.labelFontSize + 2,
                                verticalPadding: responsive.isTablet ? 26 : 22,
                                horizontalPadding: 12,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push(AppRoutes.adminChat);
                                },
                              ),
                            ),
                            SizedBox(width: responsive.horizontalSpacing),
                          ],
                          Expanded(
                            child: CommunicationLauncherButton(
                              // Same Room Chat surface either way — from
                              // staff/admin's side it's a room full of
                              // students (+their guardians); from a
                              // guardian's side it's their channel to their
                              // child's staff, so it reads as "Staff" there
                              // instead of "Students".
                              label: isParent ? 'Staff' : 'Students',
                              iconAsset: MediaRes.chatsIcon,
                              unreadCount: unread.unreadFor(
                                ConversationType.roomChat,
                              ),
                              iconSize: responsive.isTablet ? 30 : 26,
                              fontSize: responsive.labelFontSize + 2,
                              verticalPadding: responsive.isTablet ? 26 : 22,
                              horizontalPadding: 12,
                              // Reuses the existing Parent Messaging sub-tab
                              // inside MessagingScreen — the same Room Chat
                              // surface the drawer's "Parent Messaging" item
                              // already opens.
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go(
                                  MessagingScreen.parentMessagingRoute,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Classroom Notes — staff-internal (each classroom's
                      // Notes chat). Gated to non-parents so it is hidden
                      // from the Guardian persona, mirroring the web.
                      // Routes to the Classrooms list (itself staff/admin
                      // only); each classroom's Notes tab is its chat.
                      if (!isParent) ...[
                        SizedBox(height: responsive.verticalSpacing),
                        CommunicationLauncherButton(
                          label: 'Classroom Notes',
                          iconAsset: MediaRes.classroomIcon,
                          unreadCount: unread.unreadFor(
                            ConversationType.classroomChat,
                          ),
                          iconSize: responsive.isTablet ? 30 : 26,
                          fontSize: responsive.buttonFontSize,
                          verticalPadding: responsive.isTablet ? 26 : 22,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(AppRoutes.classroom);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small centered drag-handle bar — the standard mobile affordance signaling
/// "this is a dismissible sheet, swipe down to close" (matches the handle
/// used by this app's other bottom sheets, e.g. PostAddStudentBottomSheet).
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
