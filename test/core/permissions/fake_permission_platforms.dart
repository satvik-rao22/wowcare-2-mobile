import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stands in for the native side of permission_handler.
class FakePermissionHandler extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  final Map<Permission, PermissionStatus> statuses = {};

  /// What the "OS dialog" answers. Defaults to leaving the status unchanged.
  final Map<Permission, PermissionStatus> requestResults = {};

  /// How long the "OS dialog" takes to answer. Leave at zero in widget
  /// tests: a real timer would never fire under their fake clock.
  Duration requestDelay = Duration.zero;

  bool rationale = false;
  int requestCount = 0;
  int openSettingsCount = 0;
  Object? throwOnCheck;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (throwOnCheck != null) throw throwOnCheck!;
    return statuses[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    requestCount++;
    if (requestDelay > Duration.zero) await Future<void>.delayed(requestDelay);
    return {
      for (final p in permissions)
        p: statuses[p] =
            requestResults[p] ?? statuses[p] ?? PermissionStatus.denied,
    };
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(
    Permission permission,
  ) async => rationale;

  @override
  Future<bool> openAppSettings() async {
    openSettingsCount++;
    return true;
  }
}

/// Stands in for the native side of Geolocator (iOS location path).
class FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  LocationPermission status = LocationPermission.denied;
  LocationPermission? requestResult;
  int requestCount = 0;

  @override
  Future<LocationPermission> checkPermission() async => status;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCount++;
    return status = requestResult ?? status;
  }
}
