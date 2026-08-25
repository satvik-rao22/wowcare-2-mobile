import '../../../../domain/features/activity/entities/activity_upload_session.dart';
import '../../../../core/util/api_constants.dart';

class ActivityUploadSessionModel extends ActivityUploadSession {
  const ActivityUploadSessionModel({
    required super.sessionCode,
    required super.documentApiBasePath,
  });

  factory ActivityUploadSessionModel.fromUploadSessionResponse(
    Map<String, dynamic> body,
  ) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected upload-sessions API data format');
    }

    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Upload session code is missing');
    }

    final fallbackDocumentBasePath = ApiConstants.isGatewayEnv
        ? '/api/v1/document'
        : '/document-ms/api/v1';
    final documentApiBasePath =
        (data['documentApiBasePath'] ?? fallbackDocumentBasePath)
            .toString()
            .trim();

    return ActivityUploadSessionModel(
      sessionCode: sessionCode,
      documentApiBasePath: documentApiBasePath.isEmpty
          ? fallbackDocumentBasePath
          : documentApiBasePath,
    );
  }
}
