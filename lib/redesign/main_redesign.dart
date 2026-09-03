import 'package:flutter/material.dart';
import 'package:wowcare/bootstrap/app_bootstrap.dart';
import 'package:wowcare/redesign/app/redesign_app.dart';

/// The redesign's entrypoint.
///
///     flutter run -t lib/redesign/main_redesign.dart --dart-define=ENVIRONMENT=QA
///
/// It boots the same way the app does — [AppBootstrap.initialize] wires up the
/// service locator, network stack, storage, Firebase and notifications — and
/// then hands off to [RedesignApp] instead of `MyApp`. The data and domain
/// layers behind that bootstrap are final and get linked to the new screens in
/// the last phase, so nothing under `lib/` outside `lib/redesign/` is touched.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  runApp(const RedesignApp());
}
