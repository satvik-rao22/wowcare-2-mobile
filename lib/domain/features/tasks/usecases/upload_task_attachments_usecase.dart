import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';

import '../repositories/task_repository.dart';

/// Uploads several task attachments in one batch and returns their per-file
/// results (Tasks API §8/§9).
///
/// The session comes from the tasks service — that call is what authorizes the
/// domain and owner — while the transfer itself is domain-agnostic and handled
/// by [AttachmentUploadManager]. Pairing the two here is the whole job of this
/// use case, so the cubit never has to know the upload flow exists.
///
/// Supersedes `UploadTaskAttachmentUseCase` for anything multi-file: that one
/// opens a session per file, which costs a full round trip each time.
class UploadTaskAttachmentsUseCase {
  UploadTaskAttachmentsUseCase(this._repository, this._manager);

  final TaskRepository _repository;
  final AttachmentUploadManager _manager;

  Future<AttachmentUploadState> call({
    required List<PickedFile> files,
    void Function(AttachmentUploadState state)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _manager.upload(
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
    );
  }
}
