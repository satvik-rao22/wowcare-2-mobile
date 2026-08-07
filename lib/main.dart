import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wowcare/app/app.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/bootstrap/app_bootstrap.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/firebase/firebase_auth_service.dart';
import 'package:wowcare/core/util/server_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  WidgetsBinding.instance.addObserver(_TokenLifecycleObserver());

  await ServerTimeService.instance.hydrateSchoolTimeZoneFromStorage();
  unawaited(ServerTimeService.instance.sync());

  runApp(const MyApp());
}

class _TokenLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(TokenRefreshService.instance.ensureFreshToken());

      unawaited(ServerTimeService.instance.sync());
   
      unawaited(serviceLocator<FirebaseAuthService>().signIn());
    }
  }
}
