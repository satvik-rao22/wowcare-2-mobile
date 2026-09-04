part of 'notification_settings_cubit.dart';

enum NotificationSettingsStatus { loading, ready, failed }

@immutable
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    required this.userId,
    this.status = NotificationSettingsStatus.loading,
    this.groups = const <NotificationPreferenceGroup>[],
    this.savingGroupCodes = const <String>{},
    this.hasSaveFailed = false,
  });

  final String userId;
  final NotificationSettingsStatus status;
  final List<NotificationPreferenceGroup> groups;

  /// The groups with a PATCH in flight. Their rows dim and stop responding,
  /// so a second tap cannot race the first.
  final Set<String> savingGroupCodes;

  final bool hasSaveFailed;

  bool get isLoading => status == NotificationSettingsStatus.loading;
  bool get isFailed => status == NotificationSettingsStatus.failed;

  /// A school that has set up no groups for this account. Same fetch, a
  /// different answer, so it is not a status of its own.
  bool get isEmpty =>
      status == NotificationSettingsStatus.ready && groups.isEmpty;

  bool isSaving(String groupCode) => savingGroupCodes.contains(groupCode);

  /// The groups banded by category, in display order.
  List<PreferenceCategory> get categories => PreferenceCategory.of(groups);

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    List<NotificationPreferenceGroup>? groups,
    Set<String>? savingGroupCodes,
    bool? hasSaveFailed,
  }) => NotificationSettingsState(
    userId: userId,
    status: status ?? this.status,
    groups: groups ?? this.groups,
    savingGroupCodes: savingGroupCodes ?? this.savingGroupCodes,
    hasSaveFailed: hasSaveFailed ?? this.hasSaveFailed,
  );

  @override
  List<Object?> get props => <Object?>[
    userId,
    status,
    groups,
    savingGroupCodes,
    hasSaveFailed,
  ];
}
