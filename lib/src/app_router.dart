import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/tab_visibility_events.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_filter_screen.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';
import 'package:wowcare/presentation/features/activities/view/activity_student_selection.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/bathroom_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/bottle_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/incident_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/learning_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/meal_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/medication_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/nap_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/notes_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/outdoor_activity.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/photo_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/show_full_screen_media.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_feed_screen_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_filter_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_student_selection_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/choose_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/bottle_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/incident_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/medication_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/nap_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart'
    show FilterData, StaffFilterScreen;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart'
    show StaffAttendanceCardData;
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart'
    show StudentAttendanceCardData;
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/presentation/features/billing/view/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/select_students_screen.dart';
import 'package:wowcare/presentation/features/billing/view/selected_students_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/view/generate_statement_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_amount_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_authorize_screen.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/transaction_details_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/add_credit_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/send_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_settings/add_discount_screen.dart';
import 'package:wowcare/presentation/features/billing/view/billing_settings/edit_discount_screen.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/ledger_detail_screen.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/edit_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/create_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/auto_pay_token_webview.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/add_transaction_dialog.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/model/report_route_args.dart';
import 'package:wowcare/presentation/features/reports/view/annual_state_immunization_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/billing_report_form_screen.dart';
import 'package:wowcare/presentation/features/reports/view/billing_transaction_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/report_file_viewer_screen.dart';
import 'package:wowcare/presentation/features/reports/view/reports_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_absent_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_attendance_per_week_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_details_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/staff_schedule_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_absent_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_attendance_per_student_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_daily_attendance_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_emergency_contact_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_immunization_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/student_incident_report_screen.dart';
import 'package:wowcare/presentation/features/reports/view/students_and_family_report_screen.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classroom/views/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/classroom/views/screens/classroom_info_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/parent_newsletter_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/admin_chat_host_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/open_conversation_screen.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/notifications/cubit/notification_center_cubit.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_center_screen.dart';
import 'package:wowcare/presentation/features/onboarding/view/onboarding_screen.dart';
import 'package:wowcare/presentation/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_attendance_summary_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/staff/view/add_staff_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_schedule_screen.dart';
import 'package:wowcare/presentation/features/staff/model/schedule_entry.dart';
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';
import 'package:wowcare/shared/common/views/document_viewer_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/important_dates_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_schedule_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_edit_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/create_school_user_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_document_upload_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_classroom_name_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_attendance_action_targets_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_photo_upload_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/scheduling_screen.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/user_profile_screen.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/user_persona.dart';
import 'package:wowcare/presentation/features/splash/view/splash_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/splash/cubit/splash_cubit.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import 'package:wowcare/presentation/features/classroom/views/screens/classroom_overview_screen.dart';
import 'package:wowcare/presentation/features/kiosk/view/kiosk_dashboard_screen.dart';
import 'package:wowcare/presentation/features/kiosk/view/logout/kiosk_logout_page.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_sign_in_and_sign_out.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/core/storage/storage_service.dart';

/// Top-level paths. Kept identical to the old `Screen.routeName` constants so
/// existing call sites that read those constants keep working.
class AppRoutes {
  static const String splash = '/';
  static const String firstScreen = '/first-screen';
  static const String onboarding = '/onboarding';
  static const String signIn = SignInScreen.routeName;
  static const String signOut = SignOutScreen.routeName;
  static const String forgotPassword = ForgotPasswordScreen.routeName;
  static const String orgSelection = '/org-selection';
  static const String schoolSelection = '/school-selection';

  static const String dashboard = DashboardScreen.routeName;
  static const String classroom = ClassroomScreen.routeName;
  static const String activityFeed = ActivityFeedScreen.routeName;
  static const String messaging = MessagingScreen.routeName;
  static const String adminChat = AdminChatHostScreen.routeName;
  static const String openConversation = OpenConversationScreen.routeName;
  static const String parentBilling = ParentBillingScreen.routeName;

  // Notification deep-links for the admin persona: land straight on the
  // specific newsletter / pending-approval activity, not a generic list.
  static const String newsletterPreviewByCode = '/newsletter-preview-by-code';
  static const String activityApprovalByCode = '/activity-approval-by-code';
}

/// Path lookups by branch index — used by the bottom nav when there is no
/// shell in scope (e.g. an auth screen) and for routing fallbacks.
const List<String> branchRootPaths = <String>[
  AppRoutes.dashboard, // 0
  AppRoutes.classroom, // 1
  AppRoutes.activityFeed, // 2
  AppRoutes.messaging, // 3
  AppRoutes.parentBilling, // 4
];

/// Map a bottom-nav [BottomNavigationItem] → shell branch index. `null` means
/// the item is not a branch (Attendance is a modal popup, not a route).
int? branchIndexForItem({
  required bool isParent,
  required BottomNavigationItem item,
}) {
  if (isParent) {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return 0;
      case BottomNavigationItem.attendance:
        return null; // Attendance popup
      case BottomNavigationItem.activities:
        return 2;
      case BottomNavigationItem.communication:
        return 3;
      case BottomNavigationItem.billing:
        return 4;
      case BottomNavigationItem.classrooms:
        return null; // Not a parent tab
    }
  } else {
    switch (item) {
      case BottomNavigationItem.dashboard:
        return 0;
      case BottomNavigationItem.attendance:
        return null; // Attendance popup
      case BottomNavigationItem.classrooms:
        return 1;
      case BottomNavigationItem.activities:
        return 2;
      case BottomNavigationItem.communication:
        return 3;
      case BottomNavigationItem.billing:
        return null; // Not a staff/admin tab
    }
  }
}

/// Reverse of [branchIndexForItem] for highlighting the active tab when the
/// user navigates programmatically or via a deep link.
BottomNavigationItem itemForBranchIndex({
  required bool isParent,
  required int branchIndex,
}) {
  if (isParent) {
    switch (branchIndex) {
      case 2:
        return BottomNavigationItem.activities;
      case 3:
        return BottomNavigationItem.communication;
      case 4:
        return BottomNavigationItem.billing;
      default:
        return BottomNavigationItem.dashboard;
    }
  } else {
    switch (branchIndex) {
      case 1:
        return BottomNavigationItem.classrooms;
      case 2:
        return BottomNavigationItem.activities;
      case 3:
        return BottomNavigationItem.communication;
      default:
        return BottomNavigationItem.dashboard;
    }
  }
}

/// Stable navigator keys for each shell branch.
///
/// These MUST be declared outside [appRouter] so they survive router rebuilds
/// (hot reload, GoRouter.refresh, etc.). Re-creating them inside the [routes]
/// list on every build gives each branch a new GlobalKey, which confuses
/// Flutter's element lifecycle and triggers the
/// "_elements.contains(element)" assertion.
/// Public (not `_`-prefixed like its sibling branch keys) because the
/// Attendance popup (a modal, not a route) must push the parent's
/// attendance profile onto THIS specific navigator, regardless of which
/// branch's own `CustomNavigationBar` instance happened to handle the tap —
/// see `AttendancePopupManager.openParentChildAttendance`'s doc for why an
/// ambient `BuildContext` can't be trusted for this.
/// Public (not `_`-prefixed) for the same reason as [dashboardBranchKey]:
/// any branch can end up with a screen imperatively pushed onto its OWN
/// nested navigator (a sub-screen, a dialog-as-route, the Attendance
/// profile), which go_router's own `context.go` doesn't know how to pop —
/// see [popAllShellBranchNavigators]'s doc for the concrete bug this fixes
/// (e.g. "Switch Profile" not landing on Dashboard because the Attendance
/// profile, or a Communication-module sub-screen, was still covering it).
final dashboardBranchKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final classroomBranchKey = GlobalKey<NavigatorState>(debugLabel: 'classroom');
final activityBranchKey = GlobalKey<NavigatorState>(debugLabel: 'activity');
final messagingBranchKey = GlobalKey<NavigatorState>(debugLabel: 'messaging');
final billingBranchKey = GlobalKey<NavigatorState>(debugLabel: 'billing');

/// Every shell branch's own nested navigator, for callers that need to
/// unwind ALL of them (not just one specific branch) — see
/// [popAllShellBranchNavigators].
final List<GlobalKey<NavigatorState>> _allShellBranchKeys = [
  dashboardBranchKey,
  classroomBranchKey,
  activityBranchKey,
  messagingBranchKey,
  billingBranchKey,
];

