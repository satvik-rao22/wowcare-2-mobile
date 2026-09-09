import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';

/// Parses the message list / receipts endpoint's `receipts` array
/// (per-recipient-per-persona `{userCode, userName, userRole, deliveredAt,
/// readAt}`, confirmed against a live payload from
/// `GET .../messages/{code}/receipts`) into [RecipientStatus] entries.
///
/// A dual-role account (e.g. staff who is also a guardian) gets ONE ROW PER
/// PERSONA here, sharing one `userCode` but with different `role`/`userName`
/// and independent delivered/read state — e.g. delivered-only as ADMIN and
/// separately read as GUARDIAN. Each row is therefore classified purely by
/// its OWN `readAt`/`deliveredAt`, never cross-referenced against other rows
/// for the same `userCode` — doing so previously suppressed one persona's
/// receipt whenever the other persona's had already been read.
///
/// [onlyRead] selects [Message.readBy] (readAt present) vs
/// [Message.deliveredTo] (delivered but NOT YET read by THIS row — a row
/// that progressed to read surfaces only via the onlyRead:true call, so the
/// two lists never overlap).
List<RecipientStatus> parseRecipientStatuses(
  dynamic receipts, {
  required bool onlyRead,
}) {
  if (receipts is! List) return const [];
  final result = <RecipientStatus>[];
  for (final r in receipts) {
    if (r is! Map) continue;
    final userCode = (r['userCode'] ?? '').toString().trim();
    if (userCode.isEmpty) continue;
    final deliveredAt = r['deliveredAt'] != null
        ? DateTime.tryParse(r['deliveredAt'].toString())
        : null;
    final readAt = r['readAt'] != null
        ? DateTime.tryParse(r['readAt'].toString())
        : null;
    // The receipt row carries the recipient's role and display name
    // directly — the authoritative persona they were acting as, no
    // participant-list guessing needed.
    final role = (r['role'] ?? r['userRole'])?.toString();
    final name = (r['userName'] ?? '').toString().trim();
    if (onlyRead) {
      if (readAt == null) continue;
      result.add(
        RecipientStatusModel(
          name: name,
          userId: userCode,
          timestamp: readAt,
          role: role,
        ),
      );
    } else {
      if (readAt != null) continue;
      if (deliveredAt == null) continue;
      result.add(
        RecipientStatusModel(
          name: name,
          userId: userCode,
          timestamp: deliveredAt,
          role: role,
        ),
      );
    }
  }
  return result;
}

class MessageModel extends Message {
  final String? conversationCode;
  final String senderUserCode;

  const MessageModel({
    required super.id,
    required super.code,
    required super.text,
    required super.isSentByMe,
    required super.time,
    this.conversationCode,
    required this.senderUserCode,
    super.deliveredAt,
    super.readAt,
    super.editedAt,
    super.deletedAt,
    super.deliveredTo,
    super.readBy,
    super.reactions,
    super.quotedMessageId,
    super.attachments,
    super.senderName,
    super.receivers,
    super.senderRole,
    super.isPrivate = false,
    super.privateParentUserCode,
  }) : super(senderUserCode: senderUserCode);

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderCode =
        (json['senderUserCode'] as String? ??
                json['senderCode'] as String? ??
                '')
            .trim();
    final normalizedUserId = currentUserId?.trim();
    final isMine =
        normalizedUserId != null &&
        normalizedUserId.isNotEmpty &&
        senderCode.isNotEmpty &&
        senderCode == normalizedUserId;

    AppLogger.d(
      '[CHAT OWNERSHIP] fromJson\n'
      '  messageId      = ${json['id']}\n'
      '  code           = ${json['code']}\n'
      '  senderUserCode = $senderCode\n'
      '  currentUserId  = $normalizedUserId\n'
      '  isMine         = $isMine',
    );

