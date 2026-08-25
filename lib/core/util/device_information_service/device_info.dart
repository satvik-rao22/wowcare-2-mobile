import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInformation {
  // Private constructor
  DeviceInformation._privateConstructor();

  // Singleton instance
  static final DeviceInformation _instance =
      DeviceInformation._privateConstructor();

  // Getter to access the singleton instance
  static DeviceInformation get instance => _instance;

  // Cached device data
  Future<Either<AndroidDeviceInfo, IosDeviceInfo>>? _cachedDeviceData;

  Future<Either<AndroidDeviceInfo, IosDeviceInfo>> get getDeviceData async {
    try {
      if (_cachedDeviceData != null) {
        return _cachedDeviceData!;
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;

        _cachedDeviceData = Future.value(left(androidDeviceInfo));
      } else if (Platform.isIOS) {
        IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
        _cachedDeviceData = Future.value(right(iosDeviceInfo));
      } else {
        throw Exception('Device info was not configured for current platform');
      }
    } catch (e, s) {
      debugPrint('getDeviceData ERROR $e $s');
      // throw Exception('Something went wrong!!');
    }
    return _cachedDeviceData!;
  }

  PackageInfo? _packageInfo;
  Future<PackageInfo> get getAppPackageInfo async {
    if (_packageInfo != null) return _packageInfo!;
    _packageInfo = await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  String? buildNumber;

  Future<int> get buildNo async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    return int.tryParse(buildNumber) ?? 1;
  }

  // Future<String?> get notificationToken async{
  //   String? currentToken= PushNotificationService.instance.token;
  //   // String? serverStoredNotificationToken=await LocalStorageServices.getSecuredStorageString(key: StorageKeys.pushNotificationToken);
  //   //
  //   //   //update notification token on server
  //   //   LocalStorageServices.saveSharedStorageBoolValue(key: StorageKeys.pushNotificationTokenUpdateRequired, value:serverStoredNotificationToken!=null && currentToken!=serverStoredNotificationToken? true:false);
  //
  //   return currentToken;
  // }
}