/// Pops every pushed route off EVERY shell branch's own nested navigator,
/// plus the app's root navigator, back down to each branch's root screen.
///
/// Needed before a plain `context.go(someRoute)` whenever the caller can't
/// be sure nothing is imperatively pushed on top of whichever navigator is
/// currently showing — `go()` only ever changes go_router's OWN declarative
/// page list; it has no way to know about (or pop) a route pushed directly
/// via `NavigatorState.push`/`Navigator.of(context).push` bypassing
/// go_router, so that pushed screen just keeps covering the destination.
/// Two concrete cases this fixes, both hit via the app bar's "Switch
/// Profile": the parent Attendance profile (pushed onto
/// [dashboardBranchKey] — see `AttendancePopupManager
/// .openParentChildAttendance`) and Communication-module sub-screens
/// (pushed onto [messagingBranchKey] from within `MessagingScreen`/
/// `ParentMessagingThread`/etc.). Safe to call unconditionally — a branch
/// with nothing pushed on it just no-ops (`canPop()` is false).
void popAllShellBranchNavigators(BuildContext context) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  while (rootNavigator.canPop()) {
    rootNavigator.pop();
  }
  for (final key in _allShellBranchKeys) {
    final navigator = key.currentState;
    while (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// Deep-link captured from a notification that cold-launched the app (killed
/// state). On a killed-state tap the app starts at the splash, which runs an
/// auth check and then navigates to the dashboard — clobbering the deep-link if
/// we `go()` immediately. So [PushNotificationCubit] stashes the destination
/// here (from `getInitialMessage()`) and the splash routes to it instead of the
/// dashboard. Read-once via [consumePendingNotificationDeepLink].
String? pendingNotificationDeepLink;

String? consumePendingNotificationDeepLink() {
  final value = pendingNotificationDeepLink;
  pendingNotificationDeepLink = null;
  return value;
}

/// Org/school of the killed-state notification (when it targets a school other
/// than the last-used one). Captured alongside [pendingNotificationDeepLink] in
/// main() and consumed by the splash, which switches the active school before
/// routing to the deep-link. `{organizationCode, schoolCode}` or null.
Map<String, String>? pendingNotificationOrgSchool;

Map<String, String>? consumePendingNotificationOrgSchool() {
  final value = pendingNotificationOrgSchool;
  pendingNotificationOrgSchool = null;
  return value;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: CoreUtils.rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    // Log navigation events for debugging
    debugPrint(
      '[GoRouter] Navigating to: ${state.uri.path} (name: ${state.name})',
    );

    // CRITICAL SECURITY: Check if user is in kiosk mode and block non-kiosk routes
    // Use synchronous cache check to avoid race conditions from multiple redirect() calls
    bool isKioskMode = KioskAccessControl.isKioskModeActiveDirect();

    // Fallback: If cache is empty, try async storage check (app startup cold load)
    if (!isKioskMode) {
      try {
        isKioskMode = await serviceLocator<KioskAccessControl>()
            .isKioskModeActive();
      } catch (e) {
        // If KioskAccessControl is not registered, try to create it on demand
        try {
          AppLogger.w(
            '[KioskAccess] KioskAccessControl not in DI, creating on demand',
          );
          final kioskAccess = KioskAccessControl(
            serviceLocator<StorageService>(),
          );
          isKioskMode = await kioskAccess.isKioskModeActive();
        } catch (e2) {
          AppLogger.e('[KioskAccess] Error checking kiosk mode: $e2');
        }
      }
    }

    if (isKioskMode) {
      final currentRoute = state.uri.path;
      final allowed = KioskAccessControl.isRouteAllowedForKiosk(currentRoute);

      AppLogger.d(
        '[KioskAccess] Route check: path=$currentRoute, allowed=$allowed',
      );

      // Allow kiosk routes only
      if (!allowed) {
        AppLogger.d(
          '[KioskAccess] Blocking access to $currentRoute - kiosk user, redirecting to /kiosk',
        );
        return '/kiosk';
      }
    }

    // Billing is persona-split: the admin billing screen has no data for a
    // guardian. Anything that lands a guardian on /dashboard/billing — most
    // notably a notification deep-link resolved before the persona was known
    // (the killed-state launch path bakes its location in `main()`, long before
    // login/school-switch settle the role) — is rewritten to the parent billing
    // screen. Query params (e.g. `highlightCode`) are preserved so the target
    // invoice still flashes.
    if (state.uri.path == BillingScreen.routeName) {
      try {
        if (context.read<RoleCubit>().isParent) {
          final q = state.uri.queryParameters;
          AppLogger.d(
            '[Billing] Guardian on ${state.uri} → redirecting to parent billing',
          );
          return Uri(
            path: AppRoutes.parentBilling,
            queryParameters: q.isEmpty ? null : q,
          ).toString();
        }
      } catch (_) {
        // RoleCubit not reachable/resolved yet — leave routing untouched.
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      // RoleCubit/ParentChildCubit/AuthCubit are read from the ANCESTOR
      // BlocProviders (app_providers.dart/app_bloc_providers.dart) rather
      // than resolved via serviceLocator — SplashCubit needs to act on the
      // SAME instances the rest of the app observes (e.g. it calls
      // RoleCubit.refreshAccessFromServer so the dashboard sees the
      // refreshed state), not a throwaway factory instance.
      builder: (context, state) => BlocProvider(
        create: (context) => SplashCubit(
          storage: serviceLocator<StorageService>(),
          authLocal: serviceLocator<AuthLocalDataSource>(),
          authRemote: serviceLocator<AuthRemoteDataSource>(),
          kioskAccessControl: serviceLocator<KioskAccessControl>(),
          registerDeviceFcmTokenUseCase:
              serviceLocator<RegisterDeviceFcmTokenUseCase>(),
          roleCubit: context.read<RoleCubit>(),
          parentChildCubit: context.read<ParentChildCubit>(),
          authCubit: context.read<AuthCubit>(),
        )..resolve(),
        child: const SplashScreenWrapper(),
      ),
    ),
    GoRoute(
      path: AppRoutes.firstScreen,
      builder: (context, state) => BlocProvider(
        create: (_) => serviceLocator<OnboardingCubit>(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => BlocProvider(
        create: (_) => serviceLocator<OnboardingCubit>(),
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.signOut,
      builder: (context, state) => const SignOutScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.orgSelection,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final isSwitchFlow = args?['isSwitchFlow'] as bool? ?? false;
        return OrganizationSelectionScreen(isSwitchFlow: isSwitchFlow);
      },
    ),
    GoRoute(
      path: AppRoutes.schoolSelection,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? const {};
        final rawSchools = args['schoolsForOrg'];
        return SchoolSelectionScreen(
          selectedOrg: args['selectedOrg'] as String? ?? '',
          isSwitchFlow: args['isSwitchFlow'] as bool? ?? false,
          schoolsForOrg: rawSchools is List
              ? rawSchools
                    .whereType<Map>()
                    .map(
                      (m) => m.map(
                        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                      ),
                    )
                    .toList()
              : null,
          orgFromLoginContext: args['orgFromLoginContext'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: ClassroomOverviewScreen.routeName,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        final filter = args?['filter'] as String?;
        return ClassroomOverviewScreen(initialStudentFilter: filter);
      },
    ),
    // Notification center (bell-icon inbox). Top-level so it can be pushed as
    // an overlay from any screen's app bar, preserving the back stack. Uses
    // `_fastPage` so the page's route name is the matched location
    // (`/notifications`) — the app bar reads that to avoid pushing a duplicate.
    GoRoute(
      path: NotificationCenterScreen.routeName,
      pageBuilder: (context, state) => _fastPage(
        state,
        // This screen renders outside the nav shell with a plain Scaffold.
        // UnreadBadgeCubit is now provided at the app root (main.dart) so it
        // is always in scope — no per-route instance needed here.
        BlocProvider<NotificationCenterCubit>(
          create: (_) =>
              serviceLocator<NotificationCenterCubit>()..loadInitial(),
          child: const NotificationCenterScreen(),
        ),
      ),
    ),

    // Kiosk dashboard — full-screen tablet UI for school entrance kiosk.
    // Top-level route (outside StatefulShellRoute) so it bypasses the nav shell.
    // REFACTORED: Cubits provided at app root level in main.dart
    // Problem: GoRouter's nested route builders receive context from NavigatorWidget.
    // Solution: Provide cubits at app root (main.dart) instead of route level.
    //           All screens (including nested routes) now have access to shared cubits.
    GoRoute(
      path: KioskDashboardScreen.routeName,
      builder: (context, state) {
        AppLogger.d('[Kiosk] Building kiosk dashboard');
        return const KioskDashboardScreen();
      },
      routes: [
        // Kiosk staff sign-in/out screen (pure kiosk flow)
        // Uses KioskStaffSignScreenV2 which is built specifically for kiosk
        // Does NOT call resolveStaffCodeForLoggedInUser() - uses staffCode from PIN verification

        // Student attendance routes
        GoRoute(
          path: 'student-sign-in',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-in screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final pinValue = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Router received pin=$pinValue (type=${extra['pin'].runtimeType})',
            );
            return StudentSelectionSignInForm(
              allowedStudentCodes: (extra['students'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList(),
              isKiosk: extra['isKiosk'] as bool? ?? false,
              guardianCode: extra['guardianCode'] as String?,
              pin: pinValue,
            );
          },
        ),
        GoRoute(
          path: 'student-sign-out',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-out screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return StudentSelectionSignOutForm(
              allowedStudentCodes: (extra['students'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList(),
              isKiosk: extra['isKiosk'] as bool? ?? false,
              guardianCode: extra['guardianCode'] as String?,
              pin: extra['pin'] as String?,
            );
          },
        ),
        GoRoute(
          path: 'student-sign-in-out',
          builder: (context, state) {
            AppLogger.d('[Kiosk] Building student-sign-in-out screen');
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final signedInCodes =
                (extra['signedInStudents'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList() ??
                [];
            final signedOutCodes =
                (extra['signedOutStudents'] as List?)
                    ?.map((s) => (s as Map)['studentCode'] as String)
                    .toList() ??
                [];
            final guardianCode = extra['guardianCode'] as String?;
            final pin = extra['pin'] as String?;
            return StudentSignInOutSelectionScreen(
              signedInCodes: signedInCodes,
              signedOutCodes: signedOutCodes,
              guardianCode: guardianCode,
              pin: pin,
            );
          },
        ),

        // UNIFIED KIOSK SIGN-IN/SIGN-OUT PAGE
        // Consolidates student selection, sign-in, and sign-out flows
        // Stays within /kiosk context (no navigation to /dashboard)
        GoRoute(
          path: 'student-sign-in-and-sign-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final signedInCodes =
                (extra['signedInCodes'] as List?)?.cast<String>() ?? [];
            final signedOutCodes =
                (extra['signedOutCodes'] as List?)?.cast<String>() ?? [];
            final guardianCode = extra['guardianCode'] as String?;
            final pin = extra['pin'] as String?;
            final action = extra['action'] as String? ?? 'selection';

            AppLogger.d(
              '[Kiosk] Routing to unified student-sign-in-and-sign-out: '
              'action=$action, signedIn=${signedInCodes.length}, '
              'signedOut=${signedOutCodes.length}',
            );

            return _fastPage(
              state,
              KioskStudentSignInAndSignOutPage(
                signedInCodes: signedInCodes,
                signedOutCodes: signedOutCodes,
                guardianCode: guardianCode ?? '',
                pin: pin ?? '',
                action: action,
              ),
            );
          },
        ),
        // KIOSK STAFF SIGN-IN FORM
        GoRoute(
          path: 'staff-sign-in',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isKiosk = extra['isKiosk'] as bool? ?? false;
            final staffCode = extra['staffCode'] as String?;
            final staffName = extra['staffName'] as String?;
            final pin = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Routing to staff-sign-in: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
            );
            return _fastPage(
              state,
              StaffSignInForm(
                isKiosk: isKiosk,
                staffCode: staffCode,
                staffName: staffName,
                pin: pin,
              ),
            );
          },
        ),
        // KIOSK STAFF SIGN-OUT FORM
        GoRoute(
          path: 'staff-sign-out',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isKiosk = extra['isKiosk'] as bool? ?? false;
            final staffCode = extra['staffCode'] as String?;
            final staffName = extra['staffName'] as String?;
            final pin = extra['pin'] as String?;
            AppLogger.d(
              '[Kiosk] Routing to staff-sign-out: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
            );
            return _fastPage(
              state,
              StaffSignOutForm(
                isKiosk: isKiosk,
                staffCode: staffCode,
                staffName: staffName,
                pin: pin,
              ),
            );
          },
        ),

        // Kiosk logout confirmation page
        GoRoute(
          path: 'logout',
          pageBuilder: (context, state) {
            AppLogger.d('[Kiosk] Building logout page');
            return _fastPage(state, const KioskLogoutPage());
          },
        ),
      ],
    ),

    // Top-level staff attendance forms (accessible from kiosk context)
    GoRoute(
      path: '/dashboard/staff-sign-in-form',
      pageBuilder: (context, state) {
        final isGps = state.uri.queryParameters['gps'] == '1';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final isKiosk = extra['isKiosk'] as bool? ?? false;
        final staffCode = extra['staffCode'] as String?;
        final staffName = extra['staffName'] as String?;
        final pin = extra['pin'] as String?;
        AppLogger.d(
          '[Router] StaffSignInForm: isKiosk=$isKiosk, staffCode=$staffCode, staffName=$staffName, pin=${pin?.isNotEmpty ?? false}',
        );
        return _fastPage(
          state,
          StaffSignInForm(
            forceSelf: isGps,
            isKiosk: isKiosk,
            staffCode: staffCode,
            staffName: staffName,
            pin: pin,
          ),
        );
      },
    ),
    GoRoute(
      path: '/dashboard/staff-sign-out-form',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final isKiosk = extra['isKiosk'] as bool? ?? false;
        final staffCode = extra['staffCode'] as String?;
        final staffName = extra['staffName'] as String?;
        final pin = extra['pin'] as String?;
        return _fastPage(
          state,
          StaffSignOutForm(
            isKiosk: isKiosk,
            staffCode: staffCode,
            staffName: staffName,
            pin: pin,
          ),
        );
      },
    ),
    GoRoute(
      path: '/attendance/staff-sign-in',
      pageBuilder: (context, state) {
        final e = state.extra as Map<String, dynamic>? ?? const {};
        return _fastPage(
          state,
          StaffSignInForm(
            staff: e['staff'] as StaffEntity?,
            staffList: (e['staffList'] as List?)?.cast<StaffEntity>(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/attendance/staff-sign-out',
      pageBuilder: (context, state) {
        final e = state.extra as Map<String, dynamic>? ?? const {};
        return _fastPage(
          state,
          StaffSignOutForm(
            staff: e['staff'] as StaffEntity?,
            staffList: (e['staffList'] as List?)?.cast<StaffEntity>(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/attendance/staff-transfer',
      pageBuilder: (context, state) {
        final e = state.extra as Map<String, dynamic>? ?? const {};
        return _fastPage(
          state,
          StaffTransferForm(
            staff: e['staff'] as StaffEntity?,
            staffList: (e['staffList'] as List?)?.cast<StaffEntity>(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/attendance/staff-mark-absent',
      pageBuilder: (context, state) {
        final e = state.extra as Map<String, dynamic>? ?? const {};
        return _fastPage(
          state,
          StaffMarkAbsentForm(
            staff: e['staff'] as StaffEntity?,
            staffList: (e['staffList'] as List?)?.cast<StaffEntity>(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/attendance/staff-selection-sign-in',
      pageBuilder: (context, state) =>
          _fastPage(state, const StaffSelectionSignInForm()),
    ),
    GoRoute(
      path: '/attendance/staff-selection-sign-out',
      pageBuilder: (context, state) =>
          _fastPage(state, const StaffSelectionSignOutForm()),
    ),
    GoRoute(
      path: '/attendance/staff-selection-transfer',
      pageBuilder: (context, state) =>
          _fastPage(state, const StaffSelectionTransferForm()),
    ),
    GoRoute(
      path: '/attendance/staff-selection-mark-absent',
      pageBuilder: (context, state) =>
          _fastPage(state, const StaffSelectionMarkAbsentForm()),
    ),
    GoRoute(
      path: '/attendance/student-selection-sign-in',
      pageBuilder: (context, state) =>
          _fastPage(state, const StudentSelectionSignInForm()),
    ),
    GoRoute(
      path: '/attendance/student-selection-sign-out',
      pageBuilder: (context, state) =>
          _fastPage(state, const StudentSelectionSignOutForm()),
    ),
    GoRoute(
      path: '/attendance/student-selection-transfer',
      pageBuilder: (context, state) =>
          _fastPage(state, const StudentSelectionTransferForm()),
    ),
    GoRoute(
      path: '/attendance/student-selection-mark-absent',
      pageBuilder: (context, state) =>
          _fastPage(state, const StudentSelectionMarkAbsentForm()),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Expose the shell to descendants. CustomNavigationBar reads it and
        // switches tabs via goBranch — preserving each branch's widget tree
        // and navigation stack instead of rebuilding screens on every tap.
        //
        // _ShellScopeContent is a plain StatelessWidget that renders
        // navigationShell as its child. Wrapping it here (rather than passing
        // navigationShell directly as the InheritedWidget's child) gives the
        // InheritedElement a stable element type to update, avoiding the
        // "_elements.contains(element)" assertion that occurs when a
        // LayoutBuilder inside the shell subtree triggers a layout-phase
        // rebuild and both go_router and _ShellScope try to operate on the
        // same StatefulNavigationShell element in the same frame.
        // System back (Android gesture/button) should behave like the in-app
        // back button, never abruptly close the app from a non-home tab.
        // go_router pops any nested route within the active branch first; only a
        // branch *root* reaches this PopScope. From the dashboard (branch 0)
        // root we let the app exit as usual; from any other tab's root we return
        // to the dashboard instead of closing the app.
        return PopScope(
          canPop: navigationShell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            navigationShell.goBranch(0);
          },
          child: _ShellScope(
            shell: navigationShell,
            child: _ShellScopeContent(navigationShell: navigationShell),
          ),
        );
      },
      branches: [
        // Branch 0 — Dashboard with every non-tab destination nested
        // underneath it. Because they're children of /dashboard, calling
        // `context.go('/dashboard/staff')` from `/dashboard/students` REPLACES
        // /students with /staff while keeping /dashboard underneath — the
        // stack stays [Dashboard, drill-down] no matter how many drawer items
        // the user taps in a row. Back from any drill-down always lands on
        // Dashboard. (Sub-drill-downs that need to stack on top of a parent
        // drill-down — e.g. Staff → Edit Profile — still use
        // `context.push(...)` and live as siblings here.)
        StatefulShellBranch(
          navigatorKey: dashboardBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'staff',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<StaffCubit>(
                          create: (_) =>
                              serviceLocator<StaffCubit>()..loadInitial(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                        BlocProvider<StaffProfileCubit>(
                          create: (_) => serviceLocator<StaffProfileCubit>(),
                        ),
                        BlocProvider<StaffAttendanceSummaryCubit>(
                          create: (_) =>
                              serviceLocator<StaffAttendanceSummaryCubit>(),
                        ),
                        // Each StaffCard reads the school's open days from
                        // this; they share one instance and one request.
                        BlocProvider<StaffScheduleCubit>(
                          create: (_) => serviceLocator<StaffScheduleCubit>(),
                        ),
                        BlocProvider<StaffAttendanceActionTargetsCubit>(
                          create: (_) =>
                              serviceLocator<
                                StaffAttendanceActionTargetsCubit
                              >(),
                        ),
                      ],
                      child: StaffScreen(
                        incomingHighlightCode:
                            state.uri.queryParameters['highlightCode'],
                        // Staff Attendance Daily's "Active"/"Upcoming" legend
                        // cards used to Navigator.push a second, ad-hoc copy
                        // of this exact screen+provider combination — an
                        // imperative push that bypassed go_router entirely,
                        // leaving its own idea of "current location" stale
                        // and breaking subsequent context.go()/drawer
                        // navigation. They now push THIS route instead (see
                        // _openStaffListWithIncomingFilter), passing the
                        // filter via `extra` since it has no query-string
                        // equivalent here.
                        incomingStatusFilter:
                            (state.extra as StaffListArgs?)?.statusFilter,
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'students',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classrooms = args?['classrooms'] as List<String>?;
                    // Notification deep-link: highlight + scroll to a student.
                    final highlightCode =
                        state.uri.queryParameters['highlightCode'];
                    // Only Student Attendance Daily's "Active"/"Upcoming" push
                    // (see _openStudentListWithIncomingFilter) sets this —
                    // every other caller keeps the plain loadActiveClassrooms()
                    // this route already used, unchanged.
                    final applyAttendanceStaffScope =
                        args?['applyAttendanceStaffScope'] as bool? ?? false;
                    return _fastPage(
                      state,
                      MultiBlocProvider(
                        providers: [
                          BlocProvider<StudentCubit>(
                            create: (_) =>
                                serviceLocator<StudentCubit>()..loadInitial(),
                          ),
                          BlocProvider<ClassroomCubit>(
                            create: (_) => serviceLocator<ClassroomCubit>()
                              ..loadActiveClassrooms(
                                applyAttendanceStaffScope:
                                    applyAttendanceStaffScope,
                              ),
                          ),
                        ],
                        child: StudentScreen(
                          incomingStatusFilter: filter,
                          incomingClassroomSelections: classrooms,
                          incomingHighlightCode: highlightCode,
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'billing',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const BillingScreen()),
                ),
                GoRoute(
                  path: 'parent-newsletter',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    BlocProvider<StudentNewslettersCubit>(
                      create: (_) => serviceLocator<StudentNewslettersCubit>(),
                      child: const ParentNewsletterScreen(),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'reports',
                  // The hub's four cubits are created here rather than inside
                  // ReportsScreen.build (§5). §5.4: this pageBuilder re-runs
                  // whenever a child form route is pushed or popped, but the
                  // page keeps the same `state.pageKey`, so the Navigator
                  // reuses the existing element and `create:` — and therefore
                  // each `..load*()` — still fires exactly once per entry to
                  // /dashboard/reports, including on back navigation from a
                  // form. Same counts as when this block lived in build().
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(
                              force: true,
                              onlyTypeClassroom: true,
                            ),
                        ),
                        BlocProvider<StudentCubit>(
                          create: (_) =>
                              serviceLocator<StudentCubit>()..loadInitial(),
                        ),
                        BlocProvider<StaffCubit>(
                          create: (_) =>
                              serviceLocator<StaffCubit>()..loadInitial(),
                        ),
                        BlocProvider<ReportsCubit>(
                          create: (_) =>
                              serviceLocator<ReportsCubit>()..loadTags(),
                        ),
                      ],
                      child: const ReportsScreen(),
                    ),
                  ),
                  // The report form screens. Registered as children so they
                  // are pushed on the dashboard branch navigator, exactly
                  // where the plain `Navigator.push` they replaced put them —
                  // and, crucially, so the kiosk redirect above can finally
                  // see them. A kiosk-locked device could previously reach
                  // the Students & Family report (guardian names, addresses,
                  // phone numbers) because the Navigator opened it without
                  // the router ever being consulted.
                  //
                  // `builder:` rather than `_fastPage` on purpose: it yields
                  // the platform's default page transition, which is what
                  // MaterialPageRoute gave these screens before.
                  //
                  // Every builder wraps its screen in a
                  // `BlocProvider<ReportsCubit>.value` over the hub's own
                  // instance, carried in on the typed args. §5.4: there is no
                  // `..load()` in any of these builders, so back navigation
                  // re-runs nothing — the forms take their filter lists from
                  // the args and read the name→code maps off the hub's cubit,
                  // which is already populated.
                  routes: [
                    // ── Student ──────────────────────────────────────────
                    GoRoute(
                      path: ReportRoutes.studentDailyAttendanceSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentDailyAttendanceReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentAbsentSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentAbsentReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentAttendancePerStudentSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentAttendancePerStudentReportScreen(
                            students: args.students ?? const <String>[],
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentsAndFamilySegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentsAndFamilyReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                            tags: args.tags ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentImmunizationSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentImmunizationReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                            tags: args.tags ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentEmergencyContactSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentEmergencyContactReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.studentIncidentSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StudentIncidentReportScreen(
                            students: args.students ?? const <String>[],
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),

                    // ── Staff ────────────────────────────────────────────
                    GoRoute(
                      path: ReportRoutes.staffAttendancePerWeekSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StaffAttendancePerWeekReportScreen(
                            staff: args.staff ?? const <String>[],
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.staffDetailsSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StaffDirectoryReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.staffAbsentSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StaffAbsentReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: ReportRoutes.staffScheduleSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: StaffScheduleReportScreen(
                            classrooms: args.classrooms ?? const <String>[],
                          ),
                        );
                      },
                    ),

                    // ── Compliance ───────────────────────────────────────
                    GoRoute(
                      path: ReportRoutes
                          .complianceAnnualStateImmunizationSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: const AnnualStateImmunizationReportScreen(),
                        );
                      },
                    ),

                    // ── Billing ──────────────────────────────────────────
                    GoRoute(
                      path: ReportRoutes.billingTransactionSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: const BillingTransactionReportScreen(),
                        );
                      },
                    ),
                    // One screen, five report types — the variant comes from
                    // `BillingReportFormArgs.reportType`, as it did when the
                    // hub constructed the widget directly.
                    GoRoute(
                      path: ReportRoutes.billingFormSegment,
                      builder: (context, state) {
                        final args = state.extra! as BillingReportFormArgs;
                        return BlocProvider<ReportsCubit>.value(
                          value: args.cubit,
                          child: BillingReportFormScreen(
                            reportType: args.reportType,
                            title: args.title,
                            classrooms: args.classrooms ?? const <String>[],
                            students: args.students ?? const <String>[],
                          ),
                        );
                      },
                    ),

                    // ── In-app file viewer ───────────────────────────────
                    // Nested here, not at the router root like the billing
                    // copy, so the nav shell stays visible — matching the
                    // branch-navigator push this replaced.
                    GoRoute(
                      path: ReportRoutes.fileViewerSegment,
                      builder: (context, state) {
                        final args = state.extra! as ReportFileViewerArgs;
                        return ReportFileViewerScreen(
                          fileData: args.fileData,
                          fileName: args.fileName,
                          fileType: args.fileType,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'scheduling',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        // No-pagination staff fetch for the scheduling
                        // feature (status=ACTIVE&status=UPCOMING). Singleton
                        // so AddShift shares the same cached list.
                        BlocProvider<SchedulingStaffListCubit>.value(
                          value: serviceLocator<SchedulingStaffListCubit>()
                            ..load(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                      ],
                      child: SchedulingScreen(
                        // `highlightCode` may be a shiftCode (shift deep-link) or
                        // a classroomCode (SHIFT_UNDER_RATIO) — pass to both;
                        // only the matching card flashes. `view=day` forces the
                        // day view; `date=yyyy-MM-dd` jumps to the block's day.
                        highlightShiftCode:
                            state.uri.queryParameters['highlightCode'],
                        highlightClassroomCode:
                            state.uri.queryParameters['highlightCode'],
                        initialDate: _parseYmd(
                          state.uri.queryParameters['date'],
                        ),
                        forceDayView:
                            state.uri.queryParameters['view'] == 'day',
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'staff-scheduling',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    MultiBlocProvider(
                      providers: [
                        // Singleton scheduling staff list (no pagination).
                        // Provided here so AddShift can read it from context
                        // without triggering another API call.
                        BlocProvider<SchedulingStaffListCubit>.value(
                          value: serviceLocator<SchedulingStaffListCubit>(),
                        ),
                        // `.value` because the cubit is a lazy singleton —
                        // we don't want BlocProvider to close it when the
                        // route is popped. `loadIfNeeded()` runs the visible
                        // load on first entry and a silent background
                        // refresh on subsequent entries (no shimmer flash).
                        BlocProvider<StaffSchedulingCubit>.value(
                          value: serviceLocator<StaffSchedulingCubit>()
                            ..loadIfNeeded(),
                        ),
                        BlocProvider<ClassroomCubit>(
                          create: (_) => serviceLocator<ClassroomCubit>()
                            ..loadActiveClassrooms(onlyTypeClassroom: false),
                        ),
                      ],
                      child: StaffSchedulingScreen(
                        // Shift deep-links (PUBLISH/UPCOMING/EDIT/DELETE_SHIFT):
                        // jump to the shift's day, select its staff, and flash
                        // the shift block (`highlightCode` = shiftCode).
                        initialDate: _parseYmd(
                          state.uri.queryParameters['date'],
                        ),
                        initialStaffCode:
                            state.uri.queryParameters['staffCode'],
                        highlightShiftCode:
                            state.uri.queryParameters['highlightCode'],
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'future-availability',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const FutureAvailabilityScreen()),
                ),
                GoRoute(
                  path: 'individual-movement',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    IndividualMovementScreen(
                      highlightCode: state.uri.queryParameters['highlightCode'],
                      studentCode: state.uri.queryParameters['studentCode'],
                    ),
                  ),
                ),
                GoRoute(
                  path: StaffRoutes.editImportantDatesSegment,
                  pageBuilder: (context, state) {
                    final args = state.extra as EditImportantDatesArgs?;
                    return _fastPage(
                      state,
                      BlocProvider<ImportantDatesCubit>(
                        create: (_) => serviceLocator<ImportantDatesCubit>(),
                        child: EditImportantDatesScreen(
                          staffCode: args?.staffCode ?? '',
                          initialHireDate: args?.initialHireDate,
                          initialCdaExaminationDate:
                              args?.initialCdaExaminationDate,
                          initialFirstAidCprExpirationDate:
                              args?.initialFirstAidCprExpirationDate,
                          initialBackgroundRecordCheckExpirationDate:
                              args?.initialBackgroundRecordCheckExpirationDate,
                          initialPhysicalCheckupDate:
                              args?.initialPhysicalCheckupDate,
                          initialPhysicalCheckupStatus:
                              args?.initialPhysicalCheckupStatus,
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: StaffRoutes.editProfileDetailsSegment,
                  pageBuilder: (context, state) =>
                      _fastPage(state, _editProfileDetailsScreen(state.extra)),
                ),
                GoRoute(
                  path: StaffRoutes.addSegment,
                  pageBuilder: (context, state) =>
                      _fastPage(state, _addStaffScreen(state.extra)),
                ),
                GoRoute(
                  path: StaffRoutes.filterSegment,
                  pageBuilder: (context, state) {
                    final args = state.extra as StaffFilterArgs?;
                    return _fastPage(
                      state,
                      BlocProvider<ClassroomCubit>(
                        create: (_) => serviceLocator<ClassroomCubit>(),
                        child: StaffFilterScreen(
                          initialFilters: args?.initialFilters,
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: StaffRoutes.documentFormSegment,
                  pageBuilder: (context, state) =>
                      _fastPage(state, _addDocumentScreen(state.extra)),
                ),
                GoRoute(
                  path: StaffRoutes.editScheduleSegment,
                  pageBuilder: (context, state) {
                    final args = state.extra as EditStaffScheduleArgs?;
                    return _fastPage(
                      state,
                      BlocProvider<StaffScheduleCubit>(
                        create: (_) => serviceLocator<StaffScheduleCubit>(),
                        child: EditScheduleScreen(
                          staffCode: args?.staffCode ?? '',
                          initialSchedules:
                              args?.initialSchedules ??
                              const <ScheduleEntry>[],
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-attendance-tabbed-view',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classroomFilter =
                        args?['classroomFilter'] as FilterData?;
                    final initialTabIndex =
                        (args?['initialTabIndex'] as int?) ?? 0;
                    final hasBackButton =
                        args?['hasBackButton'] as bool? ?? false;
                    return _fastPage(
                      state,
                      StudentAttendanceTabbedView(
                        dailyIncomingFilter: filter,
                        classroomFilter: classroomFilter,
                        initialTabIndex: initialTabIndex,
                        highlightCode:
                            state.uri.queryParameters['highlightCode'],
                        hasBackButton: hasBackButton,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-attendance-tabbed-view',
                  pageBuilder: (context, state) {
                    final args = state.extra as Map<String, dynamic>?;
                    final filter = args?['filter'] as String?;
                    final classroomFilter =
                        args?['classroomFilter'] as FilterData?;
                    final initialTabIndex =
                        (args?['initialTabIndex'] as int?) ?? 0;
                    final hasBackButton =
                        args?['hasBackButton'] as bool? ?? false;
                    return _fastPage(
                      state,
                      StaffAttendanceTabbedView(
                        dailyIncomingFilter: filter,
                        classroomFilter: classroomFilter,
                        initialTabIndex: initialTabIndex,
                        hasBackButton: hasBackButton,
                      ),
                    );
                  },
                ),
                // Notification deep-link: open the Classroom Info screen with a
                // classroom pre-selected by code (e.g. RATIO_BREACHED).
                GoRoute(
                  path: 'classroom-info-screen',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    ClassroomInfoScreen(
                      initialClassroomCode:
                          state.uri.queryParameters['classroomCode'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'userProfile',
                  pageBuilder: (context, state) {
                    final args =
                        state.extra as Map<String, dynamic>? ?? const {};
                    return _fastPage(
                      state,
                      UserProfileScreen(
                        userName: args['userName'] as String? ?? '',
                        userEmail: args['userEmail'] as String? ?? '',
                        userPersona: args['userPersona'] as String? ?? '',
                        staffCode: args['staffCode'] as String?,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'notificationSettings',
                  pageBuilder: (context, state) =>
                      _fastPage(state, const NotificationSettingsScreen()),
                ),
                GoRoute(
                  path: 'student-profile',
                  pageBuilder: (context, state) =>
                      _fastPage(state, _studentProfileScreen(state.extra)),
                ),
                // Notification deep-link: open a student's profile from just a
                // code. The tabs self-load by studentCode, so header fields can
                // start empty and fill in once the profile loads.
                GoRoute(
                  path: 'student-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      BlocProvider<ClassroomCubit>(
                        create: (_) =>
                            serviceLocator<ClassroomCubit>()
                              ..loadActiveClassrooms(),
                        child: StudentProfileScreen(
                          studentCode: q['code'],
                          name: '',
                          classroom: '',
                          tags: const <String>[],
                          schedule: const <String>[],
                          sibling: const <String, dynamic>{
                            'name': <dynamic>[],
                            'relation': <dynamic>[],
                            'status': <dynamic>[],
                          },
                          initialTabIndex: int.tryParse(q['tab'] ?? '') ?? 0,
                          initialProfileSubTabIndex:
                              int.tryParse(q['profileTab'] ?? '') ?? 0,
                          initialHealthSubTabIndex:
                              int.tryParse(q['healthTab'] ?? '') ?? 0,
                          highlightCode: q['highlightCode'],
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: StaffRoutes.profileSegment,
                  pageBuilder: (context, state) =>
                      _fastPage(state, _staffProfileScreen(state.extra)),
                ),
                // Notification deep-link: open a staff profile from just a code.
                GoRoute(
                  path: StaffRoutes.profileByCodeSegment,
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    final staffCode = q['code'] ?? '';
                    return _fastPage(
                      state,
                      _staffProfileScope(
                        staffCode: staffCode,
                        child: StaffProfileScreen(
                          staffCode: staffCode,
                          name: '',
                          classroom: '',
                          designation: '',
                          phoneNumber: '',
                          initialTabIndex: int.tryParse(q['tab'] ?? '') ?? 0,
                          highlightCode: q['highlightCode'],
                        ),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-attendance-profile',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _studentAttendanceProfileScreen(state.extra),
                  ),
                ),
                GoRoute(
                  path: 'staff-attendance-profile',
                  pageBuilder: (context, state) => _fastPage(
                    state,
                    _staffAttendanceProfileScreen(state.extra),
                  ),
                ),
                // Notification deep-link: open a student's attendance profile
                // from just a code (e.g. ATTENDANCE_NOT_MARKED). The screen
                // self-loads its data by studentCode.
                GoRoute(
                  path: 'student-attendance-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      StudentAttendanceProfile(
                        studentCode: q['code'] ?? '',
                        studentId: 0,
                        studentName: q['name'] ?? '',
                        roomName: '—',
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'staff-attendance-profile-by-code',
                  pageBuilder: (context, state) {
                    final q = state.uri.queryParameters;
                    return _fastPage(
                      state,
                      StaffAttendanceProfile(
                        staffCode: q['code'] ?? '',
                        staffId: 0,
                        staffName: q['name'] ?? '-',
                        roomName: '-',
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-selection-sign-in-form',
                  pageBuilder: (context, state) {
                    final code =
                        state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed =
                        extra?['allowedStudentCodes'] as List<String>?;
                    final isKiosk = extra?['isKiosk'] as bool? ?? false;
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSelectionSignInForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                        isKiosk: isKiosk,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-selection-sign-out-form',
                  pageBuilder: (context, state) {
                    final code =
                        state.uri.queryParameters['studentCode']?.trim() ?? '';
                    final extra = state.extra as Map<String, dynamic>?;
                    final allowed =
                        extra?['allowedStudentCodes'] as List<String>?;
                    final isKiosk = extra?['isKiosk'] as bool? ?? false;
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSelectionSignOutForm(
                        preSelectedStudentCode: code.isNotEmpty ? code : null,
                        allowedStudentCodes: allowed,
                        isKiosk: isKiosk,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-sign-in-out-selection',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final signedInCodes =
                        extra?['signedInCodes'] as List<String>? ?? [];
                    final signedOutCodes =
                        extra?['signedOutCodes'] as List<String>? ?? [];
                    final guardianCode = extra?['guardianCode'] as String?;
                    final pin = extra?['pin'] as String?;
                    final isQrScan = extra?['isQrScan'] as bool? ?? false;
                    final qrToken = extra?['qrToken'] as String? ?? '';
                    return _fastPage(
                      state,
                      StudentSignInOutSelectionScreen(
                        signedInCodes: signedInCodes,
                        signedOutCodes: signedOutCodes,
                        guardianCode: guardianCode,
                        pin: pin,
                        isQrScan: isQrScan,
                        qrToken: qrToken,
                      ),
                    );
                  },
                ),
                // Edit-attendance forms (in-shell). The pushed form pops with a
                // bool on success, but every caller refreshes on return
                // regardless of the value, so context.push's ignored result is
                // behaviour-preserving. The row model + date ride in `extra`.
                GoRoute(
                  path: 'staff-edit-attendance-form',
                  pageBuilder: (context, state) {
                    final e = state.extra as Map<String, dynamic>? ?? const {};
                    return _fastPage(
                      state,
                      StaffEditAttendanceForm(
                        staffAttendance:
                            e['staffAttendance'] as StaffAttendanceCardData,
                        attendanceDate: e['attendanceDate'] as DateTime,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'student-edit-attendance-form',
                  pageBuilder: (context, state) {
                    final e = state.extra as Map<String, dynamic>? ?? const {};
                    return _fastPage(
                      state,
                      StudentEditAttendanceForm(
                        studentAttendance:
                            e['studentAttendance'] as StudentAttendanceCardData,
                        attendanceDate: e['attendanceDate'] as DateTime,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 1 — Classrooms (staff/admin only).
        StatefulShellBranch(
          navigatorKey: classroomBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.classroom,
              builder: (context, state) => ClassroomScreen(
                initialClassroomCode:
                    state.uri.queryParameters['classroomCode'],
                // Assign-to-classroom notifications highlight a row inside a
                // specific tab (0 students, 1 staff, 2 notes).
                initialTabIndex:
                    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
                initialHighlightCode:
                    state.uri.queryParameters['highlightCode'],
              ),
            ),
          ],
        ),

        // Branch 2 — Activities.
        StatefulShellBranch(
          navigatorKey: activityBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.activityFeed,
              builder: (context, state) {
                final q = state.uri.queryParameters;
                final highlight = (q['highlightCode'] ?? '').trim();
                final date = q['date'] ?? '';
                final room = q['classroomCode'] ?? '';
                final extra = state.extra as Map<String, dynamic>?;
                return BlocProvider<ActivityFeedScreenCubit>(
                  create: (_) => serviceLocator<ActivityFeedScreenCubit>(),
                  child: ActivityFeedScreen(
                  // The Activities tab lives in an indexed-stack branch and its
                  // Daily tab is keep-alive, so a notification tap into an
                  // already-visited tab reuses the old State — leaving the feed
                  // on the previously selected DAY/room. Keying a deep-link by
                  // its target forces a remount, so initState re-runs and
                  // applies the notification's date, classroom and highlight.
                  // Normal tab navigation carries no highlightCode and keeps a
                  // null key, so ordinary browsing state is preserved.
                  key: highlight.isNotEmpty
                      ? ValueKey('activityFeed-$highlight-$date-$room')
                      : null,
                  highlightCode: q['highlightCode'],
                  highlightDate: DateTime.tryParse(date),
                  // The deep-linked activity's classroom, so the feed opens on
                  // the room that actually contains the card to highlight.
                  highlightClassroomCode: q['classroomCode'],
                  initialTab: q['tab'] == 'custom' ? 1 : 0,
                  initialActivityTypes: q['activityType'] != null
                      ? [q['activityType']!]
                      : null,
                  initialClassrooms: q['classroom'] != null
                      ? [q['classroom']!]
                      : null,
                  resetKey: extra?['timestamp']?.toString(),
                  ),
                );
              },
            ),
          ],
        ),

        // Branch 3 — Messaging. Persona is derived from RoleCubit so the
        // same branch serves both parent and staff/admin without having to
        // pass arguments through the URL.
        StatefulShellBranch(
          navigatorKey: messagingBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.messaging,
              builder: (context, state) {
                final isParent = context.read<RoleCubit>().isParent;
                final tab = state.uri.queryParameters['tab']
                    ?.trim()
                    .toLowerCase();
                final initialTabIndex = tab == 'newsletter' ? 1 : 0;
                return MessagingScreen(
                  userPersona: isParent
                      ? UserPersona.parent
                      : UserPersona.admin,
                  initialTabIndex: initialTabIndex,
                );
              },
            ),
          ],
        ),

        // Branch 4 — Parent billing (parent only).
        StatefulShellBranch(
          navigatorKey: billingBranchKey,
          routes: [
            GoRoute(
              path: AppRoutes.parentBilling,
              builder: (context, state) => BlocProvider(
                create: (_) => serviceLocator<ParentBillingCubit>(),
                // Billing notification deep-link: the invoice's card is revealed
                // (page window grown), scrolled to and flashed.
                child: ParentBillingScreen(
                  highlightCode: state.uri.queryParameters['highlightCode'],
                ),
              ),
            ),
          ],
        ),
      ],
    ),

    // Overlay screens pushed over the shell via context.push. Placing them
    // outside StatefulShellRoute means the root navigator owns the page —
    // no bottom nav bar is shown, and there is no duplicate-GlobalKey risk
    // from having multiple sibling roots inside the same ShellBranch.
    GoRoute(
      path: AppRoutes.adminChat,
      builder: (context, state) => const AdminChatHostScreen(),
    ),
    // Deep-link target for a tapped chat push notification: fetches the
    // conversation by code and shows the correct thread.
    GoRoute(
      path: AppRoutes.openConversation,
      builder: (context, state) => OpenConversationScreen(
        conversationCode: state.uri.queryParameters['conversationCode'] ?? '',
        conversationType: state.uri.queryParameters['conversationType'],
      ),
    ),
    // Notification deep-link (admin persona, NEWSLETTER_SENT): open the
    // specific newsletter's preview screen. Self-loads by code.
    GoRoute(
      path: AppRoutes.newsletterPreviewByCode,
      pageBuilder: (context, state) => _fastPage(
        state,
        PreviewNewsletterScreen(
          newsletterCode: state.uri.queryParameters['code'] ?? '',
        ),
      ),
    ),
    // Notification deep-link (admin persona, INCIDENT_APPROVAL_PENDING /
    // INCIDENT_ACKNOWLEDGEMENT_PENDING): open that specific incident directly
    // in the admin approve/reject view. Only `activityCode` is real here — the
    // rest of the placeholder is overwritten once the screen self-loads full
    // detail via GET /api/v2/activities/{code} (same prefetch every edit-mode
    // open already relies on).
    GoRoute(
      path: AppRoutes.activityApprovalByCode,
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return _fastPage(
          state,
          MultiBlocProvider(
            providers: [
              BlocProvider<ActivityEditorCubit>(
                create: (_) => serviceLocator<ActivityEditorCubit>(),
              ),
              BlocProvider<IncidentActivityCubit>(
                create: (_) => serviceLocator<IncidentActivityCubit>(),
              ),
            ],
            child: IncidentActivityScreen(
              isEdit: true,
              activityData: ActivityItem(
                time: '',
                date: '',
                name: '',
                studentList: const <String>[],
                createdBy: '',
                activityCode: q['code'],
                studentCode: q['studentCode'],
              ),
            ),
          ),
        );
      },
    ),

    // ── Activity overlay routes (Mandate 1: GoRouter everywhere) ─────────────
    // Same pattern as the billing drill-down screens above: pushed via
    // `context.push` over the shell, args read from `state.extra` cast to the
    // matching typed class from activity_route_args.dart.
    GoRoute(
      path: ActivityFilterScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityFilterArgs;
        return BlocProvider<ActivityFilterCubit>(
          create: (_) => serviceLocator<ActivityFilterCubit>()
            ..loadMetadata(schoolCode: args.schoolCode),
          child: ActivityFilterScreen(
            schoolCode: args.schoolCode,
            classroomCode: args.classroomCode,
            initialFilters: args.initialFilters,
          ),
        );
      },
    ),
    GoRoute(
      path: ShowFullScreenMedia.routeName,
      builder: (context, state) {
        final args = state.extra! as ShowFullScreenMediaArgs;
        return ShowFullScreenMedia(
          activity: args.activity,
          photoUrl: args.photoUrl,
          videoUrl: args.videoUrl,
        );
      },
    ),
    GoRoute(
      path: FullscreenLocalVideoPlayerPage.routeName,
      builder: (context, state) {
        final args = state.extra! as FullscreenLocalVideoArgs;
        return FullscreenLocalVideoPlayerPage(videoFile: args.videoFile);
      },
    ),

    // The `name:` on these two matches the value CoreUtils.exitActivityFlow
    // already compared route.settings.name against under the old
    // Navigator.push(MaterialPageRoute(settings: RouteSettings(name: ...)))
    // pattern. go_router builds each page's RouteSettings.name from
    // `state.name ?? state.path`, so declaring `name:` here reproduces that
    // exact matching after the move to GoRouter — exitActivityFlow itself
    // needs no changes.
    GoRoute(
      // `ChooseActivity.routeName` ('chooseActivity') is a bare
      // RouteSettings.name tag (used by exitActivityFlow's popUntil match),
      // not a URL path — a top-level GoRoute path must start with '/'.
      // context.push(ChooseActivity.routeName) resolves to '/chooseActivity'
      // internally, so the registered path must match that exactly.
      path: '/${ChooseActivity.routeName}',
      name: CoreUtils.chooseActivityRouteName,
      builder: (context, state) {
        final args = state.extra! as ChooseActivityArgs;
        return BlocProvider<ChooseActivityCubit>(
          create: (_) => serviceLocator<ChooseActivityCubit>()
            ..loadActivitySettings(
              classroomCode: classroomCodeFromSelectedStudents(
                args.selectedStudents,
              ),
            ),
          child: ChooseActivity(selectedStudents: args.selectedStudents),
        );
      },
    ),
    GoRoute(
      // Same fix as ChooseActivity's route above: `.routeName` is a bare
      // RouteSettings.name tag, not a URL path — must be '/'-prefixed here.
      path: '/${ActivityStudentSelection.routeName}',
      name: CoreUtils.activityStudentSelectionRouteName,
      builder: (context, state) => BlocProvider<ActivityStudentSelectionCubit>(
        create: (_) => serviceLocator<ActivityStudentSelectionCubit>(),
        child: const ActivityStudentSelection(),
      ),
    ),
    // The following ten routes wrap each screen's cubit(s) in a BlocProvider
    // here — the only place `serviceLocator<T>()` appears on this path
    // (Mandate 5). Each screen's own `build()` used to do this wrapping
    // itself via `BlocProvider(create: (_) => serviceLocator<X>())`; moved
    // here now that every push into these screens goes through this router.
    GoRoute(
      path: NapActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return MultiBlocProvider(
          providers: [
            BlocProvider<ActivityEditorCubit>(
              create: (_) => serviceLocator<ActivityEditorCubit>(),
            ),
            BlocProvider<NapActivityCubit>(
              create: (_) => serviceLocator<NapActivityCubit>(),
            ),
          ],
          child: NapActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: BathroomActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: BathroomActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: BottleActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<BottleActivityCubit>(
          create: (_) => serviceLocator<BottleActivityCubit>()
            ..init(
              isEdit: args.isEdit,
              readOnly: args.readOnly,
              activityData: args.activityData,
              selectedStudents: args.selectedStudents,
            ),
          child: BottleActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: MealActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: MealActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: IncidentActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return MultiBlocProvider(
          providers: [
            BlocProvider<ActivityEditorCubit>(
              create: (_) => serviceLocator<ActivityEditorCubit>(),
            ),
            BlocProvider<IncidentActivityCubit>(
              create: (_) => serviceLocator<IncidentActivityCubit>(),
            ),
          ],
          child: IncidentActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: MedicationActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<MedicationActivityCubit>(
          create: (_) => serviceLocator<MedicationActivityCubit>()
            ..init(
              isEdit: args.isEdit,
              readOnly: args.readOnly,
              activityData: args.activityData,
              selectedStudents: args.selectedStudents,
            ),
          child: MedicationActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: NotesActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: NotesActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: OutdoorActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: OutdoorActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: LearningActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ActivityTypeScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: LearningActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),
    GoRoute(
      path: PhotoVideoActivityScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as PhotoVideoActivityScreenArgs;
        return BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
          child: PhotoVideoActivityScreen(
            selectedStudents: args.selectedStudents,
            isEdit: args.isEdit,
            isPhoto: args.isPhoto,
            activityData: args.activityData,
            readOnly: args.readOnly,
          ),
        );
      },
    ),

    // ── Billing drill-down screens (Mandate 1: GoRouter everywhere) ──────────
    // Every billing screen that used to be pushed via MaterialPageRoute is
    // registered here as a root-level overlay route (same pattern as the
    // /attendance/* selection forms above): pushed via `context.push` over the
    // shell, each reads its arguments from `state.extra` cast to the matching
    // typed args class from billing_route_args.dart. Return values propagate
    // back to the awaiting `context.push` when the screen pops (context.pop /
    // Navigator.pop both complete the go_router push future).
    GoRoute(
      path: CreateInvoiceScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as CreateInvoiceArgs;
        return CreateInvoiceScreen(
          selectedStudents: args.selectedStudents,
          initialInvoiceData: args.initialInvoiceData,
        );
      },
    ),
    GoRoute(
      path: SelectStudentsScreen.routeName,
      builder: (context, state) {
        final args = state.extra as SelectStudentsArgs?;
        return SelectStudentsScreen(
          invoiceData: args?.invoiceData,
          onNext: args?.onNext,
        );
      },
    ),
    GoRoute(
      path: SelectedStudentsReceiptScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as SelectedStudentsReceiptArgs;
        return SelectedStudentsReceiptScreen(
          selectedStudents: args.selectedStudents,
          invoiceData: args.invoiceData,
          onStudentRemoved: args.onStudentRemoved,
          isConfirmation: args.isConfirmation,
          onSubmit: args.onSubmit,
        );
      },
    ),
    GoRoute(
      path: TransactionDetailsScreen.routeName,
      builder: (context, state) {
        final args = state.extra as TransactionDetailsArgs?;
        return TransactionDetailsScreen(
          transaction: args?.transaction,
          ownerType: args?.ownerType,
          ownerCode: args?.ownerCode,
          familyName: args?.familyName,
        );
      },
    ),
    GoRoute(
      path: ReceivePaymentIssueRefundScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ReceivePaymentRefundArgs;
        return ReceivePaymentIssueRefundScreen(
          transaction: args.transaction,
          isRefund: args.isRefund,
          studentCode: args.studentCode,
          ownerType: args.ownerType,
          ownerCode: args.ownerCode,
        );
      },
    ),
    GoRoute(
      path: AddCreditScreen.routeName,
      builder: (context, state) {
        final args = state.extra as AddCreditArgs?;
        return AddCreditScreen(
          ownerType: args?.ownerType,
          ownerCode: args?.ownerCode,
          studentCode: args?.studentCode,
          familyName: args?.familyName,
        );
      },
    ),
    GoRoute(
      path: GenerateStatementScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as GenerateStatementArgs;
        return GenerateStatementScreen(
          cubit: args.cubit,
          subscriberCode: args.subscriberCode,
          ownerType: args.ownerType,
          familyChildren: args.familyChildren,
        );
      },
    ),
    GoRoute(
      path: ViewInvoiceScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ViewInvoiceArgs;
        return ViewInvoiceScreen(transaction: args.transaction);
      },
    ),
    GoRoute(
      path: ViewReceiptScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as ViewReceiptArgs;
        return ViewReceiptScreen(
          transaction: args.transaction,
          viewType: args.viewType,
        );
      },
    ),
    GoRoute(
      path: SendInvoiceScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as SendInvoiceArgs;
        return SendInvoiceScreen(transaction: args.transaction);
      },
    ),
    GoRoute(
      path: PayNowAmountScreen.routeName,
      builder: (context, state) => const PayNowAmountScreen(),
    ),
    GoRoute(
      path: PayNowAuthorizeScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as PayNowAuthorizeArgs;
        return PayNowAuthorizeScreen(
          method: args.method,
          amount: args.amount,
          charges: args.charges,
          settings: args.settings,
        );
      },
    ),
    GoRoute(
      path: AutoPayPaymentMethodsScreen.routeName,
      builder: (context, state) {
        final args = state.extra as AutoPayPaymentMethodsArgs?;
        return AutoPayPaymentMethodsScreen(isPicker: args?.isPicker ?? false);
      },
    ),
    GoRoute(
      // Preserves the original `fullscreenDialog: true` presentation.
      path: AutoPayTokenWebView.routeName,
      pageBuilder: (context, state) {
        final args = state.extra! as AutoPayTokenWebViewArgs;
        return MaterialPage<dynamic>(
          key: state.pageKey,
          name: state.matchedLocation,
          fullscreenDialog: true,
          child: AutoPayTokenWebView(payload: args.payload),
        );
      },
    ),
    GoRoute(
      path: AddDiscountScreen.routeName,
      builder: (context, state) => const AddDiscountScreen(),
    ),
    GoRoute(
      path: EditDiscountScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as EditDiscountArgs;
        return EditDiscountScreen(discount: args.discount);
      },
    ),
    GoRoute(
      path: LedgerDetailScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as LedgerDetailArgs;
        return LedgerDetailScreen(ledger: args.ledger);
      },
    ),
    GoRoute(
      path: EditLedgerScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as EditLedgerArgs;
        return EditLedgerScreen(ledger: args.ledger);
      },
    ),
    GoRoute(
      path: CreateLedgerScreen.routeName,
      builder: (context, state) => const CreateLedgerScreen(),
    ),
    GoRoute(
      path: AddTransactionScreen.routeName,
      builder: (context, state) {
        final args = state.extra! as AddTransactionArgs;
        return AddTransactionScreen(
          ledgerCode: args.ledgerCode,
          onSave: args.onSave,
        );
      },
    ),
    GoRoute(
      path: StaffRoutes.documentViewer,
      builder: (context, state) {
        final args = state.extra! as DocumentViewerArgs;
        return DocumentViewerScreen(
          url: args.url,
          documentName: args.documentName,
          mimeType: args.mimeType,
        );
      },
    ),
    GoRoute(
      path: ReportRoutes.billingFileViewer,
      builder: (context, state) {
        final args = state.extra! as ReportFileViewerArgs;
        return ReportFileViewerScreen(
          fileData: args.fileData,
          fileName: args.fileName,
          fileType: args.fileType,
        );
      },
    ),
  ],
);

/// Builds the edit-staff-profile route, with the cubits it needs created here
/// rather than inside the screen — §1.6: the `GoRoute` builder is the only
/// place `serviceLocator` may appear on the presentation side.
Widget _editProfileDetailsScreen(Object? extra) {
  final args = extra as EditStaffProfileArgs?;
  return MultiBlocProvider(
    providers: [
      BlocProvider<StaffProfileEditCubit>(
        create: (_) => serviceLocator<StaffProfileEditCubit>(),
      ),
      BlocProvider<ClassroomCubit>(
        create: (_) => serviceLocator<ClassroomCubit>(),
      ),
    ],
    child: EditProfileDetailsScreen(
      staffCode: args?.staffCode ?? '',
      initialFirstName: args?.initialFirstName,
      initialLastName: args?.initialLastName,
      initialEmail: args?.initialEmail,
      initialStatus: args?.initialStatus,
      initialDesignation: args?.initialDesignation,
      initialAllowedClassrooms: args?.initialAllowedClassrooms,
      initialPrimaryClassroom: args?.initialPrimaryClassroom,
      initialPhoneNumber: args?.initialPhoneNumber,
      initialBirthDate: args?.initialBirthDate,
      initialJobTag: args?.initialJobTag,
      initialStreet: args?.initialStreet,
      initialCity: args?.initialCity,
      initialState: args?.initialState,
      initialCountry: args?.initialCountry,
      initialZipCode: args?.initialZipCode,
      initialClassroomNames: args?.initialClassroomNames,
      initialClassroomCodeByName: args?.initialClassroomCodeByName,
    ),
  );
}

Widget _addStaffScreen(Object? extra) {
  final args = extra as AddStaffArgs?;
  return MultiBlocProvider(
    providers: [
      BlocProvider<CreateSchoolUserCubit>(
        create: (_) => serviceLocator<CreateSchoolUserCubit>(),
      ),
      BlocProvider<ClassroomCubit>(
        create: (_) => serviceLocator<ClassroomCubit>(),
      ),
    ],
    child: AddStaffScreen(
      isEdit: args?.isEdit ?? false,
      initialFirstName: args?.initialFirstName,
      initialLastName: args?.initialLastName,
      initialEmail: args?.initialEmail,
      initialPhone: args?.initialPhone,
      initialRole: args?.initialRole,
      initialAllowedClassroomCodes: args?.initialAllowedClassroomCodes,
      initialPrimaryClassroom: args?.initialPrimaryClassroom,
      initialStatus: args?.initialStatus,
      initialClassroomNames: args?.initialClassroomNames,
      initialClassroomCodeByName: args?.initialClassroomCodeByName,
    ),
  );
}

Widget _addDocumentScreen(Object? extra) {
  final args = extra as StaffDocumentFormArgs?;
  return MultiBlocProvider(
    providers: [
      BlocProvider<StaffProfileCubit>(
        create: (_) => serviceLocator<StaffProfileCubit>(),
      ),
      BlocProvider<StaffDocumentCubit>(
        create: (_) => serviceLocator<StaffDocumentCubit>(),
      ),
      BlocProvider<StaffDocumentUploadCubit>(
        // Depends on the StaffProfileCubit above, so it reads it from the
        // provider context rather than resolving a second instance.
        create: (context) => serviceLocator<StaffDocumentUploadCubit>(
          param1: context.read<StaffProfileCubit>(),
        ),
      ),
    ],
    child: AddDocumentScreen(
      staffCode: args?.staffCode ?? '',
      isEdit: args?.isEdit ?? false,
      documentUuid: args?.documentUuid,
      initialDocumentName: args?.initialDocumentName,
      initialDocumentType: args?.initialDocumentType,
      initialExpiryDate: args?.initialExpiryDate,
      initialFilePath: args?.initialFilePath,
      initialMimeType: args?.initialMimeType,
      initialFileSizeKb: args?.initialFileSizeKb,
      initialDocumentNotes: args?.initialDocumentNotes,
      initialAssetCode: args?.initialAssetCode,
    ),
  );
}

Widget _studentProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StudentProfileScreen(
    name: args['name'] as String? ?? '',
    classroom: args['classroom'] as String? ?? '',
    tags: args['tags'] ?? const <String, dynamic>{},
    schedule: args['schedule'] ?? const <String, dynamic>{},
    sibling:
        args['sibling'] ??
        const <String, dynamic>{
          'name': <dynamic>[],
          'relation': <dynamic>[],
          'status': <dynamic>[],
        },
    studentCode: args['studentCode'] as String?,
    syncWithParentChildSelection:
        args['syncWithParentChildSelection'] as bool? ?? false,
  );
}

/// The cubits the staff-profile screen and its three tabs need.
///
/// Created here — the `GoRoute` builder is the only place `serviceLocator` may
/// appear on the presentation side (§1.6). The profile screen and its Profile
/// tab previously each provided their own [StaffProfileCubit]; they now share
/// one, which is safe because the screen only calls the cubit's stateless
/// `fetchProfile` pass-through and never reads its state.
///
/// `create` stays lazy, so a cubit (and its `..loadInitial`) is still only
/// built when a tab that reads it is first shown — the same timing as the
/// per-tab providers this replaces.
Widget _staffProfileScope({required String staffCode, required Widget child}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<StaffProfileCubit>(
        create: (_) => serviceLocator<StaffProfileCubit>()
          ..loadInitial(staffCode),
      ),
      BlocProvider<StaffProfilePhotoUploadCubit>(
        create: (_) => serviceLocator<StaffProfilePhotoUploadCubit>(),
      ),
      BlocProvider<StaffScheduleCubit>(
        create: (_) => serviceLocator<StaffScheduleCubit>(),
      ),
      BlocProvider<ImportantDatesCubit>(
        create: (_) => serviceLocator<ImportantDatesCubit>(),
      ),
      BlocProvider<StaffDocumentsListCubit>(
        create: (_) => serviceLocator<StaffDocumentsListCubit>()
          ..loadInitial(staffCode),
      ),
      BlocProvider<StaffClassroomNameCubit>(
        create: (_) => serviceLocator<StaffClassroomNameCubit>(),
      ),
    ],
    child: child,
  );
}

Widget _staffProfileScreen(Object? extra) {
  final args = extra as StaffProfileArgs?;
  final staffCode = args?.staffCode ?? '';
  return _staffProfileScope(
    staffCode: staffCode,
    child: StaffProfileScreen(
      staffCode: staffCode,
      userCode: args?.userCode ?? '',
      name: args?.name ?? '-',
      classroom: args?.classroom ?? '-',
      designation: args?.designation ?? '',
      phoneNumber: args?.phoneNumber ?? '',
      employmentStatus: args?.employmentStatus,
      classroomNames: args?.classroomNames,
      classroomNameByCode: args?.classroomNameByCode,
    ),
  );
}

Widget _studentAttendanceProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StudentAttendanceProfile(
    studentCode: args['studentCode'] as String? ?? '',
    studentId: args['studentId'] as int? ?? 0,
    studentName: args['studentName'] as String? ?? '',
    studentPhotoUuid: args['studentPhotoUuid'] as String?,
    roomName: args['roomName'] as String? ?? '—',
    isSignedIn: args['isSignedIn'] as bool? ?? false,
    isAbsent: args['isAbsent'] as bool? ?? false,
    isExpectedToday: args['isExpectedToday'] as bool? ?? true,
    isPresentToday: args['isPresentToday'] as bool? ?? false,
    profileStatus: args['profileStatus'] as String? ?? 'A',
    syncWithParentChildSelection:
        args['syncWithParentChildSelection'] as bool? ?? false,
    initialShowAbsentDays: args['initialShowAbsentDays'] as bool? ?? false,
  );
}

Widget _staffAttendanceProfileScreen(Object? extra) {
  final args = extra as Map<String, dynamic>? ?? const {};
  return StaffAttendanceProfile(
    staffCode: args['staffCode'] as String? ?? '',
    staffId: args['staffId'] as int? ?? 0,
    staffName: args['staffName'] as String? ?? '-',
    staffPhotoUuid: args['staffPhotoUuid'] as String?,
    designationName: args['designationName'] as String? ?? '',
    roomName: args['roomName'] as String? ?? '-',
    isSignedIn: args['isSignedIn'] as bool? ?? false,
    isAbsent: args['isAbsent'] as bool? ?? false,
    isExpectedToday: args['isExpectedToday'] as bool? ?? true,
    isPresentToday: args['isPresentToday'] as bool? ?? false,
    profileStatus: args['profileStatus'] as String? ?? 'A',
    initialShowAbsentDays: args['initialShowAbsentDays'] as bool? ?? false,
  );
}

/// Snappier page builder for drill-down routes — the default Material
/// transition is ~300 ms which feels sluggish on back; we use a 180 ms slide
/// so push *and* pop animations stay smooth and tight.
Page<dynamic> _fastPage(GoRouterState state, Widget child) {
  // Notification deep-links carry their target in the query string
  // (e.g. `?code=…&highlightCode=…`). go_router's default `state.pageKey` is
  // derived from the route PATH only, so navigating to the same route with a
  // DIFFERENT query reuses the cached screen's State (Navigator calls
  // `didUpdateWidget`, not `initState`) — and screens that load their data in
  // `initState` silently keep showing the first target, ignoring the new
  // deep-link. Key query-carrying pages by their full location so a different
  // query builds a fresh page and re-inits with the notified record. Query-less
  // routes keep the stable per-path key so tab/scroll state survives re-entry.
  final key = state.uri.hasQuery
      ? ValueKey<String>('${state.matchedLocation}?${state.uri.query}')
      : state.pageKey;
  return CustomTransitionPage<dynamic>(
    key: key,
    name: state.matchedLocation,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.04, 0);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    child: child,
  );
}

/// Parses a `yyyy-MM-dd` (or ISO) query param into a local date, or null.
/// Used by notification deep-links that jump the schedule to a specific day.
DateTime? _parseYmd(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Thin wrapper that renders the [StatefulNavigationShell] as its content.
///
/// Caches the shell widget in state so that layout-phase rebuilds always
/// return the **same** Dart object from [build]. Flutter's [Element.updateChild]
/// fast-paths `child.widget == returnedWidget` → no-op when the reference is
/// identical, which prevents the "[_InactiveElements.remove] element not in
/// inactive set" assertion that fires when a layout-phase [BuildOwner.buildScope]
/// tries to retake a GlobalKey element that is still active.
///
/// When the shell reference genuinely changes (router recreated), we defer the
/// swap to a post-frame callback so it never happens inside a layout pass.
class _ShellScopeContent extends StatefulWidget {
  const _ShellScopeContent({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_ShellScopeContent> createState() => _ShellScopeContentState();
}

class _ShellScopeContentState extends State<_ShellScopeContent> {
  late StatefulNavigationShell _cachedShell;

  @override
  void initState() {
    super.initState();
    _cachedShell = widget.navigationShell;
  }

  @override
  void didUpdateWidget(covariant _ShellScopeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell != oldWidget.navigationShell) {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _cachedShell = widget.navigationShell;
            });
          }
        });
      } else {
        _cachedShell = widget.navigationShell;
      }
    }
  }

  @override
  Widget build(BuildContext context) => _cachedShell;
}

/// InheritedWidget so CustomNavigationBar can find the
/// StatefulNavigationShell without tab screens having to pass it through.
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.shell, required super.child});

  final StatefulNavigationShell shell;

  static StatefulNavigationShell? maybeOf(BuildContext context) {
    // Look up the InheritedWidget statically via its Element to avoid
    // registering a reactive dependency. This prevents layout-phase rebuild
    // conflicts when CustomNavigationBar reads the active shell.
    final element = context
        .getElementForInheritedWidgetOfExactType<_ShellScope>();
    if (element == null) return null;
    return (element.widget as _ShellScope).shell;
  }

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      shell.currentIndex != oldWidget.shell.currentIndex;
}

/// Public accessor used by the bottom-nav widget.
StatefulNavigationShell? appNavigationShell(BuildContext context) =>
    _ShellScope.maybeOf(context);

/// Navigates to the Dashboard branch's root screen, the PROVEN way — see
/// CustomNavigationBar._performNavigation, which switches branches via
/// `shell.goBranch(branchIndex)`, never a bare `context.go(...)`. A plain
/// `context.go(AppRoutes.dashboard)` while already inside the shell on a
/// DIFFERENT branch (e.g. Communication/Messaging) does not reliably swap
/// which branch the IndexedStack shows — the underlying GoRouterState/
/// location updates, but StatefulNavigationShell's own active-index
/// tracking is what CustomNavigationBar's tab-switching relies on
/// `goBranch` for, not `go`. That's what made "Switch Profile" land back
/// on Messages instead of Dashboard even after
/// [popAllShellBranchNavigators] correctly cleared everything pushed on
/// top of it.
void goToDashboardRoot(BuildContext context) {
  final shell = appNavigationShell(context);
  if (shell != null && shell.currentIndex != 0) {
    shell.goBranch(0);
  } else {
    GoRouter.of(context).go(AppRoutes.dashboard);
  }
}

/// Drop-in replacement for `appRouter.go(location, extra: extra)` at every
/// call site OUTSIDE `CustomNavigationBar` (the drawer, notification taps,
/// deep links, anywhere else that navigates straight to a route by string
/// path) — those all bypass `CustomNavigationBar._performNavigation`
/// entirely, so a bare `appRouter.go(...)` to a bottom-nav branch's root path
/// (e.g. Activities, Classroom) never told that kept-alive branch screen it
/// had just become visible again (see [TabVisibilityEvents]'s doc comment).
/// This fires that same signal whenever [location] IS one of
/// [branchRootPaths], then does the actual navigation.
void appRouterGo(String location, {Object? extra}) {
  final targetPath = Uri.parse(location).path;
  final branchIndex = branchRootPaths.indexOf(targetPath);
  if (branchIndex != -1) {
    TabVisibilityEvents.notifyBranchActivated(branchIndex);
  }
  appRouter.go(location, extra: extra);
}
