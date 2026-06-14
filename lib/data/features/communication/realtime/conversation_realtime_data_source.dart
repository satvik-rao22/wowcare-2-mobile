import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

  final String conversationCode;
  final String conversationType;
  final String lastMessagePreview;
  final int unreadCount;
  final bool isActive;
  final bool isMuted;
  final bool isPinned;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderCode;
  final String? lastMessageSenderName;
  final String? schoolCode;
  final bool? privateModeActive;

  factory ConversationInboxItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ConversationInboxItem(
      conversationCode: d['conversationCode'] as String? ?? doc.id,
      conversationType: d['conversationType'] as String? ?? 'ROOM_CHAT',
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
      title: '',
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
}

// ─── Firebase implementation ─────────────────────────────────────────────────

class FirebaseConversationRealtimeDataSource
    implements ConversationRealtimeDataSource {
  const FirebaseConversationRealtimeDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _inboxRef({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
  }) =>
      firestore
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
    // and causes a silent error that falls back to the REST API (losing live
    // unread counts). Sort on the client instead.
    Query<Map<String, dynamic>> query = _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    );

    if (filterType != null) {
      query = query.where('conversationType', isEqualTo: filterType);
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(ConversationInboxItem.fromFirestore)
          .where((item) => item.isActive)
          .toList();

      // Client-side sort: newest lastMessageAt first; nulls go to the end.
      items.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      return items;
    });
  }

  @override
  Stream<int> watchTotalUnreadCount({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
  }) {
    return _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    ).snapshots().map(
          (snapshot) => snapshot.docs.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['unreadCount'] as num?)?.toInt() ?? 0),
          ),
        );
  }

  @override
  Stream<int> watchUnreadCountForType({
    required String organizationCode,
    required String schoolCode,
    required String userCode,
    required String conversationType,
  }) {
    // Lightweight stream — only reads unreadCount, no Isar involved.
    return _inboxRef(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      userCode: userCode,
    )
        .where('conversationType', isEqualTo: conversationType)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['unreadCount'] as num?)?.toInt() ?? 0),
          ),
        );
  }
}
