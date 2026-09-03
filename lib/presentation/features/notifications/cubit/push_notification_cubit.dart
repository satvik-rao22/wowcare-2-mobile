import 'dart:async';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/notifications/deep_link_parser.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/notification_payload.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';
import '../../../../domain/features/notifications/repositories/push_notification_repository.dart';
import '../../../../domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import '../../../../shared/common/app/cubit/role_cubit.dart';
import '../../../../shared/services/geofence_notification_service.dart';
import '../../../../app/di/di.dart';
import '../../../../core/util/notification_events.dart';
import 'notification_badge_cubit.dart';
import '../routing/notification_route_resolver.dart';
part 'push_notification_state.dart';

/// ViewModel for push notifications.
///
/// Owns the FCM lifecycle (permission, token, message streams) and surfaces a
/// tapped notification as [PushNotificationState.navigationRequest] for the View
/// layer to act on — the cubit never touches the router itself, keeping it free
/// of navigation/UI dependencies and unit-testable.
///
/// Note: the background/terminated *isolate* handler stays as a top-level
/// function in `main.dart` (a Firebase requirement); this cubit handles the
/// foreground and the on-tap navigation that runs in the main isolate.
class PushNotificationCubit extends Cubit<PushNotificationState> {
  PushNotificationCubit({
    required PushNotificationRepository repository,
    required GeofenceNotificationService localNotifications,
    required RegisterDeviceFcmTokenUseCase registerDeviceFcmToken,
  }) : _repository = repository,
       _localNotifications = localNotifications,
       _registerDeviceFcmToken = registerDeviceFcmToken,
       super(const PushNotificationState.initial());

  final PushNotificationRepository _repository;
  final GeofenceNotificationService _localNotifications;
  final RegisterDeviceFcmTokenUseCase _registerDeviceFcmToken;

  StreamSubscription<PushNotification>? _onMessageSub;
  StreamSubscription<PushNotification>? _onTapSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<Uri>? _onDeepLinkSub;
  final AppLinks _appLinks = AppLinks();

  /// Last FCM token — re-synced when session becomes ready after login/splash.
  String? _lastToken;

  /// Wires up permissions, token retrieval and message listeners. Call once,
  /// after the View's [BlocListener] is mounted, so a killed-state launch tap
  /// isn't emitted before anyone is listening.
  ///
  /// Note: FCM registration is deferred until after auth is complete (AuthCubit
  /// handles this via _registerDeviceFcmTokenIfSessionReady). Here we only set
  /// up permissions and listeners, not registration.
  Future<void> init() async {
    try {
      // Note: the killed-state launch tap is captured in main() (before runApp)
      // and stashed as `pendingNotificationDeepLink` for the splash to consume —
      // doing it here (post-frame) would race the splash's auth timer.
      await _repository.requestPermission();

      final token = await _repository.getToken();
      AppLogger.d('[FCM] Device token: $token');
      if (token != null) {
        _lastToken = token;
        emit(state.copyWith(token: token));
        // FCM registration deferred to AuthCubit after login completes.
        // Registering here would fail with 401 since auth token isn't set yet.
        AppLogger.d(
          '[FCM] Token received; registration will happen after auth',
        );
      }

      _onTokenRefreshSub = _repository.onTokenRefresh.listen((newToken) {
        AppLogger.d('[FCM] Token refreshed: $newToken');
        _lastToken = newToken;
        emit(state.copyWith(token: newToken));
        // Only auto-register on refresh if already authenticated (has stored access token).
        // Otherwise auth flow will handle initial registration after login.
        _registerOnTokenRefreshIfAuthenticated(newToken);
      });

      // Foreground: the OS does not show a tray notification, so surface one
      // locally to keep parity with background/killed behaviour. Attach the
      // resolved deep-link location as the payload so tapping the foreground
      // notification redirects exactly like a background-tray tap (otherwise a
      // foreground tap does nothing and the user stays put).
      _onMessageSub = _repository.onMessage.listen((message) {
        AppLogger.d('[FCM] ════════ Foreground notification received ════════');
        AppLogger.d('[FCM] title : ${message.title}');
        AppLogger.d('[FCM] body  : ${message.body}');
        AppLogger.d('[FCM] data  : ${message.data}');
        AppLogger.d(
          '[FCM] ═══════════════════════════════════════════════════',
        );
        // A push may correspond to a new bell notification. Re-fetch the
        // authoritative REST unread-count (never increment locally — the count
        // is always server-derived, never accumulated on device) and tell any
        // open Notification Center to reload its list. Use the retrying
        // variant: the backend's own read-model can lag a beat behind the
        // push it just sent, so a single read taken right now can come back
        // stale — the retry re-reads shortly after to self-correct.
        try {
          serviceLocator<NotificationBadgeCubit>().refreshWithRetry();
        } catch (_) {}
        NotificationEvents.notifyChanged();
        // Resolve with the current persona: billing opens the PARENT billing
        // screen for guardians and the admin one for staff/admins. This payload
        // is what a tap on the local notification routes to, so resolving it
        // persona-less sent parents to the (empty-for-them) admin billing screen.
        // Admin persona also gets a direct deep-link for newsletter / pending
        // approval activity notifications instead of the shared list screens.
        final destination = NotificationRouteResolver.resolve(
          message,
          isGuardian: _isGuardianPersona(),
          isAdminPersona: _isAdminPersonaOnly(),
        );
        // Encode the target org/school into the payload so a tap on this local
        // notification (now, or after a kill/relaunch) can switch school before
        // routing — the plain location alone would lose that context.
        final payload = destination == null
            ? null
            : encodeNotificationPayload(
                location: destination.location,
                organizationCode: message.organizationCode,
                schoolCode: message.schoolCode,
              );
        // Avoid showing the notification TWICE. A message that carries a
        // notification payload (title/body non-null — see PushNotificationModel)
        // is auto-displayed by iOS in the foreground via
        // setForegroundNotificationPresentationOptions(alert:true). Showing our
        // own local notification on top of that produced two banners. Only
        // surface a local notification when the OS won't:
        //   • Android foreground never auto-shows notification-payload messages,
        //   • data-only messages (title == null) aren't shown by either OS.
        final bool hasOsNotificationPayload =
            message.title != null || message.body != null;
        final bool osAlreadyShows = hasOsNotificationPayload && Platform.isIOS;
        if (!osAlreadyShows) {
          _localNotifications.showCustomNotification(
            title: message.title ?? 'School Alert',
            body: message.body ?? 'You have a new notification',
            payload: payload,
          );
        }

        // Signal any open conversation thread to refresh when a new message
        // arrives for it. The seq counter ensures consecutive events on the
        // same conversation still trigger Equatable-based BlocListeners.
        final convCode = message.data['conversationCode'];
        if (message.data['type'] == 'NEW_MESSAGE' &&
            convCode != null &&
            convCode.isNotEmpty) {
          emit(
            state.copyWith(
              newMessageEventSeq: state.newMessageEventSeq + 1,
              incomingConversationCode: convCode,
            ),
          );
        }
      });

      // Tap while app was in the background.
      _onTapSub = _repository.onNotificationTap.listen(_requestNavigation);

      // Universal Link / Android App Link tapped while the app is already
      // running (foreground or background, not killed) — e.g. an email
      // button. The killed-state/cold-start equivalent is handled separately
      // in notification_launch_handler.dart before this cubit even exists,
      // via the same pushNotificationFromDeepLinkUri parser.
      _onDeepLinkSub = _appLinks.uriLinkStream.listen((uri) {
        final notification = pushNotificationFromDeepLinkUri(uri);
        if (notification == null) return;
        AppLogger.d('[DeepLink] Tap while running: $uri');
        _requestNavigation(notification);
      });
    } catch (e) {
      AppLogger.d('[FCM] setup failed (continuing without push): $e');
    }
  }

