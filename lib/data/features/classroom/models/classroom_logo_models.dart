class ClassroomLogoUploadSessionDataModel {
  const ClassroomLogoUploadSessionDataModel({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;

  factory ClassroomLogoUploadSessionDataModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassroomLogoUploadSessionDataModel(
      sessionCode: (json['sessionCode'] ?? '').toString().trim(),
      documentApiBasePath:
          (json['documentApiBasePath'] ?? '/api/v1').toString().trim(),
    );
  }
}

class ClassroomLogoUploadSessionResponseModel {
  const ClassroomLogoUploadSessionResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ClassroomLogoUploadSessionDataModel? data;

  factory ClassroomLogoUploadSessionResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassroomLogoUploadSessionResponseModel(
      success: json['success'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? ClassroomLogoUploadSessionDataModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Response shape for the finalize-logo endpoint. No payload beyond the
/// success/message envelope is used by callers.
class ClassroomLogoFinalizeResponseModel {
  const ClassroomLogoFinalizeResponseModel({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory ClassroomLogoFinalizeResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassroomLogoFinalizeResponseModel(
      success: json['success'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
    );
  }
}
