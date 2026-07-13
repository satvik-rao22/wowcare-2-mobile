import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Live signal for the notification bell badge.
///
/// The bell COUNT is always read from REST (`/notification/inbox/unread-counts`)
/// — per the notifications spec, the count is NEVER derived from Firestore. This
/// datasource only emits a "something changed" tick from the live Firestore
/// collection `userNotifications/{userCode}/notifications` so the cubit knows to
/// re-fetch the authoritative REST count.
abstract class NotificationRealtimeDataSource {
  /// Emits (value ignored) whenever the user's notifications collection changes.
  Stream<void> watchNotificationChanges({required String userCode});
}

class FirebaseNotificationRealtimeDataSource
    implements NotificationRealtimeDataSource {
  FirebaseNotificationRealtimeDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  /// Permission-denied backoff (seconds), matching the messaging listeners: a
  /// listener that subscribes during a Firebase-auth blip gets permission-denied
  /// and would otherwise stay dead forever.
  static const List<int> _retryDelays = <int>[2, 4, 8, 16];

  @override
  Stream<void> watchNotificationChanges({required String userCode}) {
    final code = userCode.trim();
    if (code.isEmpty) return const Stream<void>.empty();

    final controller = StreamController<void>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? snapSub;
    StreamSubscription<User?>? authWaitSub;

    Query<Map<String, dynamic>> query() => firestore
        .collection('userNotifications')
        .doc(code)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50);

    void attach(int attempt) {
      AppLogger.d(
        '[NotifBadge] attaching Firestore listener '
        'userNotifications/$code/notifications (attempt $attempt)',
      );
      snapSub?.cancel();
      snapSub = query().snapshots().listen(
        (snap) {
          AppLogger.d(
            '[NotifBadge] Firestore snapshot: ${snap.docs.length} docs '
            '(fromCache=${snap.metadata.isFromCache}) → refresh count',
          );
          if (!controller.isClosed) controller.add(null);
        },
        onError: (Object error) {
          if (controller.isClosed) return;
          AppLogger.d('[NotifBadge] Firestore listener error: $error');
          if (error is FirebaseException && error.code == 'permission-denied') {
            if (attempt < _retryDelays.length) {
              Future<void>.delayed(
                Duration(seconds: _retryDelays[attempt]),
                () {
                  if (!controller.isClosed) attach(attempt + 1);
                },
              );
            } else {
              // Retries exhausted: wait for a signed-in Firebase user (the
              // custom-token sign-in may still be racing), then re-subscribe.
              authWaitSub?.cancel();
              authWaitSub =
                  FirebaseAuth.instance.authStateChanges().listen((user) {
                if (controller.isClosed) {
                  authWaitSub?.cancel();
                  return;
                }
                if (user != null) {
                  authWaitSub?.cancel();
                  authWaitSub = null;
                  attach(0);
                }
              });
            }
          } else {
            controller.addError(error);
          }
        },
      );
    }

    controller
      ..onListen = () {
        attach(0);
      }
      ..onCancel = () async {
        await snapSub?.cancel();
        await authWaitSub?.cancel();
      };

    return controller.stream;
  }
}
