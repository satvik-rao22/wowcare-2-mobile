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
      // API returns a list of objects; extract the name field safely
      data: (json['data'] as List?)
              ?.map((item) {
                if (item is String) return item;
                if (item is Map<String, dynamic>) {
                  // Try common keys; adjust if backend uses a different one
                  return (item['schoolName'] ??
                          item['name'] ??
                          item['value'] ??
                          '')
                      .toString();
                }
                return item.toString();
              })
              .where((e) => e.isNotEmpty)
              .toList()
              .cast<String>() ??
          <String>[],
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
