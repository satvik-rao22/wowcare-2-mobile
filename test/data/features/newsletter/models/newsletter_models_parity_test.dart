// Characterisation test for the Mandate 8 conversion of the SENT (staff/admin)
// newsletter models in `newsletter_models.dart`.
//
// Each `_legacy*` function is the hand-written `fromJson` body copied VERBATIM
// from the pre-conversion source, and every fixture is compared field-for-field
// against the generated parser.
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_api_envelope.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';

// ── LEGACY PARSERS ─────────────────────────────────────────────────────────

NewsletterComponentModel _legacyComponent(Map<String, dynamic> json) =>
    NewsletterComponentModel(
      id: json['id'] as int? ?? 0,
      componentType: (json['componentType'] as String? ?? '').trim(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      contentJson: (json['contentJson'] as String? ?? '').trim(),
    );

NewsletterAttachmentModel _legacyAttachment(Map<String, dynamic> json) {
  final mediaCode =
      (json['mediaCode'] ?? json['assetCode'] ?? '').toString().trim();
  final assetUrl = (json['assetUrl'] ??
          json['url'] ??
          json['downloadUrl'] ??
          json['fileUrl'] ??
          json['publicUrl'] ??
          '')
      .toString()
      .trim();
  return NewsletterAttachmentModel(
    id: json['id'] as int? ?? 0,
    mediaCode: mediaCode,
    fileName: (json['fileName'] as String? ?? '').trim(),
    mimeType: (json['mimeType'] as String? ?? '').trim(),
    fileSize: json['fileSize'] as int? ?? 0,
    sortOrder: json['sortOrder'] as int? ?? 0,
    assetUrl: assetUrl,
  );
}

NewsletterRecipientModel _legacyRecipient(Map<String, dynamic> json) {
  final firstName = (json['firstName'] ?? '').toString().trim();
  final lastName = (json['lastName'] ?? '').toString().trim();
  final composedName = <String>[firstName, lastName]
      .where((String part) => part.isNotEmpty)
      .join(' ');
  return NewsletterRecipientModel(
    id: json['id'] as int? ?? 0,
    classroomCode: (json['classroomCode'] as String? ?? '').trim(),
    studentCode:
        (json['studentCode'] ?? json['userCode'] ?? '').toString().trim(),
    userName: (json['userName'] ??
            json['studentName'] ??
            json['recipientName'] ??
            json['guardianName'] ??
            json['name'] ??
            composedName)
        .toString()
        .trim(),
  );
}

String _legacySummary(List<NewsletterComponentModel> components) {
  for (final component in components) {
    final text = component.plainText.trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

NewsletterModel _legacyNewsletter(Map<String, dynamic> json) {
  final recipientsJson = json['recipients'] as List<dynamic>? ?? const [];
  final componentsJson = json['components'] as List<dynamic>? ?? const [];
  final attachmentsJson = json['attachments'] as List<dynamic>? ?? const [];

  final components = componentsJson
      .map((dynamic e) => _legacyComponent(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final subtitle = (json['subtitle'] as String? ?? '').trim();

  return NewsletterModel(
    id: json['id'] as int? ?? 0,
    code: (json['code'] as String? ?? '').trim(),
    organizationCode: (json['organizationCode'] as String? ?? '').trim(),
    schoolCode: (json['schoolCode'] as String? ?? '').trim(),
    title: (json['title'] as String? ?? '').trim(),
    subtitle: subtitle.isNotEmpty ? subtitle : _legacySummary(components),
    layoutJson: (json['layoutJson'] as String? ?? '').trim(),
    colorTheme: (json['colorTheme'] as String? ?? '').trim(),
    backgroundPattern: (json['backgroundPattern'] as String? ?? 'plain').trim(),
    status: (json['status'] as String? ?? '').trim(),
    scheduledAt: _legacyDate(json['scheduledAt']),
    sentAt: _legacyDate(json['sentAt']),
    createdAt: _legacyDate(json['createdAt']),
    recipientCount: json['recipientCount'] as int? ?? 0,
    createdBy: (json['createdBy'] as String? ?? '').trim(),
    createdByName: (json['createdByName'] as String? ?? '').trim(),
    recipients: recipientsJson
        .map((dynamic e) => _legacyRecipient(e as Map<String, dynamic>))
        .toList(),
    components: components,
    attachments: attachmentsJson
        .map((dynamic e) => _legacyAttachment(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );
}

DateTime? _legacyDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

void main() {
  group('NewsletterComponentModel (sent)', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'componentType': ' TEXT ', 'sortOrder': 2, 'contentJson': ' {} '},
      <String, dynamic>{},
      {'id': null, 'componentType': null, 'sortOrder': null, 'contentJson': null},
    ]) {
      test('parity: $f', () {
        expect(NewsletterComponentModel.fromJson(f), _legacyComponent(f));
      });
    }
  });

  group('NewsletterAttachmentModel (sent)', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'mediaCode': 'M', 'fileName': 'F', 'mimeType': 'T', 'fileSize': 3, 'sortOrder': 1, 'assetUrl': 'U'},
      {'assetCode': ' AC '},
      {'url': 'u1'},
      {'downloadUrl': 'd'},
      {'fileUrl': 'f'},
      {'publicUrl': 'p'},
      // present-but-empty wins over a later alias
      {'mediaCode': '', 'assetCode': 'ignored', 'assetUrl': '', 'url': 'ignored'},
      <String, dynamic>{},
    ]) {
      test('parity: $f', () {
        expect(NewsletterAttachmentModel.fromJson(f), _legacyAttachment(f));
      });
    }
  });

  group('NewsletterRecipientModel (sent)', () {
    for (final f in <Map<String, dynamic>>[
      {'id': 1, 'classroomCode': 'C', 'studentCode': 'S', 'userName': 'N'},
      {'userCode': ' UC '},
      {'studentName': 'SN'},
      {'recipientName': 'RN'},
      {'guardianName': 'GN'},
      {'name': 'NM'},
      // composed from first + last when every alias is absent
      {'firstName': ' Ada ', 'lastName': ' Lovelace '},
      {'firstName': 'OnlyFirst'},
      {'lastName': 'OnlyLast'},
      // an explicit empty userName must WIN over the composed fallback
      {'userName': '', 'firstName': 'Ada', 'lastName': 'Lovelace'},
      <String, dynamic>{},
    ]) {
      test('parity: $f', () {
        expect(NewsletterRecipientModel.fromJson(f), _legacyRecipient(f));
      });
    }
  });

  group('NewsletterModel (sent)', () {
    final fixtures = <Map<String, dynamic>>[
      {
        'id': 1, 'code': ' N1 ', 'organizationCode': 'O', 'schoolCode': 'S',
        'title': ' T ', 'subtitle': ' Sub ', 'layoutJson': ' [] ',
        'colorTheme': ' ocean ', 'backgroundPattern': ' dots ', 'status': ' SENT ',
        'scheduledAt': '2024-01-01T00:00:00Z', 'sentAt': '2024-01-02T00:00:00Z',
        'createdAt': '2024-01-03T00:00:00Z', 'recipientCount': 2,
        'createdBy': 'u', 'createdByName': 'U',
        'recipients': [{'classroomCode': 'C1', 'userName': 'A'}],
        'components': [
          {'id': 2, 'componentType': 'TEXT', 'sortOrder': 9, 'contentJson': '{"text":"second"}'},
          {'id': 1, 'componentType': 'TEXT', 'sortOrder': 1, 'contentJson': '{"text":"first"}'},
        ],
        'attachments': [
          {'mediaCode': 'B', 'sortOrder': 5},
          {'mediaCode': 'A', 'sortOrder': 1},
        ],
      },
      <String, dynamic>{},
      // subtitle blank -> derived from the FIRST component after sorting
      {
        'subtitle': '   ',
        'components': [
          {'componentType': 'TEXT', 'sortOrder': 9, 'contentJson': '{"text":"later"}'},
          {'componentType': 'TEXT', 'sortOrder': 1, 'contentJson': '{"text":"earlier"}'},
        ],
      },
      // subtitle blank and no components -> stays blank
      {'subtitle': ''},
      // backgroundPattern default
      {'title': 'x'},
      {'backgroundPattern': null},
      {'backgroundPattern': '  spots  '},
      // dates
      {'sentAt': 'garbage', 'createdAt': '', 'scheduledAt': null},
      // empty lists
      {'recipients': [], 'components': [], 'attachments': []},
    ];
    for (var i = 0; i < fixtures.length; i++) {
      test('parity: fixture $i', () {
        final f = fixtures[i];
        expect(NewsletterModel.fromJson(f), _legacyNewsletter(f));
      });
    }

    test('components and attachments come back sorted by sortOrder', () {
      final m = NewsletterModel.fromJson(fixtures.first);
      expect(m.components.map((e) => e.sortOrder), [1, 9]);
      expect(m.attachments.map((e) => e.sortOrder), [1, 5]);
    });

    test('derived subtitle uses the first component after sorting', () {
      expect(NewsletterModel.fromJson(fixtures[2]).subtitle, 'earlier');
    });

    test('toJson round-trips back to an equal model', () {
      final m = NewsletterModel.fromJson(fixtures.first);
      expect(NewsletterModel.fromJson(m.toJson()), m);
    });
  });

  group('NewsletterPageModel', () {
    NewsletterPageModel fromApi(Map<String, dynamic> body) =>
        NewsletterPageModel.fromApiResponse(
          NewsletterApiEnvelope.fromJson(body),
        );

    test('fromApiResponse unwraps the envelope and derives hasMore', () {
      final page = fromApi({
        'success': true,
        'data': {
          'content': [
            {'code': 'A'},
            {'code': 'B'},
          ],
          'number': 0,
          'size': 2,
          'totalPages': 3,
          'totalElements': 6,
        },
      });
      expect(page.items.length, 2);
      expect(page.page, 0);
      expect(page.hasMore, isTrue);
    });

    test('falls back to pageable when number/size are absent', () {
      final page = fromApi({
        'data': {
          'content': <dynamic>[],
          'pageable': {'pageNumber': 2, 'pageSize': 10},
          'totalPages': 3,
        },
      });
      expect(page.page, 2);
      expect(page.size, 10);
      // page 2 of 3 (zero-based) is the LAST page: 2 + 1 < 3 is false.
      expect(page.hasMore, isFalse);
    });

    test('derives hasMore from totals when totalPages is 0', () {
      final page = fromApi({
        'data': {
          'content': [
            {'code': 'A'},
          ],
          'number': 0,
          'size': 1,
          'totalPages': 0,
          'totalElements': 5,
        },
      });
      expect(page.hasMore, isTrue);
    });

    test('survives a missing / non-map data envelope', () {
      expect(fromApi(<String, dynamic>{}).items, isEmpty);
      expect(fromApi({'data': 'nope'}).items, isEmpty);
    });

    test('the cache shape round-trips through toJson/fromJson', () {
      final original = fromApi({
        'data': {
          'content': [
            {'code': 'A', 'title': 'T'},
          ],
          'number': 1,
          'size': 1,
          'totalPages': 4,
          'totalElements': 4,
        },
      });
      expect(NewsletterPageModel.fromJson(original.toJson()), original);
    });
  });

  group('NewsletterApiEnvelope', () {
    test('non-map bodies yield null rather than throwing', () {
      expect(NewsletterApiEnvelope.tryFrom(null), isNull);
      expect(NewsletterApiEnvelope.tryFrom('a string'), isNull);
      expect(NewsletterApiEnvelope.tryFrom(<dynamic>[]), isNull);
    });

    test('success defaults to false when the key is absent', () {
      expect(NewsletterApiEnvelope.fromJson(<String, dynamic>{}).success,
          isFalse);
    });

    test('dataAsMap is null when data is absent or not an object', () {
      expect(NewsletterApiEnvelope.fromJson(<String, dynamic>{}).dataAsMap,
          isNull);
      expect(NewsletterApiEnvelope.fromJson({'data': 5}).dataAsMap, isNull);
      expect(
        NewsletterApiEnvelope.fromJson({
          'data': {'a': 1},
        }).dataAsMap,
        {'a': 1},
      );
    });
  });
}
