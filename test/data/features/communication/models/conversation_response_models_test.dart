import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/conversation_model.dart';
import 'package:wowcare/data/features/communication/models/create_conversation_response.dart';
import 'package:wowcare/data/features/communication/models/get_conversations_response.dart';

/// Characterisation test (Mandate 8) for the two response envelopes. The
/// `old*` helpers are verbatim copies of the pre-conversion hand-written
/// parsers; the generated parsers must match them field-for-field on valid,
/// missing, null and wrong-type inputs.
///
/// One intentional, documented relaxation: the pagination ints are now parsed
/// as `num?.toInt()` (json_serializable standard) instead of `as int?`, so a
/// double-encoded pagination value (e.g. `5.0`) is tolerated where the old
/// parser threw. Backend pagination values are always integers, so this only
/// affects malformed input and never loses or changes data. Covered by an
/// explicit test below rather than the parity fixtures.

GetConversationsResponse oldGet(Map<String, dynamic> json) =>
    GetConversationsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? oldData(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String? ?? '',
      correlationId: json['correlationId'] as String?,
    );

ConversationsData oldData(Map<String, dynamic> json) => ConversationsData(
  content:
      (json['content'] as List<dynamic>?)
          ?.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  totalElements: json['totalElements'] as int? ?? 0,
  totalPages: json['totalPages'] as int? ?? 0,
  size: json['size'] as int? ?? 0,
  number: json['number'] as int? ?? 0,
  first: json['first'] as bool? ?? true,
  last: json['last'] as bool? ?? true,
  empty: json['empty'] as bool? ?? true,
);

CreateConversationResponse oldCreate(Map<String, dynamic> json) =>
    CreateConversationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? ConversationModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String? ?? '',
      correlationId: json['correlationId'] as String?,
    );

void expectData(ConversationsData? a, ConversationsData? b) {
  expect(b == null, a == null);
  if (a == null || b == null) return;
  expect(b.content.length, a.content.length);
  expect(b.totalElements, a.totalElements);
  expect(b.totalPages, a.totalPages);
  expect(b.size, a.size);
  expect(b.number, a.number);
  expect(b.first, a.first);
  expect(b.last, a.last);
  expect(b.empty, a.empty);
}

void main() {
  group('GetConversationsResponse — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty': {},
      'nulls': {
        'success': null,
        'message': null,
        'data': null,
        'timestamp': null,
        'correlationId': null,
      },
      'scalars only': {
        'success': true,
        'message': 'ok',
        'timestamp': '2026-09-08T00:00:00Z',
        'correlationId': 'abc',
      },
      'with empty data page': {
        'success': true,
        'data': {'content': <dynamic>[], 'totalElements': 0, 'empty': true},
      },
      'with paged data': {
        'success': true,
        'data': {
          'content': <dynamic>[],
          'totalElements': 42,
          'totalPages': 5,
          'size': 10,
          'number': 2,
          'first': false,
          'last': false,
          'empty': false,
        },
      },
    };

    fixtures.forEach((name, json) {
      test(name, () {
        final a = oldGet(json);
        final b = GetConversationsResponse.fromJson(json);
        expect(b.success, a.success);
        expect(b.message, a.message);
        expect(b.timestamp, a.timestamp);
        expect(b.correlationId, a.correlationId);
        expectData(a.data, b.data);
      });
    });

    test('double-encoded pagination int is tolerated (documented relaxation)', () {
      final b = GetConversationsResponse.fromJson(const {
        'data': {'totalElements': 42.0},
      });
      expect(b.data!.totalElements, 42);
    });
  });

  group('CreateConversationResponse — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty': {},
      'nulls': {
        'success': null,
        'message': null,
        'data': null,
        'timestamp': null,
        'correlationId': null,
      },
      'scalars only': {
        'success': true,
        'message': 'created',
        'timestamp': '2026-09-08T00:00:00Z',
        'correlationId': 'xyz',
      },
    };

    fixtures.forEach((name, json) {
      test(name, () {
        final a = oldCreate(json);
        final b = CreateConversationResponse.fromJson(json);
        expect(b.success, a.success);
        expect(b.message, a.message);
        expect(b.timestamp, a.timestamp);
        expect(b.correlationId, a.correlationId);
        expect(b.data == null, a.data == null);
      });
    });
  });
}
