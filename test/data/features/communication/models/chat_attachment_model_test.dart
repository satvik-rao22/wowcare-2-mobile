import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/message_model.dart';

/// Characterisation test (Mandate 8) for [ChatAttachmentModel]. `oldAtt` is a
/// verbatim copy of the pre-conversion hand-written `fromJson`; the generated
/// parser must match it field-for-field across both key spellings (the
/// messaging-service inline shape and the local upload-pipeline shape), and
/// `toJson` must emit an identical map.
ChatAttachmentModel oldAtt(Map<String, dynamic> json) {
  final rawId = json['attachmentId'] ?? json['id'];
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

void expectSame(ChatAttachmentModel a, ChatAttachmentModel b) {
  expect(b.name, a.name);
  expect(b.type, a.type);
  expect(b.sizeBytes, a.sizeBytes);
  expect(b.mimeType, a.mimeType);
  expect(b.remoteUrl, a.remoteUrl);
  expect(b.localPath, a.localPath);
  expect(b.code, a.code);
  expect(b.attachmentId, a.attachmentId);
  expect(b.toJson(), a.toJson());
}

void main() {
  group('ChatAttachmentModel — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty': {},
      'snake-case (local upload shape)': {
        'name': 'doc.pdf',
        'type': 'document',
        'size_bytes': 2048,
        'mime_type': 'application/pdf',
        'remote_url': 'https://x/doc.pdf',
        'local_path': '/tmp/doc.pdf',
        'code': 'AST_1',
        'attachmentId': 7,
      },
      'service inline shape (camel + alt keys)': {
        'originalFilename': 'photo.jpg',
        'attachmentType': 'image',
        'fileSize': 4096,
        'mimeType': 'image/jpeg',
        'fileUrl': 'https://x/photo.jpg',
        'assetCode': 'AST_2',
        'id': 99,
      },
      'thumbnailUrl fallback for remote': {
        'name': 'v.mp4',
        'thumbnailUrl': 'https://x/thumb.jpg',
      },
      'attachmentId as string': {'name': 'a', 'attachmentId': '42'},
      'attachmentId absent': {'name': 'a'},
      'attachmentId unparseable string': {'name': 'a', 'id': 'abc'},
    };

    fixtures.forEach((name, json) {
      test(name, () {
        expectSame(oldAtt(json), ChatAttachmentModel.fromJson(json));
      });
    });

    test('round-trips through the entity', () {
      final m = ChatAttachmentModel.fromJson(const {
        'name': 'doc.pdf',
        'size_bytes': 10,
        'attachmentId': 3,
        'code': 'AST',
      });
      final back = ChatAttachmentModel.fromEntity(m.toEntity());
      expect(back.toJson(), m.toJson());
    });
  });
}
