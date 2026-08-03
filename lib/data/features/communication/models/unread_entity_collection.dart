import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/unread_entity.dart';

part 'unread_entity_collection.g.dart';

/// Isar collection tracking unread counts per conversation per user.
/// One record per conversation — updated on every message send/receive.
@collection
class UnreadEntityCollection {
  Id get isarId => id;

  late int id;

  @Index(unique: true)
  late String conversationCode;

  /// Raw string; convert via [ConversationType.fromApiString].
  @Index()
  late String conversationType;

  late int unreadCount;
  String? lastUnreadMessageCode;
  DateTime? lastUnreadAt;
  late DateTime updatedAt;

  // Tenancy
  @Index()
  late String organizationCode;

  @Index()
  late String schoolCode;

  DateTime? lastSyncedAt;

  UnreadEntityCollection();

  factory UnreadEntityCollection.fromEntity(UnreadEntity entity) {
    return UnreadEntityCollection()
      ..conversationCode = entity.conversationCode
      ..conversationType = entity.conversationType.toApiString()
      ..unreadCount = entity.unreadCount
      ..lastUnreadMessageCode = entity.lastUnreadMessageCode
      ..lastUnreadAt = entity.lastUnreadAt
      ..updatedAt = entity.updatedAt
      ..organizationCode = entity.organizationCode
      ..schoolCode = entity.schoolCode;
  }

  UnreadEntity toEntity() {
    return UnreadEntity(
      conversationCode: conversationCode,
      conversationType: ConversationType.fromApiString(conversationType),
      unreadCount: unreadCount,
      lastUnreadMessageCode: lastUnreadMessageCode,
      lastUnreadAt: lastUnreadAt,
      updatedAt: updatedAt,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
