import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/data/features/communication/models/message_entity_dto.dart';

/// Characterisation test (Mandate 8) for the two message sub-DTOs converted to
/// `json_serializable` — [AttachmentEntityDto] and [ReactionDto]. The `old*`
/// helpers are verbatim copies of the pre-conversion parsers; the generated
/// parsers must match field-for-field and emit an identical `toJson`.
/// (`MessageEntityDto` and `ReadReceiptEntityDto` remain hand-written — see
/// scope notes in the model file — and are covered by the existing
/// message_entity_dto_test.dart.)

AttachmentEntityDto oldAtt(Map<String, dynamic> json) {
  final rawId = json['attachmentId'] ?? json['id'];
  return AttachmentEntityDto(
    code: json['code'] as String? ?? '',
    messageCode: json['messageCode'] as String? ?? '',
    conversationCode: json['conversationCode'] as String? ?? '',
    fileName: json['fileName'] as String? ?? '',
    fileUrl: json['fileUrl'] as String? ?? '',
    mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
    fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    uploadedBy: json['uploadedBy'] as String? ?? '',
    uploadedAt: DateTime.parse(
      json['uploadedAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
    ),
    attachmentId: rawId is int ? rawId : int.tryParse('$rawId'),
  );
}

ReactionDto oldReaction(Map<String, dynamic> json) => ReactionDto(
  messageCode: json['messageCode'] as String? ?? '',
  userCode: json['userCode'] as String? ?? '',
  userName: json['userName'] as String? ?? '',
  emoji: json['emoji'] as String? ?? '',
  createdAt: DateTime.parse(
    json['createdAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
  ),
  role: (json['role'] ?? json['userRole'])?.toString(),
);

void main() {
  const uploadedAt = '2026-01-01T00:00:00.000Z';

  group('AttachmentEntityDto — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty': {'uploadedAt': uploadedAt},
      'full': {
        'code': 'AST',
        'messageCode': 'MSG',
        'conversationCode': 'CONV',
        'fileName': 'doc.pdf',
        'fileUrl': 'https://x/doc.pdf',
        'mimeType': 'application/pdf',
        'fileSizeBytes': 2048,
        'thumbnailUrl': 'https://x/thumb.jpg',
        'uploadedBy': 'STF1',
        'uploadedAt': uploadedAt,
        'attachmentId': 7,
      },
      'attachmentId via id, string form': {
        'uploadedAt': uploadedAt,
        'id': '42',
      },
      'attachmentId unparseable': {'uploadedAt': uploadedAt, 'id': 'zzz'},
    };

    fixtures.forEach((name, json) {
      test(name, () {
        final a = oldAtt(json);
        final b = AttachmentEntityDto.fromJson(json);
        expect(b.toJson(), a.toJson());
        expect(b.attachmentId, a.attachmentId);
        expect(b.mimeType, a.mimeType);
        expect(b.toEntity().attachmentType, a.toEntity().attachmentType);
      });
    });
  });

  group('ReactionDto — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty': {'createdAt': uploadedAt},
      'full with role': {
        'messageCode': 'MSG',
        'userCode': 'U1',
        'userName': 'Ava',
        'emoji': '👍',
        'createdAt': uploadedAt,
        'role': 'STAFF',
      },
      'role via userRole': {'createdAt': uploadedAt, 'userRole': 'GUARDIAN'},
    };

    fixtures.forEach((name, json) {
      test(name, () {
        final a = oldReaction(json);
        final b = ReactionDto.fromJson(json);
        expect(b.toJson(), a.toJson());
        expect(b.role, a.role);
      });
    });
  });
}
