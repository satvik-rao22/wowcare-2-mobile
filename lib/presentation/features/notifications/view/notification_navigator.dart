import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/src/app_router.dart';

import '../../../../core/util/active_school_switcher.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';
import '../../../../shared/common/app/cubit/parent_child_cubit.dart';
import '../../../../shared/common/app/cubit/role_cubit.dart';
import '../cubit/push_notification_cubit.dart';
import '../routing/notification_route_resolver.dart';

/// View-layer glue for push notifications.
///
/// - Kicks off [PushNotificationCubit.init] after the first frame (so the
///   listener below is already mounted when a killed-state launch tap fires).
/// - Listens for [PushNotificationState.navigationRequest] and performs the
///   actual routing, keeping the cubit free of any router dependency.
///
/// The action→destination mapping itself lives in [NotificationRouteResolver]
/// (the single dedicated redirection table). This widget is intentionally thin:
/// resolve → `appRouter.go`. To support a new notification action, edit the
/// resolver, not this file.
class NotificationNavigator extends StatefulWidget {
  const NotificationNavigator({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationNavigator> createState() => _NotificationNavigatorState();
}

class _NotificationNavigatorState extends State<NotificationNavigator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PushNotificationCubit>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PushNotificationCubit, PushNotificationState>(
      listenWhen: (prev, curr) =>
          curr.navigationRequest != null &&
          curr.navigationRequest != prev.navigationRequest,
      listener: (context, state) {
        _route(state.navigationRequest!);
        context.read<PushNotificationCubit>().clearNavigationRequest();
      },
      child: widget.child,
    );
  }

  Future<void> _route(PushNotification message) async {
    // Cheap, persona-independent check first so we don't switch school for an
    // action that has no in-app destination.
    if (NotificationRouteResolver.resolve(message) == null) {
      AppLogger.d('[FCM] No route mapped for action: ${message.action}');
      return;
    }
    // Capture the role cubit before the async gap; reading `.isParent` after the
    // switch then reflects the TARGET school's persona (the cubit instance lives
    // above this widget, so it's safe to use post-await without `context`).
    final roleCubit = context.read<RoleCubit>();
    // If the notification targets a different school the user belongs to, switch
    // the active org/school (and reset role/caches) BEFORE redirecting, so the
    // destination screen loads the notified school's data — not the current one.
    if (mounted) {
      await switchActiveSchoolIfNeeded(
        context: context,
        organizationCode: message.organizationCode,
        schoolCode: message.schoolCode,
      );
    }
    // Resolve again with the resolved persona: billing actions open the parent
    // vs admin billing screen depending on whether the current user is a
    // guardian, and newsletter/pending-approval actions deep-link straight to
    // the specific item for the admin persona. Other actions are unaffected.
    final destination = NotificationRouteResolver.resolve(
      message,
      isGuardian: roleCubit.isParent,
      isAdminPersona: roleCubit.role == 'admin',
    );
    if (destination == null) return;
    // Keep the parent persona's sibling selector (the global child dropdown)
    // in sync with whichever child this notification is about — otherwise a
    // tap on Child B's notification while Child A is selected navigates to
    // Child B's screen but leaves the dropdown (and every other screen that
    // reads ParentChildCubit) still showing Child A.
    if (mounted && roleCubit.isParent) {
      final studentCode = NotificationRouteResolver.studentCodeFor(message);
      if (studentCode != null) {
        context.read<ParentChildCubit>().selectByCode(studentCode);
      }
    }
    // URL changes (incl. the `highlightCode` query param) → go_router rebuilds
    // the branch, so the destination screen can scroll-to / flash the target.
    AppLogger.d(
      '[FCM] Routing action=${message.action} → ${destination.location}',
    );
    appRouter.go(destination.location);
  }
}
