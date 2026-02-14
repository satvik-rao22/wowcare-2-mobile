class SchoolNamesResponseModel {
  final bool success;
  final String message;
  final List<String> data;
  /// Full list of {schoolCode, schoolName} when API returns objects.
  final List<Map<String, String>> dataWithCodes;
  final String timestamp;

  SchoolNamesResponseModel({
    required this.success,
    required this.message,
    required this.data,
    this.dataWithCodes = const [],
    required this.timestamp,
  });

  factory SchoolNamesResponseModel.fromJson(Map<String, dynamic> json) {
    // API returns data as object: {organizationName, schools: [{code, name, ...}]}
    List<dynamic> rawList = [];
    final data = json['data'];
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final schools = data['schools'];
      rawList = schools is List ? schools : [];
    }
    final names = <String>[];
    final withCodes = <Map<String, String>>[];
    for (final item in rawList) {
      if (item is String) {
        names.add(item);
        withCodes.add({'schoolCode': item, 'schoolName': item});
      } else if (item is Map<String, dynamic>) {
        final name = (item['schoolName'] ?? item['name'] ?? item['value'] ?? '')
            .toString()
            .trim();
        final code =
            (item['schoolCode'] ?? item['code'] ?? item['id'] ?? name).toString().trim();
        if (name.isNotEmpty) {
          names.add(name);
          withCodes.add({'schoolCode': code, 'schoolName': name});
        }
      }
    }
    return SchoolNamesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: names,
      dataWithCodes: withCodes,
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
