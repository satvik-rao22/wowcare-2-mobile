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

    final assetCode = (data['assetCode'] ?? '').toString().trim();
    final presignedPutUrl = (data['presignedPutUrl'] ?? '').toString().trim();
    if (assetCode.isEmpty || presignedPutUrl.isEmpty) {
      throw Exception('Missing assetCode or presignedPutUrl in presign response');
    }

    final rawHeaders = data['requiredHeaders'];
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

