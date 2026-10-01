import 'package:equatable/equatable.dart';

/// The installed app's version: `2.2.21` and build `25` for `2.2.21+25`.
class AppVersion extends Equatable {
  const AppVersion({required this.name, required this.build});

  final String name;

  /// The store build number: `versionCode` on Android, `CFBundleVersion` on
  /// iOS. Zero when it could not be read.
  final int build;

  @override
  List<Object?> get props => [name, build];
}
