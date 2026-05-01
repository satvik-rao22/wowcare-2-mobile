import '../../../../domain/features/activity/entities/activity_asset_presign.dart';

class ActivityAssetPresignModel extends ActivityAssetPresign {
  const ActivityAssetPresignModel({
    required super.assetCode,
    required super.presignedPutUrl,
    required super.requiredHeaders,
  });

  factory ActivityAssetPresignModel.fromResponse(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected assets presign API data format');
    }

    final uploads = data['uploads'];
    if (uploads is! List || uploads.isEmpty) {
      throw Exception('Unexpected assets presign uploads format');
    }
    final firstUpload = uploads.first;
    if (firstUpload is! Map) {
      throw Exception('Unexpected assets presign upload item format');
    }

    final assetCode = (firstUpload['assetCode'] ?? '').toString().trim();
    final presignedPutUrl =
        (firstUpload['presignedPutUrl'] ?? '').toString().trim();
    if (assetCode.isEmpty || presignedPutUrl.isEmpty) {
      throw Exception('Missing assetCode or presignedPutUrl in presign response');
    }

    final rawHeaders = firstUpload['requiredHeaders'];
    final requiredHeaders = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        final k = key.toString().trim();
        final v = value.toString().trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          requiredHeaders[k] = v;
        }
      });
    }

    return ActivityAssetPresignModel(
      assetCode: assetCode,
      presignedPutUrl: presignedPutUrl,
      requiredHeaders: requiredHeaders,
    );
  }
}

