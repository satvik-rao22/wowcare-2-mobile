import 'package:equatable/equatable.dart';

/// One notification-preference definition with its per-channel enabled flags,
/// as returned by `GET /api/v1/notification/preferences`.
class NotificationPreference extends Equatable {
  const NotificationPreference({
    required this.definitionCode,
    this.definitionTitle = '',
    this.categoryName = '',
    this.allowedChannels = const <String>[],
    this.enabledInApp = false,
    this.enabledPush = false,
    this.enabledEmail = false,
  });

  final String definitionCode;
  final String definitionTitle;
  final String categoryName;
  final List<String> allowedChannels;
  final bool enabledInApp;
  final bool enabledPush;
  final bool enabledEmail;

  @override
  List<Object?> get props => <Object?>[
        definitionCode,
        definitionTitle,
        categoryName,
        allowedChannels,
        enabledInApp,
        enabledPush,
        enabledEmail,
      ];
}
