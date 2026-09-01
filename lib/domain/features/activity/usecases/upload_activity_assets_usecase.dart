import 'package:dio/dio.dart';

import '../repositories/activity_media_upload_repository.dart';

/// Opens one upload session and runs presign → PUT → complete for every item.
class UploadActivityAssetsUseCase {
  UploadActivityAssetsUseCase(this._repository);

  final ActivityMediaUploadRepository _repository;

  Future<ActivityAssetUploadResult> call({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
    required String ownerType,
    required String ownerCode,
    required List<ActivityUploadItem> items,
    void Function(int itemIndex, int totalItems, int percent)? onItemProgress,
    void Function(int completedItems, int totalItems)? onItemComplete,
    CancelToken? cancelToken,
  }) {
    return _repository.uploadAssets(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: bindingMode,
      studentCodes: studentCodes,
      ownerType: ownerType,
      ownerCode: ownerCode,
      items: items,
      onItemProgress: onItemProgress,
      onItemComplete: onItemComplete,
      cancelToken: cancelToken,
    );
  }
}
