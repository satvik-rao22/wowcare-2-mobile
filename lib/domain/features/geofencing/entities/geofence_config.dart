import 'package:equatable/equatable.dart';

class GeofenceConfig extends Equatable {
  const GeofenceConfig({
    required this.schoolCode,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 250,
  });

  final String schoolCode;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  @override
  List<Object?> get props => [schoolCode, latitude, longitude, radiusMeters];
}
