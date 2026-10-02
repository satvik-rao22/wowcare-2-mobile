import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// "Has this install launched before?" — a file in the app's Application
/// Support directory.
///
/// It lives on the filesystem, not in the secure store, for one reason: the
/// iOS Keychain survives app uninstall, so a marker kept there would survive
/// too and every reinstall would look like an existing install. The app
/// container is removed on uninstall on both platforms (and this directory is
/// excluded from Android backup — `allowBackup` is off), so the file's
/// absence is a reliable "fresh install" signal. See `StorageBootstrap` for
/// what that signal triggers.
class InstallMarker {
  InstallMarker({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const String fileName = '.wowcare_installed';

  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  Future<bool> exists() async => (await _file()).exists();

  /// Creates the marker. A no-op when it already exists.
  Future<void> create() async {
    final file = await _file();
    if (await file.exists()) return;
    await file.create(recursive: true);
    await file.writeAsString(
      DateTime.now().toUtc().toIso8601String(),
      flush: true,
    );
  }
}
