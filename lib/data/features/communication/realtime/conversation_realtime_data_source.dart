import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/firebase/firebase_auth_service.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

// ─── Lightweight DTO for Firestore user_inbox data ──────────────────────────
/// Represents the per-user conversation record stored in Firestore
/// under orgs/{org}/schools/{school}/user_inbox/{user}/conversations/{code}.
///
/// Contains only the fields Firestore keeps denormalised per user.
/// Missing metadata (title, avatarUrl, participants) is filled in from Isar.
class ConversationInboxItem {
  const ConversationInboxItem({
    required this.conversationCode,
    required this.conversationType,
    this.title = '',
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.isActive,
    required this.isMuted,
    required this.isPinned,
    this.lastMessageAt,
    this.lastMessageSenderCode,
    this.lastMessageSenderName,
    this.schoolCode,
    this.privateModeActive,
    this.privateModeActivatedBy,
    this.privateModeActivatedAt,
  });

  final String conversationCode;
  final String conversationType;

  /// The conversation's stored title from the inbox doc (room/student/classroom name, or the frozen
  /// counterpart name for STAFF_DIRECT). Parsed so the no-cache [toMinimalEntity] can show it instead
  /// of the "Conversation" placeholder until the participant roster loads from the Isar cache.
  final String title;
  final String lastMessagePreview;
  final int unreadCount;
  final bool isActive;
  final bool isMuted;
  final bool isPinned;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderCode;
  final String? lastMessageSenderName;
  final String? schoolCode;

  /// Parsed but intentionally not merged into [ConversationEntity] yet — this
  /// is a single bool on a per-user inbox doc, while [ConversationEntity]
  /// tracks private mode per-guardian via `privateModeStates`. Whether this
  /// means "private mode is on for the recipient of this inbox doc" or
  /// something else needs confirming with the backend before merging it; a
  /// wrong guess here would mis-flag a conversation as private/not-private
  /// for the wrong guardian.
  final bool? privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;

  factory ConversationInboxItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ConversationInboxItem(
      conversationCode: d['conversationCode'] as String? ?? doc.id,
      conversationType: d['conversationType'] as String? ?? 'ROOM_CHAT',
      title: d['title'] as String? ?? '',
      lastMessagePreview: d['lastMessagePreview'] as String? ?? '',
      unreadCount: (d['unreadCount'] as num?)?.toInt() ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      isMuted: d['isMuted'] as bool? ?? false,
      isPinned: d['isPinned'] as bool? ?? false,
      lastMessageAt: _parseTimestamp(d['lastMessageAt']),
      lastMessageSenderCode: d['lastMessageSenderCode'] as String?,
      lastMessageSenderName: d['lastMessageSenderName'] as String?,
      schoolCode: d['schoolCode'] as String?,
      privateModeActive: d['privateModeActive'] as bool?,
      privateModeActivatedBy: d['privateModeActivatedBy'] as String?,
      privateModeActivatedAt: _parseTimestamp(d['privateModeActivatedAt']),
    );
  }

  /// Merges this Firestore snapshot into an existing cached [ConversationEntity].
  ///
  /// Preserves metadata fields (title, avatarUrl, participants) from the cache.
  /// Only the realtime fields (unreadCount, lastMessage*) are overwritten.
  ConversationEntity mergeWith(ConversationEntity cached) {
    return ConversationEntity(
      id: cached.id,
      code: conversationCode,
      type: ConversationType.fromApiString(conversationType),
      title: cached.title,
      description: cached.description,
      avatarUrl: cached.avatarUrl,
      status: isActive ? 'ACTIVE' : 'INACTIVE',
      organizationCode: cached.organizationCode,
      schoolCode: schoolCode ?? cached.schoolCode,
      createdAt: cached.createdAt,
      createdBy: cached.createdBy,
      updatedAt: cached.updatedAt,
      updatedBy: cached.updatedBy,
      participantCount: cached.participantCount,
      unreadCount: unreadCount,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt ?? cached.lastMessageAt,
      lastMessageBy: lastMessageSenderCode ?? cached.lastMessageBy,
      lastMessageSenderName:
          lastMessageSenderName ?? cached.lastMessageSenderName,
      participants: cached.participants,
      studentCode: cached.studentCode,
      classroomCode: cached.classroomCode,
      privateModeActive: privateModeActive ?? cached.privateModeActive,
      privateModeActivatedBy:
          privateModeActivatedBy ?? cached.privateModeActivatedBy,
      privateModeActivatedAt:
          privateModeActivatedAt ?? cached.privateModeActivatedAt,
      privateModeStates: cached.privateModeStates,
    );
  }

  /// Creates a minimal entity when there is no Isar cache for this conversation.
  ConversationEntity toMinimalEntity({
    required String organizationCode,
    required String schoolCode,
  }) {
    return ConversationEntity(
      id: 0,
      code: conversationCode,
      type: ConversationType.fromApiString(conversationType),
      title: title,
      description: '',
      avatarUrl: '',
      status: isActive ? 'ACTIVE' : 'INACTIVE',
      organizationCode: organizationCode,
      schoolCode: this.schoolCode ?? schoolCode,
      createdAt: DateTime.now(),
      createdBy: '',
      updatedAt: DateTime.now(),
      updatedBy: '',
      participantCount: 0,
      unreadCount: unreadCount,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageSenderCode,
      lastMessageSenderName: lastMessageSenderName,
      privateModeActive: privateModeActive ?? false,
      privateModeActivatedBy: privateModeActivatedBy,
      privateModeActivatedAt: privateModeActivatedAt,
      participants: const [],
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) {
      // Epoch seconds or milliseconds
      return value > 1e12
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return null;
  }
}

