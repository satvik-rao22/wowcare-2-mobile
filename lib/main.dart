import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wowcare/app/app.dart';
import 'package:wowcare/bootstrap/app_bootstrap.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/util/server_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  // Proactive token refresh — the piece the web client doesn't need. A browser
  // tab stays alive; a phone can background for hours, so the access token is
  // routinely stale on resume. Renewing here (with a skew, just BEFORE expiry)
  // avoids eating a guaranteed 401 on the first request after resume.
  WidgetsBinding.instance.addObserver(_TokenLifecycleObserver());

  // Sync the authoritative server clock once at startup; the observer re-syncs
  // on every resume (a phone can background for hours and the device clock can
  // drift or be manually changed). Fire-and-forget: falls back to device time.
  unawaited(ServerTimeService.instance.sync());

  runApp(const MyApp());
}

/// Refreshes the access token whenever the app returns to the foreground, so the first request
/// after a long background doesn't eat a guaranteed 401. [TokenRefreshService.ensureFreshToken]
/// no-ops when the token is still comfortably valid (default 60s skew), so this is cheap on resume.
///
/// Also re-syncs the authoritative server clock on resume.
///
/// Restores the observer the "feature/activity-bug" merge dropped, which left a dangling
/// `_TokenLifecycleObserver()` reference in main() and broke the mobile build on develop.
class _TokenLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(TokenRefreshService.instance.ensureFreshToken());
      // Re-align "now" with the server after time in the background.
      unawaited(ServerTimeService.instance.sync());
    }
  }
}
