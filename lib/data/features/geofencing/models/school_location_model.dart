import '../../../../domain/features/geofencing/entities/geofence_config.dart';

class SchoolLocationModel {
  const SchoolLocationModel({
    required this.schoolCode,
    required this.latitude,
    required this.longitude,
  });

  final String schoolCode;
  final double latitude;
  final double longitude;

  factory SchoolLocationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return SchoolLocationModel(
      schoolCode: (data['schoolCode'] as String?) ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  GeofenceConfig toEntity() => GeofenceConfig(
    schoolCode: schoolCode,
    latitude: latitude,
    longitude: longitude,
  );
}
