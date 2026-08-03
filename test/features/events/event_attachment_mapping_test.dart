import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/event_models.dart';

/// Shaped after a real occurrence payload: `attachments[]` arrives with
/// `deliveryUrl` and `thumbnailUrl` already filled in, which is why events need
/// no resolve call.
Map<String, dynamic> _occurrence({List<Map<String, dynamic>>? attachments}) => {
      'occurrenceCode': 'OCC_CF3027F4D4',
      'eventCode': 'EVT_E401380B99',
      'type': 'STAFF',
      'displayName': 'Staff meeting',
      'displayDescription': 'Bring notes',
      'scheduledStartDate': '2026-08-04',
      'allDayFlag': true,
      'status': 'SCHEDULED',
      'recurring': false,
      'audienceScope': 'STAFF_SET',
      'includeParentsFlag': false,
      'createdAt': '2026-08-03T12:34:51.966347Z',
      'updatedAt': '2026-08-03T12:40:32.416134Z',
      'participants': const {
        'school': [],
        'classroom': [],
        'staff': [],
        'students': [],
        'parents': [],
      },
      if (attachments != null) 'attachments': attachments,
    };

Map<String, dynamic> _attachment({
  String assetCode = 'AST_9009D242-B',
  String fileName = 'training.jpg',
  String mediaType = 'IMAGE',
  String contentType = 'image/jpeg',
}) =>
    {
      'code': 'ATT_ACB97E186E',
      'eventCode': 'EVT_E401380B99',
      'type': 'EVENT',
      'assetCode': assetCode,
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': 80084,
      'mediaType': mediaType,
      'status': 'READY',
      'deliveryUrl': 'https://cdn.test/$assetCode/primary.webp',
      'thumbnailUrl': 'https://cdn.test/$assetCode/thumb_256.webp',
    };

void main() {
  test('occurrence attachments map through to the entity with their URLs', () {
    final event = EventModel.fromOccurrenceApi(
      _occurrence(attachments: [_attachment()]),
    ).toEntity();

    expect(event.attachments, hasLength(1));
    final asset = event.attachments.single;
    expect(asset.assetCode, 'AST_9009D242-B');
    expect(asset.fileName, 'training.jpg');
    expect(asset.sizeBytes, 80084);
    // URLs arrive inline, so the view layer needs no resolve round trip.
    expect(asset.isReady, isTrue);
    expect(asset.fullUrl, endsWith('primary.webp'));
    expect(asset.previewUrl, endsWith('thumb_256.webp'));
    expect(asset.isImage, isTrue);
    expect(asset.displaySubtitle, 'JPG · 78 KB');
  });

  test('several attachments keep their payload order', () {
    final event = EventModel.fromOccurrenceApi(
      _occurrence(
        attachments: [
          _attachment(assetCode: 'AST_1', fileName: 'a.jpg'),
          _attachment(
            assetCode: 'AST_2',
            fileName: 'b.pdf',
            mediaType: 'DOCUMENT',
            contentType: 'application/pdf',
          ),
        ],
      ),
    ).toEntity();

    expect(event.attachments.map((a) => a.assetCode), ['AST_1', 'AST_2']);
    expect(event.attachments[1].isPdf, isTrue);
    expect(event.attachments[1].isDocument, isTrue);
  });

  test('no attachments key yields an empty list, not a null', () {
    final event = EventModel.fromOccurrenceApi(_occurrence()).toEntity();

    expect(event.attachments, isEmpty);
  });

  test('an attachment without an asset code is skipped', () {
    final event = EventModel.fromOccurrenceApi(
      _occurrence(
        attachments: [
          {'code': 'ATT_1', 'fileName': 'orphan.jpg'},
          _attachment(assetCode: 'AST_OK'),
        ],
      ),
    ).toEntity();

    // Without an asset code there is nothing to fetch or key a cache on.
    expect(event.attachments.map((a) => a.assetCode), ['AST_OK']);
  });
}
