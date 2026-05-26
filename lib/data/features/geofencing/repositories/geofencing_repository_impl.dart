import 'package:geolocator/geolocator.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../../../../domain/features/geofencing/entities/geofence_config.dart';
import '../../../../domain/features/geofencing/repositories/geofencing_repository.dart';
import '../datasources/geofencing_local_datasource.dart';
import '../models/school_location_model.dart';

class GeofencingRepositoryImpl implements GeofencingRepository {
  GeofencingRepositoryImpl({
    required GeofencingLocalDataSource localDataSource,
    required ApiClient apiClient,
  })  : _local = localDataSource,
        _apiClient = apiClient;

  final GeofencingLocalDataSource _local;
  final ApiClient _apiClient;

  @override
  Future<bool> hasLocationPermission() => _local.hasLocationPermission();

  @override
  Future<bool> requestLocationPermission() =>
      _local.requestLocationPermission();

  @override
  Future<bool> isLocationServiceEnabled() => _local.isLocationServiceEnabled();

  @override
  Future<GeofenceConfig> getSchoolLocation({required String schoolCode}) async {
    try {
      final path = ApiPaths.schoolTimezone(schoolCode);
      final url = ApiPaths.url(path);
      final response = await _apiClient.client.get<dynamic>(url);
      final model = SchoolLocationModel.fromJson(
        response.data as Map<String, dynamic>? ?? {},
      );
      return model.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Position> getCurrentPosition() => _local.getCurrentPosition();

  @override
  Stream<Position> getPositionStream() => _local.getPositionStream();
}
