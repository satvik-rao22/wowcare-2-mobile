import 'package:flutter/material.dart';
import 'package:wowcare/redesign/app/redesign_app.dart';

/// The redesign on its own, with no bootstrap behind it.
///
///     flutter run -t lib/redesign/main_preview.dart
///
/// While the UI phase runs, every feature is fed by a `PreviewSource` holding
/// fixtures, so nothing here needs Firebase, the network stack, storage or the
/// app's own service locator. That makes this the fastest way to look at a
/// screen, and the only entrypoint that works without a configured Firebase
/// environment.
///
/// [main_redesign.dart] is the one that boots the real stack, and is what
/// Phase 5 links the data layer through. Neither replaces `lib/main.dart`,
/// which is what a reviewer runs to get the New Design / Old Design chooser.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RedesignApp());
}
