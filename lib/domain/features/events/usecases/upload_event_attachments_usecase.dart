import 'package:dio/dio.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';
import 'package:wowcare/shared/services/asset/asset_models.dart';

import '../repositories/event_repository.dart';

/// Uploads several event attachments in one batch and returns their per-file
/// results.
///
/// The session comes from the events service — that call is what authorizes the
/// domain and owner — while the transfer itself is domain-agnostic and handled
/// by [AttachmentUploadManager]. Mirrors `UploadTaskAttachmentsUseCase`; the two
/// differ only in which service mints the session.
class UploadEventAttachmentsUseCase {
  UploadEventAttachmentsUseCase(this._repository, this._manager);

  final EventRepository _repository;
  final AttachmentUploadManager _manager;

  Future<AttachmentUploadState> call({
    required List<PickedFile> files,
    void Function(AttachmentUploadState state)? onProgress,
    CancelToken? cancelToken,
  }) {
    // The manager reports a failed batch in the state it returns, never by
    // throwing. By then each file's error is a message, so only a cancel can
    // be bucketed more precisely than unknown.
    return AppEvents.track(
      AppEvent.eventAttachmentUpload,
      () => _manager.upload(
        files: files,
        openSession: () async {
          final session = await _repository.createUploadSession();
          return UploadSessionResult(
            sessionCode: session.sessionCode,
            documentApiBasePath: session.documentApiBasePath,
          );
        },
        onProgress: onProgress,
        cancelToken: cancelToken,
      ),
      count: files.length,
      failureOf: (state) {
        if (!state.hasFailures) return null;
        return (cancelToken?.isCancelled ?? false)
            ? EventFailure.cancelled
            : EventFailure.unknown;
      },
    );
  }
}
