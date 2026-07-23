import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wowcare/app/app.dart';
import 'package:wowcare/bootstrap/app_bootstrap.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  // Proactive token refresh — the piece the web client doesn't need. A browser
  // tab stays alive; a phone can background for hours, so the access token is
  // routinely stale on resume. Renewing here (with a skew, just BEFORE expiry)
  // avoids eating a guaranteed 401 on the first request after resume.
  WidgetsBinding.instance.addObserver(_TokenLifecycleObserver());

  runApp(const MyApp());
}

/// Refreshes the access token when the app returns to the foreground.
class _TokenLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Fire-and-forget: a failure just leaves the 401 path to handle renewal.
    unawaited(
      TokenRefreshService.instance.ensureFreshToken().catchError((_) => false),
    );
  }
}
