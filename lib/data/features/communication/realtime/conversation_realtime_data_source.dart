import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/firebase/firebase_auth_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

/// Picks the persona-correct unread count off a raw user_inbox document map.
///
/// Prefers the per-persona breakdown present on conversations more than one
/// role can see (e.g. ADMIN_CHAT — see [ConversationInboxItem.fromFirestore]'s
/// own doc for why a flat count isn't enough there), and falls back to the
/// flat `unreadCount` field when [roleBucket] is null or the document has
/// neither shape below (every other conversation type, and any doc from
/// before this field existed).
///
/// The backend writes this as a FLAT field literally named `unreadByRole.
/// ADMIN` / `unreadByRole.GUARDIAN` (a dot inside the key itself — the write
/// path used a plain map literal with `set(..., merge: true)`, which treats
/// the key as one opaque segment, not `update()`'s dot-as-nested-path
/// notation) — confirmed from the Firestore console, which renders it as an
/// unindented top-level row, not an expandable nested map. `doc.data()`
/// hands that back as a literal `"unreadByRole.ADMIN"` key in the returned
/// map, NOT as `data['unreadByRole']['ADMIN']`. Checking the actual nested-map
/// shape too, second, costs nothing and keeps this correct if a future
/// backend change ever switches to writing it that way instead.
int resolveRoleAwareUnreadCount(Map<String, dynamic> data, String? roleBucket) {
  final flat = (data['unreadCount'] as num?)?.toInt() ?? 0;
  if (roleBucket == null) return flat;

  // STAFF_DIRECT is strictly peer-to-peer (Teachers/Staff/Admins/Directors
  // only, one conversation = exactly two parties) — the reading account's
  // role IN THIS CONVERSATION is fixed at creation and never ambiguous, so
  // there is no "which of my personas is this doc for" question to answer
  // the way there is for ADMIN_CHAT/ROOM_CHAT (where the SAME physical
  // account can hold two roles that both see the identical doc, e.g. an
  // admin who is also a guardian at that school). If the backend ever
  // stamps a STAFF_DIRECT doc's `unreadByRole` with a key that isn't this
  // reader's current persona bucket (e.g. the sender's role), the
  // roleAwareNoEntry branch below would silently resolve a genuinely
  // unread STAFF_DIRECT message to 0 — always trust the flat count here
  // instead.
  if (data['conversationType'] == 'STAFF_DIRECT') return flat;

  final dottedKey = data['unreadByRole.$roleBucket'];
  if (dottedKey is num) {
    AppLogger.d(
      '[UnreadDebug][resolve] conv=${data['conversationCode']} '
      'roleBucket=$roleBucket source=dottedKey flat=$flat '
      'resolved=${dottedKey.toInt()}',
    );
    return dottedKey.toInt();
  }

  final byRole = data['unreadByRole'];
  if (byRole is Map) {
    final perRole = byRole[roleBucket];
    if (perRole is num) {
      AppLogger.d(
        '[UnreadDebug][resolve] conv=${data['conversationCode']} '
        'roleBucket=$roleBucket source=nestedMap flat=$flat '
        'unreadByRole=$byRole resolved=${perRole.toInt()}',
      );
      return perRole.toInt();
    }
  }

  // The doc has started per-role tracking (a dotted `unreadByRole.<OTHER_ROLE>`
  // key, or a non-empty nested `unreadByRole` map) but has no entry for THIS
  // role. An absent entry here means "no unread recorded for this role yet",
  // NOT "trust the flat legacy count" — that flat field can reflect a
  // DIFFERENT role's read state (or a pre-migration value never updated
  // since), which is exactly what left a conversation's badge stuck on a
  // stale non-zero count even after the current role had genuinely read it:
  // the backend only ever wrote an entry for the OTHER role, so this role's
  // read receipt had nowhere role-aware to land, and falling back to flat
  // kept surfacing the other role's number. Only a doc with NO per-role
  // tracking at all (a true legacy doc, or brand new with no unreadByRole
  // data whatsoever) still trusts flat below.
  final hasAnyRoleAwareEntry =
      data.keys.any((k) => k.startsWith('unreadByRole.')) ||
      (byRole is Map && byRole.isNotEmpty);
  if (hasAnyRoleAwareEntry) {
    AppLogger.d(
      '[UnreadDebug][resolve] conv=${data['conversationCode']} '
      'roleBucket=$roleBucket source=roleAwareNoEntry flat=$flat resolved=0',
    );
    return 0;
  }

  AppLogger.d(
    '[UnreadDebug][resolve] conv=${data['conversationCode']} '
    'roleBucket=$roleBucket source=flatFallback flat=$flat',
  );
  return flat;
}

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

  /// [roleBucket] — the CURRENT persona's coarse bucket ('ADMIN' / 'GUARDIAN'),
  /// resolved from [StorageKeys.activeSchoolRole] by the repository. A dual-role
  /// account (e.g. an org admin who is ALSO a guardian at the same school) shares
  /// ONE user_inbox doc per conversation regardless of which persona they're
  /// currently active as, so a flat `unreadCount` can't tell "read as admin" apart
  /// from "read as guardian" for the same underlying doc — that's what the doc's
  /// `unreadByRole` map (e.g. `{ADMIN: 0, GUARDIAN: 3}`) is for on conversations
  /// visible to more than one role (ADMIN_CHAT). Resolved here, once, at parse
  /// time, so every downstream consumer of [unreadCount] (mergeWith,
  /// toMinimalEntity, badges) automatically gets the persona-correct value
  /// without having to know this distinction exists.
  factory ConversationInboxItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? roleBucket,
  }) {
    final d = doc.data() ?? {};
    return ConversationInboxItem(
      conversationCode: d['conversationCode'] as String? ?? doc.id,
      conversationType: d['conversationType'] as String? ?? 'ROOM_CHAT',
      title: d['title'] as String? ?? '',
      lastMessagePreview: d['lastMessagePreview'] as String? ?? '',
      unreadCount: resolveRoleAwareUnreadCount(d, roleBucket),
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
      createdAt: AppTime.nowUtc(),
      createdBy: '',
      updatedAt: AppTime.nowUtc(),
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
  /// [roleBucket] — see [resolveRoleAwareUnreadCount]; the current persona's
  /// coarse bucket ('ADMIN' / 'GUARDIAN'), used to pick the right unread
  /// count on conversations a dual-role account shares one inbox doc for.
  /// Results are sorted by [lastMessageAt] descending on the client — NO
  /// Firestore orderBy is used, so no composite index is required.
  Stream<List<ConversationInboxItem>> watchInbox({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    String? filterType,
    String? roleBucket,
  });

  /// Lightweight stream: total unread count across all conversations.
  /// Only reads [unreadCount] (or the [roleBucket]-selected entry of
  /// `unreadByRole` when present) — never triggers Isar reads or writes.
  Stream<int> watchTotalUnreadCount({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    String? roleBucket,
  });

  /// Lightweight per-type unread sum — only reads [unreadCount] (or the
  /// [roleBucket]-selected entry of `unreadByRole`) per doc. Used by
  /// [UnreadBadgeCubit] to avoid duplicating the full merge pipeline.
  Stream<int> watchUnreadCountForType({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationType,
    String? roleBucket,
  });

  /// Lightweight per-conversation unread — reads [unreadCount] (or the
  /// [roleBucket]-selected entry of `unreadByRole`) for the single inbox doc
  /// keyed by [conversationCode]. Used for per-classroom badges.
  Stream<int> watchUnreadCountForConversation({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationCode,
    String? roleBucket,
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
    String? roleBucket,
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
      final isPermissionDenied =
          error is FirebaseException && error.code == 'permission-denied';
      if (isPermissionDenied) {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
      }
      if (attempt < _retryDelays.length) {
        // Retry on ANY error, not just permission-denied — a transient
        // network blip ('unavailable'), a brief 'deadline-exceeded', or
        // similar was previously treated as terminal (addError + close),
        // permanently killing this list's live sync with no way back short
        // of leaving and reopening the screen. Backoff applies uniformly;
        // only permission-denied gets the extra re-auth nudge above.
        Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
          if (!controller.isClosed) attach(attempt + 1);
        });
      } else if (isPermissionDenied) {
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
      } else {
        // Non-auth error and backoff exhausted — genuinely give up; the
        // cubit's REST fallback still works either way.
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
                    .map(
                      (doc) => ConversationInboxItem.fromFirestore(
                        doc,
                        roleBucket: roleBucket,
                      ),
                    )
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
    String? roleBucket,
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
      final isPermissionDenied =
          error is FirebaseException && error.code == 'permission-denied';
      if (isPermissionDenied) {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
      }
      if (attempt < _retryDelays.length) {
        // Retry on ANY error, not just permission-denied — see the
        // matching comment on watchInbox's retryOrForward.
        Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
          if (!controller.isClosed) attach(attempt + 1);
        });
      } else if (isPermissionDenied) {
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
                    sum + resolveRoleAwareUnreadCount(doc.data(), roleBucket),
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
    String? roleBucket,
  }) {
    final query = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    ).where('conversationType', isEqualTo: conversationType);
    return _watchInboxUnreadSum(query, roleBucket: roleBucket);
  }

  @override
  Stream<int> watchUnreadCountForConversation({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationCode,
    String? roleBucket,
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
    return _watchInboxUnreadSum(query, roleBucket: roleBucket);
  }

  /// Resilient sum of `unreadCount` (role-aware — see
  /// [resolveRoleAwareUnreadCount]) across the docs matched by [query] in the
  /// user_inbox collection, with the shared permission-denied re-auth + backoff
  /// retry. Backs both the per-type and per-conversation unread watches.
  Stream<int> _watchInboxUnreadSum(
    Query<Map<String, dynamic>> query, {
    String? roleBucket,
  }) {
    final controller = StreamController<int>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inner;
    StreamSubscription<User?>? authWaitSub;
    late void Function(int attempt) attach;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      final isPermissionDenied =
          error is FirebaseException && error.code == 'permission-denied';
      if (isPermissionDenied) {
        // Proactively (re)establish Firebase auth for the current user — the session
        // may be stale (account/persona switch) or expired. Deduped + no-ops when
        // already correct, so this is cheap and makes an authStateChanges event fire.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
      }
      if (attempt < _retryDelays.length) {
        // Retry on ANY error, not just permission-denied — see the
        // matching comment on watchInbox's retryOrForward.
        Future.delayed(Duration(seconds: _retryDelays[attempt]), () {
          if (!controller.isClosed) attach(attempt + 1);
        });
      } else if (isPermissionDenied) {
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
      } else {
        controller.addError(error);
        controller.close();
      }
    }

    attach = (int attempt) {
      inner?.cancel();
      runZonedGuarded(() {
        inner = query
            .snapshots(includeMetadataChanges: true)
            .listen(
              (snapshot) {
                if (controller.isClosed) return;
                // Firestore's on-device persistence can serve a stale snapshot
                // (e.g. the pre-mark-read unreadCount) as the FIRST emission on a
                // freshly attached listener, before the server round-trip
                // confirms the real value — that's what let a just-read
                // conversation's badge flash back to a non-zero count on
                // re-subscribe (dashboard badge, classroom Notes badge). Only
                // forward server-confirmed snapshots; a genuinely offline device
                // just waits rather than showing a value the user already read.
                if (snapshot.metadata.isFromCache) return;
                controller.add(
                  snapshot.docs.fold<int>(
                    0,
                    (sum, doc) =>
                        sum +
                        resolveRoleAwareUnreadCount(doc.data(), roleBucket),
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
