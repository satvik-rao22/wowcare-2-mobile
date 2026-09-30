class SchoolNamesResponseModel {
  final bool success;
  final String message;
  final List<String> data;
  /// Full list of {schoolCode, schoolName} when API returns objects.
  final List<Map<String, String>> dataWithCodes;
  /// Optional organization display name when API returns
  /// { organizationName, schools: [...] }.
  final String organizationName;
  final String timestamp;

  SchoolNamesResponseModel({
    required this.success,
    required this.message,
    required this.data,
    this.dataWithCodes = const [],
    this.organizationName = '',
    required this.timestamp,
  });

  factory SchoolNamesResponseModel.fromJson(Map<String, dynamic> json) {
    // API returns data as object: {organizationName, schools: [{code, name, ...}]}
    List<dynamic> rawList = [];
    final data = json['data'];
    String orgName = '';
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      orgName = (data['organizationName'] ?? '').toString().trim();
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
        final status = (item['status'] ?? '').toString().trim().toUpperCase();
        if (name.isNotEmpty) {
          names.add(name);
          withCodes.add({
            'schoolCode': code,
            'schoolName': name,
            if (status.isNotEmpty) 'status': status,
          });
        }
      }
    }
    return SchoolNamesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: names,
      dataWithCodes: withCodes,
      organizationName: orgName,
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
