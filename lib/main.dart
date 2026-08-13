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

  WidgetsBinding.instance.addObserver(_TokenLifecycleObserver()..start());

  await ServerTimeService.instance.hydrateSchoolTimeZoneFromStorage();
  unawaited(ServerTimeService.instance.sync());

  runApp(const MyApp());
}

/// Keeps the backend access token and the Firebase session fresh both on
/// background→foreground resume AND while the app just sits open and idle.
///
/// The resume path alone leaves a real gap: a phone left open on a chat
/// screen (screen on, app foregrounded, no lifecycle transition) never
/// triggers a refresh — [TokenRefreshService.ensureFreshToken] and
/// [FirebaseAuthService.signIn] were only ever called from
/// [didChangeAppLifecycleState]'s `resumed` branch. Firestore listeners do
/// have their own reactive retry-on-`permission-denied` path (see
/// `MessageRealtimeDataSource._watchWithRetry` / `ConversationRealtimeDataSource
/// .retryOrForward`), but that only fires once a listener actually errors —
/// an idle-long-enough session can go stale silently in between. The
/// periodic timer below proactively re-validates on an interval regardless
/// of lifecycle state, so staleness gets caught before it causes a visible
/// drop in realtime updates.
class _TokenLifecycleObserver extends WidgetsBindingObserver {
  static const _idleRefreshInterval = Duration(minutes: 15);

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // Runs for the lifetime of the process — this observer is never removed/
  // disposed (the app has no natural teardown point short of process
  // death), so the timer is deliberately left uncancelled rather than
  // stored in a field that would just sit unused.
  void start() {
    Timer.periodic(_idleRefreshInterval, (_) {
      // Skip while backgrounded — nothing to keep alive for a UI that isn't
      // visible, and [didChangeAppLifecycleState]'s own `resumed` branch
      // already covers the moment it comes back.
      if (_lifecycleState == AppLifecycleState.resumed) {
        unawaited(_refreshAll());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAll());
    }
  }

  Future<void> _refreshAll() async {
    unawaited(TokenRefreshService.instance.ensureFreshToken());
    unawaited(ServerTimeService.instance.sync());
    unawaited(serviceLocator<FirebaseAuthService>().signIn());
  }
}