// ─── Abstract contract ───────────────────────────────────────────────────────

abstract class ConversationRealtimeDataSource {
  /// Stream of per-user inbox items from Firestore user_inbox collection.
  ///
  /// [filterType] — when non-null, filters to a specific conversationType.
  /// Results are sorted by [lastMessageAt] descending on the client — NO
  /// Firestore orderBy is used, so no composite index is required.
  Stream<List<ConversationInboxItem>> watchInbox({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    String? filterType,
  });

  /// Lightweight stream: total unread count across all conversations.
  /// Only reads [unreadCount] — never triggers Isar reads or writes.
  Stream<int> watchTotalUnreadCount({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
  });

  /// Lightweight per-type unread sum — only reads [unreadCount] per doc.
  /// Used by [UnreadBadgeCubit] to avoid duplicating the full merge pipeline.
  Stream<int> watchUnreadCountForType({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationType,
  });

  /// Lightweight per-conversation unread — reads [unreadCount] for the single
  /// inbox doc keyed by [conversationCode]. Used for per-classroom badges.
  Stream<int> watchUnreadCountForConversation({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationCode,
  });
}

// ─── Firebase implementation ─────────────────────────────────────────────────

class FirebaseConversationRealtimeDataSource
    implements ConversationRealtimeDataSource {
  const FirebaseConversationRealtimeDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  // Retry delays in seconds — same progression used by
  // FirebaseMessageRealtimeDataSource. The inbox listener races the Firebase
  // custom-token sign-in (signInWithCustomToken is async). Four retries cover
  // the typical auth propagation window without blocking the UI.
  static const _retryDelays = [2, 4, 8, 16];

  CollectionReference<Map<String, dynamic>> _inboxRef({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
  }) => firestore
      .collection('orgs')
      .doc(organizationCode)
      .collection('schools')
      .doc(schoolCode)
      .collection('user_inbox')
      .doc(userCode)
      .collection('conversations');

  @override
  Stream<List<ConversationInboxItem>> watchInbox({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    String? filterType,
  }) {
    // Bug fix: do NOT use orderBy('lastMessageAt') + where('conversationType')
    // together — that requires a Firestore composite index which may not exist
    // and causes a silent error. Sort on the client instead.
    Query<Map<String, dynamic>> query = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    );
    if (filterType != null) {
      query = query.where('conversationType', isEqualTo: filterType);
    }

    final controller = StreamController<List<ConversationInboxItem>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inner;
    StreamSubscription<User?>? authWaitSub;
    late void Function(int attempt) attach;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      if (error is FirebaseException && error.code == 'permission-denied') {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
        if (attempt < _retryDelays.length) {
          Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
            if (!controller.isClosed) attach(attempt + 1);
          });
        } else {
          authWaitSub?.cancel();
          authWaitSub = FirebaseAuth.instance.authStateChanges().listen((user) {
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
        controller.close();
      }
    }

    attach = (int attempt) {
      inner?.cancel();
      runZonedGuarded(() {
        inner = query.snapshots().listen(
          (snapshot) {
            if (controller.isClosed) return;
            final items =
                snapshot.docs
                    .map(ConversationInboxItem.fromFirestore)
                    .where((item) => item.isActive)
                    .toList()
                  ..sort((a, b) {
                    if (a.lastMessageAt == null && b.lastMessageAt == null) {
                      return 0;
                    }
                    if (a.lastMessageAt == null) return 1;
                    if (b.lastMessageAt == null) return -1;
                    return b.lastMessageAt!.compareTo(a.lastMessageAt!);
                  });
            controller.add(items);
          },
          onError: (Object error) => retryOrForward(error, attempt),
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
          cancelOnError: true,
        );
      }, (Object error, StackTrace _) => retryOrForward(error, attempt));
    };

    controller.onListen = () => attach(0);
    controller.onCancel = () {
      inner?.cancel();
      inner = null;
      authWaitSub?.cancel();
      authWaitSub = null;
    };
    return controller.stream;
  }

  @override
  Stream<int> watchTotalUnreadCount({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
  }) {
    final ref = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    );

    final controller = StreamController<int>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inner;
    StreamSubscription<User?>? authWaitSub;
    late void Function(int attempt) attach;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      if (error is FirebaseException && error.code == 'permission-denied') {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
        if (attempt < _retryDelays.length) {
          Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
            if (!controller.isClosed) attach(attempt + 1);
          });
        } else {
          authWaitSub?.cancel();
          authWaitSub = FirebaseAuth.instance.authStateChanges().listen((user) {
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
        controller.close();
      }
    }

    attach = (int attempt) {
      inner?.cancel();
      runZonedGuarded(() {
        inner = ref.snapshots().listen(
          (snapshot) {
            if (controller.isClosed) return;
            controller.add(
              snapshot.docs.fold<int>(
                0,
                (sum, doc) =>
                    sum + ((doc.data()['unreadCount'] as num?)?.toInt() ?? 0),
              ),
            );
          },
          onError: (Object error) => retryOrForward(error, attempt),
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
          cancelOnError: true,
        );
      }, (Object error, StackTrace _) => retryOrForward(error, attempt));
    };

    controller.onListen = () => attach(0);
    controller.onCancel = () {
      inner?.cancel();
      inner = null;
      authWaitSub?.cancel();
      authWaitSub = null;
    };
    return controller.stream;
  }

  @override
  Stream<int> watchUnreadCountForType({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationType,
  }) {
    final query = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    ).where('conversationType', isEqualTo: conversationType);
    return _watchInboxUnreadSum(query);
  }

  @override
  Stream<int> watchUnreadCountForConversation({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationCode,
  }) {
    // A single inbox doc, keyed by conversationCode (the doc id). Reusing the
    // same query-snapshot path as the per-type watch keeps the resilient
    // permission-denied re-auth / backoff behaviour identical (0 or 1 doc →
    // its unreadCount).
    final query = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    ).where(FieldPath.documentId, isEqualTo: conversationCode);
    return _watchInboxUnreadSum(query);
  }

  /// Resilient sum of `unreadCount` across the docs matched by [query] in the
  /// user_inbox collection, with the shared permission-denied re-auth + backoff
  /// retry. Backs both the per-type and per-conversation unread watches.
  Stream<int> _watchInboxUnreadSum(Query<Map<String, dynamic>> query) {
    final controller = StreamController<int>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inner;
    StreamSubscription<User?>? authWaitSub;
    late void Function(int attempt) attach;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      if (error is FirebaseException && error.code == 'permission-denied') {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
        if (attempt < _retryDelays.length) {
          Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
            if (!controller.isClosed) attach(attempt + 1);
          });
        } else {
          authWaitSub?.cancel();
          authWaitSub = FirebaseAuth.instance.authStateChanges().listen((user) {
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
        controller.close();
      }
    }

    attach = (int attempt) {
      inner?.cancel();
      runZonedGuarded(() {
        inner = query.snapshots().listen(
          (snapshot) {
            if (controller.isClosed) return;
            controller.add(
              snapshot.docs.fold<int>(
                0,
                (sum, doc) =>
                    sum + ((doc.data()['unreadCount'] as num?)?.toInt() ?? 0),
              ),
            );
          },
          onError: (Object error) => retryOrForward(error, attempt),
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
          cancelOnError: true,
        );
      }, (Object error, StackTrace _) => retryOrForward(error, attempt));
    };

    controller.onListen = () => attach(0);
    controller.onCancel = () {
      inner?.cancel();
      inner = null;
      authWaitSub?.cancel();
      authWaitSub = null;
    };
    return controller.stream;
  }
}