  /// Register token on refresh (use case handles 401 gracefully if not authenticated).
  /// Fire-and-forget: don't await to avoid blocking the token refresh event.
  void _registerOnTokenRefreshIfAuthenticated(String token) {
    // Use case handles auth failures gracefully (marked as non-fatal in logs)
    // If user is not authenticated yet, the 401 is caught and ignored.
    // ignore: unawaited_futures
    _registerDeviceFcmToken(fcmToken: token);
  }

  /// Current persona, read off the root navigator's [RoleCubit] (the cubit lives
  /// above the router, so it is reachable without a local BuildContext — the
  /// same approach [SessionExpiredCoordinator] uses). Defaults to false when the
  /// tree isn't up yet, matching the resolver's own default.
  bool _isGuardianPersona() {
    try {
      final ctx = CoreUtils.rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return false;
      return ctx.read<RoleCubit>().isParent;
    } catch (_) {
      return false;
    }
  }

  /// True only for the `admin` persona bucket — deliberately narrower than
  /// [RoleCubit.isAdmin], which also covers `staff`. See
  /// [NotificationRouteResolver.resolve]'s `isAdminPersona` param.
  bool _isAdminPersonaOnly() {
    try {
      final ctx = CoreUtils.rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return false;
      return ctx.read<RoleCubit>().role == 'admin';
    } catch (_) {
      return false;
    }
  }

  void _requestNavigation(PushNotification message) {
    AppLogger.d('[FCM] Tap → action=${message.action} data=${message.data}');
    // This message was delivered while the app was backgrounded/killed, so
    // the foreground onMessage handler above never ran for it — without this,
    // the badge stays stale until some unrelated screen refresh happens to
    // reload it.
    try {
      serviceLocator<NotificationBadgeCubit>().refreshWithRetry();
    } catch (_) {}
    emit(state.copyWith(navigationRequest: message));
  }

  /// Clears the pending navigation request once the View has handled it.
  void clearNavigationRequest() => emit(state.clearNavigationRequest());

  /// Call after login/splash when org+school are in storage (init may have run too early).
  Future<void> syncTokenWithBackend() async {
    final token = _lastToken ?? await _repository.getToken();
    if (token == null || token.trim().isEmpty) return;
    _lastToken = token;
    await _registerDeviceFcmToken(fcmToken: token);
  }

  @override
  Future<void> close() {
    _onMessageSub?.cancel();
    _onTapSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onDeepLinkSub?.cancel();
    return super.close();
  }
}
