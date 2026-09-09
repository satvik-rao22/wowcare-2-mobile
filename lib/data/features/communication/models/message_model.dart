import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';

part 'message_model.g.dart';

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

/// MANDATE 8 SCOPE NOTE — [MessageModel.fromJson] is intentionally NOT
/// converted to generated `json_serializable`. It is a mapper, not a
/// serializer: it takes a runtime `currentUserId` (json_serializable factories
/// accept only the map), derives `isSentByMe` from that param, derives
/// `deliveredAt`/`readAt` from the coarse top-level `status`, feeds the single
/// `receipts` key into TWO fields (`deliveredTo`/`readBy`) via
/// [parseRecipientStatuses], builds domain [ReactionEntry] objects inline, and
/// logs. None of that is expressible through `@JsonKey`. The model is still a
/// typed object at the boundary (no raw map leaves it), and it is constructed
/// directly at several datasource/repository sites as a [Message] subtype, so
/// it stays extending [Message]. Its `toJson` is currently unused (sendMessage
/// builds its body by hand) but retained for compilation/parity.
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
                (e) => ChatAttachmentModel.fromJson(
                  e as Map<String, dynamic>,
                ).toEntity(),
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
          .map((e) => ChatAttachmentModel.fromEntity(e).toJson())
          .toList(),
      'senderName': senderName,
      if (privateParentUserCode != null)
        'privateParentUserCode': privateParentUserCode,
    };
  }
}

/// MANDATE 8 SCOPE NOTE — kept hand-written. Its `fromJson` is dead code
/// ([parseRecipientStatuses] constructs it directly from receipt rows), and it
/// is built inline as a [RecipientStatus] subtype, so a standalone
/// `@JsonSerializable` conversion would break those direct constructions for
/// no serialisation benefit.
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

// ── ChatAttachment field-quirk readers (were inline aliases) ────────────────
// The messaging-service inline attachment row and the local upload-pipeline
// model use different key spellings for the same fields; each reader accepts
// every known spelling, preserving the previous parser's exact precedence and
// its `as int?` cast (which throws on a double `size`, unlike num.toInt()).

Object? _readAttName(Map<dynamic, dynamic> j, String k) =>
    (j['name'] ?? j['originalFilename']) as String? ?? '';
Object? _readAttType(Map<dynamic, dynamic> j, String k) =>
    (j['type'] ?? j['attachmentType']) as String? ?? '';
Object? _readAttSize(Map<dynamic, dynamic> j, String k) =>
    (j['size_bytes'] ?? j['sizeBytes'] ?? j['fileSize']) as int? ?? 0;
Object? _readAttMime(Map<dynamic, dynamic> j, String k) =>
    (j['mime_type'] ?? j['mimeType']) as String? ?? '';
Object? _readAttRemote(Map<dynamic, dynamic> j, String k) =>
    (j['remote_url'] ?? j['remoteUrl'] ?? j['fileUrl'] ?? j['thumbnailUrl'])
        as String? ??
    '';
Object? _readAttLocal(Map<dynamic, dynamic> j, String k) =>
    (j['local_path'] ?? j['localPath']) as String?;
Object? _readAttCode(Map<dynamic, dynamic> j, String k) =>
    (j['code'] ?? j['assetCode']) as String?;
Object? _readAttId(Map<dynamic, dynamic> j, String k) {
  final raw = j['attachmentId'] ?? j['id'];
  return raw is int ? raw : int.tryParse('$raw');
}

@JsonSerializable()
class ChatAttachmentModel {
  const ChatAttachmentModel({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.mimeType,
    required this.remoteUrl,
    this.localPath,
    this.code,
    this.attachmentId,
  });

  @JsonKey(readValue: _readAttName)
  final String name;
  @JsonKey(readValue: _readAttType)
  final String type;
  @JsonKey(name: 'size_bytes', readValue: _readAttSize)
  final int sizeBytes;
  @JsonKey(name: 'mime_type', readValue: _readAttMime)
  final String mimeType;
  @JsonKey(name: 'remote_url', readValue: _readAttRemote)
  final String remoteUrl;
  @JsonKey(name: 'local_path', readValue: _readAttLocal)
  final String? localPath;
  @JsonKey(readValue: _readAttCode)
  final String? code;
  @JsonKey(readValue: _readAttId)
  final int? attachmentId;

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$ChatAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatAttachmentModelToJson(this);

  factory ChatAttachmentModel.fromEntity(ChatAttachment e) =>
      ChatAttachmentModel(
        name: e.name,
        type: e.type,
        sizeBytes: e.sizeBytes,
        mimeType: e.mimeType,
        remoteUrl: e.remoteUrl,
        localPath: e.localPath,
        code: e.code,
        attachmentId: e.attachmentId,
      );

  ChatAttachment toEntity() => ChatAttachment(
    name: name,
    type: type,
    sizeBytes: sizeBytes,
    mimeType: mimeType,
    remoteUrl: remoteUrl,
    localPath: localPath,
    code: code,
    attachmentId: attachmentId,
  );
}
