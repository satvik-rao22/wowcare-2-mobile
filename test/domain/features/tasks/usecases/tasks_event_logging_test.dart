import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/domain/features/tasks/usecases/cancel_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/detach_task_attachment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/upload_task_attachments_usecase.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';

/// Answers the `Future<void>` writes generically; set [error] to fail them.
class _FakeTaskRepository implements TaskRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (error != null) return Future<Never>.error(error!);
    return switch (invocation.memberName) {
      #deleteTask ||
      #deleteAssignment ||
      #detachAttachment => Future<void>.value(),
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

void main() {
  final logs = <SentryLog>[];
  late _FakeTaskRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeTaskRepository();
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

  test('deletes and detaches log one event each and no codes', () async {
    await DeleteTaskUseCase(repo)('TSK-1');
    await DeleteTaskAssignmentUseCase(repo)('ASG-1');
    await DetachTaskAttachmentUseCase(repo)(
      taskCode: 'TSK-1',
      attachmentCode: 'ATT-1',
    );
    await settle();

    expect(logs.map((log) => log.body), [
      'task.delete.succeeded',
      'task.assignment_delete.succeeded',
      'task.attachment_detach.succeeded',
    ]);
    for (final log in logs) {
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(anyOf('TSK-1', 'ASG-1', 'ATT-1'))),
      );
    }
  });

  test('an occurrence cancel failure is bucketed and rethrown', () async {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/x'),
      reason: 'offline',
    );
    repo.error = error;

    await expectLater(
      CancelTaskOccurrenceUseCase(repo)(
        seriesCode: 'TSK-1',
        occurrenceCode: 'OCC-1',
        reason: 'closed for snow',
      ),
      throwsA(same(error)),
    );
    await settle();

    final log = logs.single;
    expect(log.body, 'task.occurrence_cancel.failed');
    expect(log.attributes['failure']!.value, 'network');
    expect(
      log.attributes.values.map((a) => '${a.value}'),
      isNot(contains('closed for snow')),
    );
  });

  test('an attachment upload logs the file count', () async {
    const file = PickedFile(
      path: '/tmp/checklist.pdf',
      name: 'checklist.pdf',
      sizeBytes: 10,
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
    const done = AttachmentUploadState(
      items: [
        AttachmentUploadItem(file: file, status: AttachmentUploadStatus.done),
      ],
    );

    await UploadTaskAttachmentsUseCase(repo, _FakeUploadManager(done))(
      files: const [file],
    );
    await settle();

    final log = logs.single;
    expect(log.body, 'task.attachment_upload.succeeded');
    expect(log.attributes['count']!.value, 1);
  });

  test('an upload that could not open a session is failed', () async {
    const fatal = AttachmentUploadState(
      fatalError: 'Could not start the upload.',
    );

    await UploadTaskAttachmentsUseCase(repo, _FakeUploadManager(fatal))(
      files: const [
        PickedFile(
          path: '/tmp/a.pdf',
          name: 'a.pdf',
          sizeBytes: 1,
          extension: 'pdf',
          mimeType: 'application/pdf',
        ),
      ],
    );
    await settle();

    expect(logs.single.body, 'task.attachment_upload.failed');
    expect(logs.single.attributes['failure']!.value, 'unknown');
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
