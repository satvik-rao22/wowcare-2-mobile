import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_upload_asset_statuses_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/upload_activity_assets_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/wait_activity_assets_ready_usecase.dart';

/// Records the arguments each repository method receives so we can prove the
/// thin use-cases forward verbatim.
class _SpyRepository implements ActivityMediaUploadRepository {
  Map<String, dynamic>? uploadArgs;
  Map<String, dynamic>? waitArgs;
  Map<String, dynamic>? statusArgs;

  @override
  Future<ActivityAssetUploadResult> uploadAssets({
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
  }) async {
    uploadArgs = {
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'classroomCode': classroomCode,
      'activityTypeCode': activityTypeCode,
      'bindingMode': bindingMode,
      'studentCodes': studentCodes,
      'ownerType': ownerType,
      'ownerCode': ownerCode,
      'items': items,
      'cancelToken': cancelToken,
    };
    return const ActivityAssetUploadResult(
      assetCodeByPath: {'/p': 'ASSET-1'},
      sessionCode: 'SESSION-1',
      newAssetCodes: ['ASSET-1'],
    );
  }

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> assetCodes,
  }) async {
    waitArgs = {'sessionCode': sessionCode, 'assetCodes': assetCodes};
  }

  @override
  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> assetCodes,
  }) async {
    statusArgs = {'sessionCode': sessionCode, 'assetCodes': assetCodes};
    return {'ASSET-1': 'READY'};
  }
}

void main() {
  test('UploadActivityAssetsUseCase forwards every argument to the repository',
      () async {
    final repo = _SpyRepository();
    final token = CancelToken();
    final items = [
      // The use-case never touches the filesystem — it only forwards the item.
      ActivityUploadItem(
        file: File('/tmp/never-read.jpg'),
        fileName: 'a.jpg',
        contentType: 'image/jpeg',
        mediaType: 'IMAGE',
      ),
    ];

    final result = await UploadActivityAssetsUseCase(repo).call(
      organizationCode: 'ORG',
      schoolCode: 'SCH',
      classroomCode: 'CLS',
      activityTypeCode: 'TYPE',
      bindingMode: 'SHARED',
      studentCodes: const ['STU-1', 'STU-2'],
      ownerType: 'CLASSROOM',
      ownerCode: 'CLS',
      items: items,
      cancelToken: token,
    );

    expect(repo.uploadArgs!['organizationCode'], 'ORG');
    expect(repo.uploadArgs!['bindingMode'], 'SHARED');
    expect(repo.uploadArgs!['studentCodes'], ['STU-1', 'STU-2']);
    expect(repo.uploadArgs!['ownerType'], 'CLASSROOM');
    expect(identical(repo.uploadArgs!['items'], items), isTrue);
    expect(identical(repo.uploadArgs!['cancelToken'], token), isTrue);
    expect(result.sessionCode, 'SESSION-1');
    expect(result.newAssetCodes, ['ASSET-1']);
  });

  test('WaitActivityAssetsReadyUseCase delegates', () async {
    final repo = _SpyRepository();
    await WaitActivityAssetsReadyUseCase(repo).call(
      sessionCode: 'S9',
      assetCodes: const ['A9'],
    );
    expect(repo.waitArgs, {
      'sessionCode': 'S9',
      'assetCodes': ['A9'],
    });
  });

  test('GetActivityUploadAssetStatusesUseCase delegates and returns statuses',
      () async {
    final repo = _SpyRepository();
    final statuses = await GetActivityUploadAssetStatusesUseCase(repo).call(
      sessionCode: 'S8',
      assetCodes: const ['ASSET-1'],
    );
    expect(repo.statusArgs, {
      'sessionCode': 'S8',
      'assetCodes': ['ASSET-1'],
    });
    expect(statuses, {'ASSET-1': 'READY'});
  });
}
