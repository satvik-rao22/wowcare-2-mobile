import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Live signal for the notification bell badge.
///
/// The bell COUNT is always derived directly from the live Firestore
/// collection `userNotifications/{userCode}/notifications` — never from REST.
/// Every snapshot is counted client-side for unread docs (see
/// [resolveNotificationIsRead]) and the resulting total emitted directly, the
/// same pattern messaging's `UnreadBadgeCubit`/`resolveRoleAwareUnreadCount`
/// already use for its badge.
abstract class NotificationRealtimeDataSource {
  /// Emits the live unread notification count for [userCode], recomputed on
  /// every Firestore snapshot.
  Stream<int> watchUnreadCount({required String userCode});
}

/// Picks whether a raw `userNotifications/.../notifications` doc is read.
///
/// Defensive about the exact field shape — mirrors the same multi-shape
/// tolerance `resolveRoleAwareUnreadCount` uses for messaging's `unreadByRole`,
/// since this collection's schema was never previously inspected client-side
/// (the old listener only used it as a "something changed" trigger, ignoring
/// doc contents entirely). Checks, in order:
///  1. `readAt` present/non-empty → read (mirrors the REST inbox contract's
///     own `AppNotificationModel.fromInboxJson` derivation).
///  2. `status` present and not `UNREAD` → read (same REST contract).
///  3. `isRead` / `read` boolean, if present.
/// A doc matching none of these is treated as unread (fail-open toward
/// showing a message rather than silently hiding one).
bool resolveNotificationIsRead(Map<String, dynamic> data) {
  final readAt = data['readAt'];
  if (readAt != null && readAt.toString().trim().isNotEmpty) return true;

  final status = (data['status'] ?? '').toString().trim().toUpperCase();
  if (status.isNotEmpty && status != 'UNREAD') return true;

  final isReadRaw = data['isRead'] ?? data['read'];
  if (isReadRaw is bool) return isReadRaw;

  return false;
}

class FirebaseNotificationRealtimeDataSource
    implements NotificationRealtimeDataSource {
  FirebaseNotificationRealtimeDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  /// Permission-denied backoff (seconds), matching the messaging listeners: a
  /// listener that subscribes during a Firebase-auth blip gets permission-denied
  /// and would otherwise stay dead forever.
  static const List<int> _retryDelays = <int>[2, 4, 8, 16];

  /// Bounds the worst-case read size for the count query. Not a "recent N"
  /// window like the old trigger-only listener's `limit(50)` — this needs to
  /// be an authoritative total, so it's sized generously rather than tightly;
  /// a user with more lifetime notifications than this would undercount.
  static const int _maxDocsForCount = 500;

  @override
  Stream<int> watchUnreadCount({required String userCode}) {
    final code = userCode.trim();
    if (code.isEmpty) return const Stream<int>.empty();

    final controller = StreamController<int>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? snapSub;
    StreamSubscription<User?>? authWaitSub;

    Query<Map<String, dynamic>> query() => firestore
        .collection('userNotifications')
        .doc(code)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(_maxDocsForCount);

    void attach(int attempt) {
      AppLogger.d(
        '[NotifBadge] attaching Firestore listener '
        'userNotifications/$code/notifications (attempt $attempt)',
      );
      snapSub?.cancel();
      snapSub = query().snapshots().listen(
        (snap) {
          final unread = snap.docs
              .where((doc) => !resolveNotificationIsRead(doc.data()))
              .length;
          AppLogger.d(
            '[NotifBadge] Firestore snapshot: ${snap.docs.length} docs '
            '(fromCache=${snap.metadata.isFromCache}) → unread=$unread',
          );
          if (!controller.isClosed) controller.add(unread);
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
