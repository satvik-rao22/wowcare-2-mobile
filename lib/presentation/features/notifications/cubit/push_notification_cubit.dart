import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/util/logger_service.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';
import '../../../../domain/features/notifications/repositories/push_notification_repository.dart';
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
  })  : _repository = repository,
        _localNotifications = localNotifications,
        super(const PushNotificationState.initial());

  final PushNotificationRepository _repository;
  final GeofenceNotificationService _localNotifications;

  StreamSubscription<PushNotification>? _onMessageSub;
  StreamSubscription<PushNotification>? _onTapSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  /// Wires up permissions, token retrieval and message listeners. Call once,
  /// after the View's [BlocListener] is mounted, so a killed-state launch tap
  /// isn't emitted before anyone is listening.
  Future<void> init() async {
    try {
      await _repository.requestPermission();

      final token = await _repository.getToken();
      AppLogger.d('[FCM] Device token: $token');
      if (token != null) emit(state.copyWith(token: token));

      _onTokenRefreshSub = _repository.onTokenRefresh.listen((newToken) {
        AppLogger.d('[FCM] Token refreshed: $newToken');
        emit(state.copyWith(token: newToken));
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

      // Tap that launched the app from a killed state.
      final initial = await _repository.getInitialMessage();
      if (initial != null) _requestNavigation(initial);
    } catch (e) {
      AppLogger.d('[FCM] setup failed (continuing without push): $e');
    }
  }

  void _requestNavigation(PushNotification message) {
    AppLogger.d('[FCM] Tap → action=${message.action} data=${message.data}');
    emit(state.copyWith(navigationRequest: message));
  }

  /// Clears the pending navigation request once the View has handled it.
  void clearNavigationRequest() => emit(state.clearNavigationRequest());

  @override
  Future<void> close() {
    _onMessageSub?.cancel();
    _onTapSub?.cancel();
    _onTokenRefreshSub?.cancel();
    return super.close();
  }
}