    return MessageModel(
      id: (json['id'] ?? '').toString(),
      code: json['code'] as String? ?? '',
      conversationCode:
          json['conversationCode'] as String? ??
          json['conversation_code'] as String?,
      senderUserCode: senderCode,
      text: json['content'] as String? ?? '',
      isSentByMe: isMine,
      time: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : AppTime.nowUtc(),
      deliveredAt: json['status'] == 'DELIVERED' || json['status'] == 'READ'
          ? AppTime.nowUtc()
          : null,
      readAt: json['status'] == 'READ' ? AppTime.nowUtc() : null,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      // Real per-recipient delivered/read state — confirmed against a live
      // payload at GET .../messages/conversation/{code}: `receipts`, an
      // array of {userCode, deliveredAt, readAt}. This was previously
      // ignored entirely (deliveredTo/readBy hardcoded to `const []`), so
      // ticks/message-info for group chats (Room Chat, Staff Direct — the
      // legacy stack this model backs) only ever reflected the message's
      // own coarse top-level `status`, which the backend doesn't actually
      // update per-recipient — group ticks stayed stuck on "sent" even once
      // everyone had read it.
      deliveredTo: parseRecipientStatuses(json['receipts'], onlyRead: false),
      readBy: parseRecipientStatuses(json['receipts'], onlyRead: true),
      reactions: [
        for (var r in (json['reactions'] as List<dynamic>?) ?? [])
          if (r is Map<String, dynamic> &&
              r['userCode'] != null &&
              r['emoji'] != null)
            ReactionEntry(
              userCode: r['userCode'].toString(),
              emoji: r['emoji'].toString(),
              // The reaction row carries the reactor's role and display
              // name directly — the authoritative persona they reacted as,
              // no participant-list guessing needed.
              role: (r['role'] ?? r['userRole'])?.toString(),
              userName: (r['userName'] as String?)?.trim(),
            ),
      ],
      quotedMessageId: (json['replyToMessageId'] ?? '').toString().isEmpty
          ? null
          : json['replyToMessageId'].toString(),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => ChatAttachmentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      senderName: (json['senderDisplayName'] as String?)?.isNotEmpty == true
          ? json['senderDisplayName'] as String
          : json['senderName'] as String?,
      // Which persona the sender was acting AS — see Message.senderRole.
      // The messaging service is only known to key this as `senderRole`;
      // `role` is a defensive fallback in case some endpoint variant uses
      // the same key the send request itself sends this under.
      senderRole: (json['senderRole'] as String?)?.trim().isNotEmpty == true
          ? (json['senderRole'] as String).trim()
          : (json['role'] as String?)?.trim(),
      receivers: const [],
      // Privacy is driven by the presence of privateParentUserCode (the backend
      // invariant is isPrivate = privateParentUserCode != null). ppc-presence
      // takes PRECEDENCE over the `isPrivate`/`private` booleans because the API
      // returns isPrivate=false even when ppc is set (mapper bug) — trusting the
      // boolean first lets web-sent private messages leak into the staff Group
      // tab instead of the owning parent's private tab.
      isPrivate:
          ((json['privateParentUserCode'] as String?)?.trim().isNotEmpty ??
              false) ||
          (json['isPrivate'] as bool? ?? false) ||
          (json['private'] as bool? ?? false),
      privateParentUserCode: json['privateParentUserCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'conversationCode': conversationCode,
      'senderUserCode': senderUserCode,
      'content': text,
      'time': time.toIso8601String(),
      'replyToMessageId': quotedMessageId,
      'attachments': attachments
          .map((e) => (e as ChatAttachmentModel).toJson())
          .toList(),
      'senderName': senderName,
      if (privateParentUserCode != null)
        'privateParentUserCode': privateParentUserCode,
    };
  }
}

class RecipientStatusModel extends RecipientStatus {
  const RecipientStatusModel({
    required super.name,
    super.userId,
    super.timestamp,
    super.role,
  });

  factory RecipientStatusModel.fromJson(Map<String, dynamic> json) {
    return RecipientStatusModel(
      name: json['name'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      role: (json['role'] ?? json['userRole'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_id': userId,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class ChatAttachmentModel extends ChatAttachment {
  const ChatAttachmentModel({
    required super.name,
    required super.type,
    required super.sizeBytes,
    required super.mimeType,
    required super.remoteUrl,
    super.localPath,
    super.code,
    super.attachmentId,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['attachmentId'] ?? json['id'];
    // The messaging service's own attachment row (returned inline with each
    // message — see GET .../messages/conversation/{code}) uses a different
    // shape than the local upload-pipeline model below: `originalFilename`,
    // `attachmentType`, `fileSize`, `assetCode`, and a `fileUrl`/
    // `thumbnailUrl` that is null until the document service finishes
    // resolving it (see AttachmentUrlResolver for that resolution step).
    return ChatAttachmentModel(
      name: (json['name'] ?? json['originalFilename']) as String? ?? '',
      type: (json['type'] ?? json['attachmentType']) as String? ?? '',
      sizeBytes:
          (json['size_bytes'] ?? json['sizeBytes'] ?? json['fileSize'])
              as int? ??
          0,
      mimeType: (json['mime_type'] ?? json['mimeType']) as String? ?? '',
      remoteUrl:
          (json['remote_url'] ??
                  json['remoteUrl'] ??
                  json['fileUrl'] ??
                  json['thumbnailUrl'])
              as String? ??
          '',
      localPath: (json['local_path'] ?? json['localPath']) as String?,
      code: (json['code'] ?? json['assetCode']) as String?,
      attachmentId: rawId is int ? rawId : int.tryParse('$rawId'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size_bytes': sizeBytes,
      'mime_type': mimeType,
      'remote_url': remoteUrl,
      'local_path': localPath,
      'code': code,
      'attachmentId': attachmentId,
    };
  }
}
