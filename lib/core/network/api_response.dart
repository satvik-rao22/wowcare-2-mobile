class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  /// Generic factory that knows how to decode the `data` field.
  ///
  /// Example usages:
  /// - `ApiResponse<LoginResponseModel>.fromJson(json, (d) => LoginResponseModel.fromJson(d));`
  /// - `ApiResponse<List<String>>.fromJson(json, (d) => List<String>.from(d as List));`
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic dataJson) fromData,
  ) {
    final rawData = json['data'];

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: rawData == null ? null : fromData(rawData),
      timestamp: json['timestamp']?.toString(),
    );
  }
}

