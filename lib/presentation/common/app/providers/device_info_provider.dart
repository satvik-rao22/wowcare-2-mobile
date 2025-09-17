import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    // Fetch Android device info
    final androidInfo = await deviceInfo.androidInfo;
    return '${androidInfo.brand} ${androidInfo.model}, Android ${androidInfo.version.release}';
  } else if (Platform.isIOS) {
    // Fetch iOS device info
    final iosInfo = await deviceInfo.iosInfo;
    return '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
  } else {
    // Handle other platforms (e.g., macOS, Windows)
    final genericInfo = await deviceInfo.deviceInfo;
    return 'Unknown Device: ${genericInfo.data}';
  }
}

