import 'package:workmanager/workmanager.dart';
import 'package:wowcare/core/background/callback_dispatcher.dart';

/// One-time WorkManager setup. Registers the callback dispatcher only —
/// does NOT schedule any task. Task registration/cancellation is entirely
/// state-driven from GeofenceCubit (always + gpsSignInEnabled only).
Future<void> initializeWorkManager() async {
  await Workmanager().initialize(callbackDispatcher);
}
