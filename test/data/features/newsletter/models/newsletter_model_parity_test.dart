// Characterisation test for the Mandate 8 conversion of the STUDENT
// newsletter models (`newsletter_model.dart` + its three leaf models).
//
// Each `_legacy*` function below is the hand-written `fromJson` body copied
// VERBATIM from the pre-conversion source. Every fixture is fed through both
// the legacy parser and the generated one and the results compared with `==`
// (Equatable, so field-for-field). This is the safety net §8 asks for before
// a hand-written parser is deleted — not coverage.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_attachment_model.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_component_model.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_model.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_recipient_model.dart';

// ── LEGACY PARSERS (verbatim from the deleted hand-written factories) ───────

NewsletterRecipientModel _legacyRecipient(Map<String, dynamic> json) =>
    NewsletterRecipientModel(
      id: json['id'] as int?,
      code: (json['code'] ?? '').toString().trim(),
      userCode: (json['userCode'] ?? '').toString().trim(),
      userName: (json['userName'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString().trim(),
    );

NewsletterAttachmentModel _legacyAttachment(Map<String, dynamic> json) =>
    NewsletterAttachmentModel(
      id: json['id'] as int?,
      code: (json['code'] ?? json['mediaCode'] ?? json['assetCode'] ?? '')
          .toString()
          .trim(),
      name: (json['name'] ?? json['fileName'] ?? '').toString().trim(),
      url: (json['url'] ??
              json['assetUrl'] ??
              json['downloadUrl'] ??
              json['fileUrl'] ??
              json['publicUrl'] ??
              '')
          .toString()
          .trim(),
      mimeType:
          (json['mimeType'] ?? json['contentType'] ?? '').toString().trim(),
      sizeBytes: json['sizeBytes'] as int? ?? json['size'] as int?,
    );

NewsletterComponentModel _legacyComponent(Map<String, dynamic> json) {
  final rawData = json['data'];
  Map<String, dynamic> data = rawData is Map<String, dynamic>
      ? rawData
      : rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

  if (data.isEmpty) {
    final contentJson = json['contentJson'];
    if (contentJson is String && contentJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(contentJson);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
  }

  return NewsletterComponentModel(
    id: json['id'] as int?,
    type: (json['type'] ?? json['componentType'] ?? '').toString().trim(),
    data: data,
    order: json['order'] as int? ?? json['sortOrder'] as int?,
  );
}

NewsletterModel _legacyNewsletter(Map<String, dynamic> json) {
  final componentsJson = json['components'];
  final attachmentsJson = json['attachments'];
  final recipientsJson = json['recipients'];

  return NewsletterModel(
    id: json['id'] as int?,
    code: (json['code'] ?? '').toString().trim(),
    organizationCode: (json['organizationCode'] ?? '').toString().trim(),
    schoolCode: (json['schoolCode'] ?? '').toString().trim(),
    title: (json['title'] ?? '').toString().trim(),
    subtitle: (json['subtitle'] ?? '').toString().trim(),
    layoutJson: (json['layoutJson'] ?? '').toString(),
    backgroundPattern: (json['backgroundPattern'] ?? '').toString().trim(),
    colorTheme: (json['colorTheme'] ?? '').toString().trim(),
    assetCode: (json['assetCode'] as String?)?.trim(),
    status: (json['status'] ?? '').toString().trim(),
    createdBy: (json['createdBy'] ?? '').toString().trim(),
    createdByName: (json['createdByName'] ?? '').toString().trim(),
    createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    components: componentsJson is List
        ? componentsJson
            .whereType<Map>()
            .map((e) => _legacyComponent(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <NewsletterComponentModel>[],
    attachments: attachmentsJson is List
        ? attachmentsJson
            .whereType<Map>()
            .map((e) => _legacyAttachment(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <NewsletterAttachmentModel>[],
    recipients: recipientsJson is List
        ? recipientsJson
            .whereType<Map>()
            .map((e) => _legacyRecipient(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <NewsletterRecipientModel>[],
    recipientCount: json['recipientCount'] as int? ??
        (json['recipients'] is List ? (json['recipients'] as List).length : 0),
  );
}

void main() {
  group('NewsletterRecipientModel', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'code': ' C1 ', 'userCode': 'U1', 'userName': 'A', 'status': 'S'},
      <String, dynamic>{},
      {'id': null, 'code': null, 'userCode': null, 'userName': null},
      {'code': '', 'userName': '   '},
      {'id': 2, 'userName': 42},
    ]) {
      test('parity: $f', () {
        expect(NewsletterRecipientModel.fromJson(f), _legacyRecipient(f));
      });
    }
  });

  group('NewsletterAttachmentModel', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'code': 'C', 'name': 'N', 'url': 'U', 'mimeType': 'M', 'sizeBytes': 9},
      // every alias falls through to the next key
      {'mediaCode': ' MC ', 'fileName': 'FN', 'assetUrl': 'AU', 'contentType': 'CT', 'size': 5},
      {'assetCode': 'AC', 'downloadUrl': 'DU'},
      {'fileUrl': 'FU'},
      {'publicUrl': 'PU'},
      // present-but-empty must WIN over a later alias with content
      {'code': '', 'mediaCode': 'ignored', 'url': '', 'assetUrl': 'ignored'},
      <String, dynamic>{},
      {'id': null, 'sizeBytes': null, 'size': null},
    ]) {
      test('parity: $f', () {
        expect(NewsletterAttachmentModel.fromJson(f), _legacyAttachment(f));
      });
    }
  });

  group('NewsletterComponentModel', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'type': 'TEXT', 'data': {'parts': []}, 'order': 2},
      {'componentType': ' IMAGE ', 'sortOrder': 3},
      // data absent -> decoded out of contentJson
      {'contentJson': '{"parts":[{"type":"TEXT","text":"hi"}]}'},
      // data present but EMPTY -> still falls back to contentJson
      {'data': <String, dynamic>{}, 'contentJson': '{"a":1}'},
      // unparseable contentJson must yield {} and never throw
      {'contentJson': 'not json at all'},
      // contentJson decodes to a non-map -> ignored
      {'contentJson': '[1,2,3]'},
      {'contentJson': '   '},
      {'data': 'not a map'},
      <String, dynamic>{},
    ]) {
      test('parity: $f', () {
        expect(NewsletterComponentModel.fromJson(f), _legacyComponent(f));
      });
    }
  });

  group('NewsletterModel', () {
    final fixtures = <Map<String, dynamic>>[
      {
        'id': 7,
        'code': ' NL_1 ',
        'organizationCode': 'ORG',
        'schoolCode': 'SCH',
        'title': ' T ',
        'subtitle': ' S ',
        'layoutJson': '  [] ',
        'backgroundPattern': ' plain ',
        'colorTheme': ' ocean ',
        'assetCode': ' AST_1 ',
        'status': ' SENT ',
        'createdBy': 'me',
        'createdByName': 'Me',
        'createdAt': '2024-01-02T03:04:05Z',
        'updatedAt': '2024-02-03T04:05:06Z',
        'components': [
          {'id': 1, 'type': 'TEXT', 'data': {'parts': []}, 'order': 1},
        ],
        'attachments': [
          {'code': 'A1', 'url': 'u'},
        ],
        'recipients': [
          {'code': 'R1', 'userName': 'Kid'},
        ],
        'recipientCount': 3,
      },
      // everything missing
      <String, dynamic>{},
      // recipientCount absent -> length of recipients
      {
        'recipients': [
          {'code': 'R1'},
          {'code': 'R2'},
        ],
      },
      // recipients absent entirely -> 0
      {'title': 'x'},
      // lists containing junk entries must be SKIPPED, not throw
      {
        'components': [1, 'two', null, {'type': 'TEXT'}],
        'attachments': ['nope', {'code': 'A'}],
        'recipients': [null, {'code': 'R'}],
      },
      // lists that are not lists at all
      {'components': 'nope', 'attachments': 42, 'recipients': <String, dynamic>{}},
      // unparseable / empty dates
      {'createdAt': 'not a date', 'updatedAt': ''},
      {'createdAt': null, 'updatedAt': null},
      // layoutJson must NOT be trimmed
      {'layoutJson': '  <p>hi</p>  '},
      // nulls everywhere
      {
        'code': null,
        'title': null,
        'assetCode': null,
        'colorTheme': null,
        'recipientCount': null,
      },
    ];
    for (var i = 0; i < fixtures.length; i++) {
      test('parity: fixture $i', () {
        final f = fixtures[i];
        expect(NewsletterModel.fromJson(f), _legacyNewsletter(f));
      });
    }

    test('layoutJson is preserved untrimmed', () {
      final m = NewsletterModel.fromJson({'layoutJson': '  <p>hi</p>  '});
      expect(m.layoutJson, '  <p>hi</p>  ');
    });

    test('toJson round-trips back to an equal model', () {
      final f = fixtures.first;
      final m = NewsletterModel.fromJson(f);
      expect(NewsletterModel.fromJson(m.toJson()), m);
    });
  });
}
