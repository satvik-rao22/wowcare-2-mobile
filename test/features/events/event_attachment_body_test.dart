import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/event_models.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/event_upload_session.dart';

Event _event() => Event(
      code: 'EVT_1',
      type: EventType.classroom,
      name: 'Morning circle',
      date: DateTime(2026, 8, 3),
      allDay: false,
      startTime: '09:00',
      endTime: '09:30',
      description: 'Bring a hat',
      classrooms: const [EventAttendee(code: 'CLS_A', name: 'Bumblebees')],
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

void main() {
  group('createBody assetCodes', () {
    test('sends the ready asset codes when files were uploaded', () {
      final body = EventModel.createBody(
        _event(),
        assetCodes: const ['AST_1', 'AST_2'],
      );

      expect(body['attachmentAssetCodes'], ['AST_1', 'AST_2']);
    });

    test('omits the key entirely when there are no attachments', () {
      final body = EventModel.createBody(_event());

      // Omitted rather than sent empty, so an event with no attachments does
      // not look like a deliberate "clear".
      expect(body.containsKey('attachmentAssetCodes'), isFalse);
    });
  });

  group('updateBody assetCodes', () {
    test('full-replaces with the uploaded set', () {
      final body = EventModel.updateBody(
        _event(),
        assetCodes: const ['AST_9'],
      );

      expect(body['attachmentAssetCodes'], ['AST_9']);
    });

    test('omits the key when null so existing attachments survive', () {
      final body = EventModel.updateBody(_event());

      // The form cannot show what is already attached, so a save that staged no
      // files must leave the server's list alone.
      expect(body.containsKey('attachmentAssetCodes'), isFalse);
    });

    test('an explicit empty list is sent, clearing attachments', () {
      final body = EventModel.updateBody(_event(), assetCodes: const []);

      expect(body['attachmentAssetCodes'], isEmpty);
    });

    test('still drops type and audienceScope', () {
      final body = EventModel.updateBody(
        _event(),
        assetCodes: const ['AST_1'],
      );

      expect(body.containsKey('type'), isFalse);
      expect(body.containsKey('audienceScope'), isFalse);
      expect(body['attachmentAssetCodes'], ['AST_1']);
    });
  });

  group('uploadSession parsing', () {
    test('reads the session code and document base path', () {
      final session = EventModel.uploadSession(
        const {
          'success': true,
          'data': {
            'sessionCode': 'UPS_ABC',
            'sessionStatus': 'OPEN',
            'documentApiBasePath': '/document-ms/api/v1',
          },
        },
        fallbackDocumentBasePath: '/fallback',
      );

      expect(
        session,
        const EventUploadSession(
          sessionCode: 'UPS_ABC',
          documentApiBasePath: '/document-ms/api/v1',
        ),
      );
    });

    test('falls back when the response omits the base path', () {
      final session = EventModel.uploadSession(
        const {
          'data': {'sessionCode': 'UPS_ABC'},
        },
        fallbackDocumentBasePath: '/document-ms/api/v1',
      );

      expect(session.documentApiBasePath, '/document-ms/api/v1');
    });

    test('throws when the session code is missing', () {
      expect(
        () => EventModel.uploadSession(
          const {
            'data': {'sessionStatus': 'OPEN'},
          },
          fallbackDocumentBasePath: '/x',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
