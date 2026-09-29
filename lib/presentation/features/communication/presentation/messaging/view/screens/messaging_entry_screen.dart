import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/communication_providers.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/router/app_routes.dart' show DashboardRoutes;
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/communication_launcher_button.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/confirmation_dialogue_box.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/src/app_router.dart';

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
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider<UnreadBadgeCubit>.value(
        value: resolveUnreadBadgeCubit()..startWatching(),
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
          bottom: MediaQuery.viewInsetsOf(context).bottom,
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
                      AppStrings.messagingTitle,
                      style: AppTextStyles.size16.copyWith(
                        fontSize: responsive.isTablet ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  _MarkAllReadButton(isParent: isParent, isStaff: isStaff),
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
                          label: AppStrings.navStaff,
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
                                label: AppStrings.navAdmin,
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
                              label: isParent ? AppStrings.navStaff : AppStrings.navStudents,
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
                      // Routes to the Dashboard's Ratio Monitoring section
                      // (every classroom's notes badge at a glance) rather
                      // than dropping straight into one classroom's Notes
                      // tab — mirrors the Classroom Notes notification
                      // routing in NotificationRouteResolver.
                      if (!isParent) ...[
                        SizedBox(height: responsive.verticalSpacing),
                        CommunicationLauncherButton(
                          label: AppStrings.navClassroomNotes,
                          iconAsset: MediaRes.classroomIcon,
                          unreadCount: unread.unreadFor(
                            ConversationType.classroomChat,
                          ),
                          iconSize: responsive.isTablet ? 30 : 26,
                          fontSize: responsive.buttonFontSize,
                          verticalPadding: responsive.isTablet ? 26 : 22,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(
                              Uri(
                                path: DashboardRoutes.root,
                                queryParameters: const {
                                  'focus': 'ratioMonitoring',
                                },
                              ).toString(),
                            );
                          },
                        ),
                      ],
                      // Parents never filter by staff/student active status,
                      // so the notice would be meaningless noise for them.
                      if (!isParent) ...[
                        SizedBox(height: responsive.verticalSpacing),
                        const _InactiveUnreadNotice(),
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

/// Header action that clears every unread badge in one go. The sheet stays open on
/// success so the badges visibly drop to 0 as the Firestore inbox
/// listeners pick up the backend's reset — no local badge state is touched.
class _MarkAllReadButton extends StatefulWidget {
  const _MarkAllReadButton({required this.isParent, required this.isStaff});

  final bool isParent;
  final bool isStaff;

  @override
  State<_MarkAllReadButton> createState() => _MarkAllReadButtonState();
}

class _MarkAllReadButtonState extends State<_MarkAllReadButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.markAllReadConfirmTitle,
        content: AppStrings.markAllReadConfirmBody,
        confirmText: AppStrings.markAllRead,
        cancelText: 'Cancel',
        showSkipButton: true,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final result = await resolveMarkAllReadUseCase()();
    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => CoreUtils.showTopSnackBar(
        context: context,
        message: failure.message ?? AppStrings.markAllReadFailed,
        isError: true,
      ),
      (_) => CoreUtils.showTopSnackBar(
        context: context,
        message: AppStrings.markAllReadSuccess,
        isSuccess: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always shown, even at 0 unread (product decision). To hide it again
    // when nothing is unread for the current persona, restore:
    // final total = context.select<UnreadBadgeCubit, int>((c) {
    //   final s = c.state;
    //   if (widget.isParent) return s.parentTotal;
    //   if (widget.isStaff) return s.staffTotal;
    //   return s.adminTotal;
    // });
    // if (total == 0 && !_loading) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: _loading ? null : _onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.done_all, size: 18),
      label: Text(
        AppStrings.markAllRead,
        style: AppTextStyles.size16.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Info note explaining that unread badges above still count messages for
/// Students/Staff who have since been made inactive — the messaging screens
/// filter to active participants by default, so those unread threads would
/// otherwise look like they've vanished.
class _InactiveUnreadNotice extends StatelessWidget {
  const _InactiveUnreadNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.studentInfoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.studentInfoColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.messagingInactiveUnreadNotice,
              style: AppTextStyles.size16.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
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
