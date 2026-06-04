import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';
import '../../../../domain/features/notifications/repositories/push_notification_repository.dart';
import '../../../../domain/features/notifications/usecases/register_device_fcm_token_usecase.dart';
import '../../../../shared/services/geofence_notification_service.dart';
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
        AppLogger.d('[FCM] Foreground: ${message.title} | ${message.data}');
        final destination = NotificationRouteResolver.resolve(message);
        _localNotifications.showCustomNotification(
          title: message.title ?? 'School Alert',
          body: message.body ?? 'You have a new notification',
          payload: destination?.location,
        );
      });

      // Tap while app was in the background.
      _onTapSub = _repository.onNotificationTap.listen(_requestNavigation);
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

  void _requestNavigation(PushNotification message) {
    AppLogger.d('[FCM] Tap → action=${message.action} data=${message.data}');
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
    return super.close();
  }
}
