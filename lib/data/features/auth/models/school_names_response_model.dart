class SchoolNamesResponseModel {
  final bool success;
  final String message;
  final List<String> data;
  final String timestamp;

  SchoolNamesResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory SchoolNamesResponseModel.fromJson(Map<String, dynamic> json) {
    return SchoolNamesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'timestamp': timestamp,
    };
  }
}
