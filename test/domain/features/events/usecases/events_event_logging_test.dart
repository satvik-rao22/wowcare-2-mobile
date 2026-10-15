import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/repositories/event_repository.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/upload_event_attachments_usecase.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';

/// Answers every repository call generically, so the test does not have to
/// mirror the repository's long signatures.
class _FakeEventRepository implements EventRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (error != null) return Future<Never>.error(error!);
    return switch (invocation.memberName) {
      #respondToOccurrence => Future<void>.value(),
      #deleteHoliday => Future.value('deleted'),
      _ => throw UnimplementedError('${invocation.memberName}'),
    };
  }
}

/// Hands back a canned batch result; the transfer itself is not under test.
class _FakeUploadManager implements AttachmentUploadManager {
  _FakeUploadManager(this.result);

  final AttachmentUploadState result;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(result);
}

const _files = [
  PickedFile(
    path: '/tmp/permission-slip.pdf',
    name: 'permission-slip.pdf',
    sizeBytes: 10,
    extension: 'pdf',
    mimeType: 'application/pdf',
  ),
  PickedFile(
    path: '/tmp/map.png',
    name: 'map.png',
    sizeBytes: 20,
    extension: 'png',
    mimeType: 'image/png',
  ),
];

void main() {
  final logs = <SentryLog>[];
  late _FakeEventRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeEventRepository();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  Iterable<String> attributeValues(SentryLog log) =>
      log.attributes.values.map((a) => '${a.value}');

  test('an RSVP logs its outcome and nothing about the party', () async {
    await RespondToEventUseCase(repo)(
      eventCode: 'EVT-1',
      occurrenceCode: 'OCC-1',
      partyCode: 'GRD-1',
      partyType: 'GUARDIAN',
      status: EventRsvpStatus.attending,
    );
    await settle();

    final log = logs.single;
    expect(log.body, 'event.rsvp.succeeded');
    expect(
      attributeValues(log),
      isNot(contains(anyOf('EVT-1', 'OCC-1', 'GRD-1', 'GUARDIAN'))),
    );
  });

  test('a holiday delete failure is bucketed and rethrown untouched', () async {
    final request = RequestOptions(path: '/x');
    final error = DioException.badResponse(
      statusCode: 403,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 403),
    );
    repo.error = error;

    await expectLater(
      DeleteHolidayUseCase(repo)('HOL-1'),
      throwsA(same(error)),
    );
    await settle();

    final log = logs.single;
    expect(log.body, 'event.holiday_delete.failed');
    expect(log.attributes['failure']!.value, 'forbidden');
  });

  group('attachment upload', () {
    test('logs the file count and no file name', () async {
      final done = AttachmentUploadState(
        items: [
          for (final file in _files)
            AttachmentUploadItem(
              file: file,
              status: AttachmentUploadStatus.done,
              assetCode: 'AST-${file.name}',
            ),
        ],
      );

      final result = await UploadEventAttachmentsUseCase(
        repo,
        _FakeUploadManager(done),
      )(files: _files);
      await settle();

      expect(result, same(done));
      final log = logs.single;
      expect(log.body, 'event.attachment_upload.succeeded');
      expect(log.attributes['count']!.value, 2);
      expect(
        attributeValues(log),
        isNot(contains(anyOf(contains('.pdf'), contains('.png')))),
      );
    });

    test('a batch that comes back with a failed file is failed', () async {
      final partial = AttachmentUploadState(
        items: [
          AttachmentUploadItem(
            file: _files[0],
            status: AttachmentUploadStatus.done,
          ),
          AttachmentUploadItem(
            file: _files[1],
            status: AttachmentUploadStatus.failed,
            error: 'Upload was rejected',
          ),
        ],
      );

      await UploadEventAttachmentsUseCase(repo, _FakeUploadManager(partial))(
        files: _files,
      );
      await settle();

      final log = logs.single;
      expect(log.body, 'event.attachment_upload.failed');
      expect(log.attributes['failure']!.value, 'unknown');
      expect(log.attributes['count']!.value, 2);
      expect(attributeValues(log), isNot(contains('Upload was rejected')));
    });

    test('a cancelled batch is bucketed cancelled', () async {
      final cancelToken = CancelToken()..cancel();
      final failed = AttachmentUploadState(
        items: [
          for (final file in _files)
            AttachmentUploadItem(
              file: file,
              status: AttachmentUploadStatus.failed,
            ),
        ],
      );

      await UploadEventAttachmentsUseCase(repo, _FakeUploadManager(failed))(
        files: _files,
        cancelToken: cancelToken,
      );
      await settle();

      expect(logs.single.attributes['failure']!.value, 'cancelled');
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
