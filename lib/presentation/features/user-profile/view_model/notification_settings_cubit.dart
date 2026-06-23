import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/config/notification_preference_catalog.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference.dart';
import 'package:wowcare/domain/features/notifications/usecases/get_notification_preferences_usecase.dart';
import 'package:wowcare/domain/features/notifications/usecases/update_notification_preferences_usecase.dart';

/// Holds the notification-settings toggle matrix.
///
/// Each entry maps a notification row to `[inApp, email, push]` flags — the same
/// left-to-right order shown on screen.
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    required this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.saved = false,
    this.errorMessage,
  });

  final Map<String, List<bool>> settings;
  final bool isLoading;
  final bool isSaving;
  final bool saved;
  final String? errorMessage;

  NotificationSettingsState copyWith({
    Map<String, List<bool>>? settings,
    bool? isLoading,
    bool? isSaving,
    bool? saved,
    String? errorMessage,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[settings, isLoading, isSaving, saved, errorMessage];
}

/// Owns the notification-settings state. Loads current preferences from the
/// notification service (`GET /preferences`) and saves them back
/// (`PATCH /preferences`), fanning each UI row out to every definition code it
/// controls — see [NotificationPreferenceCatalog].
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required GetNotificationPreferencesUseCase getPreferences,
    required UpdateNotificationPreferencesUseCase updatePreferences,
    required StorageService storage,
  })  : _getPreferences = getPreferences,
        _updatePreferences = updatePreferences,
        _storage = storage,
        super(NotificationSettingsState(settings: _defaultSettings()));

  final GetNotificationPreferencesUseCase _getPreferences;
  final UpdateNotificationPreferencesUseCase _updatePreferences;
  final StorageService _storage;

  // Channel indices within each row's `[inApp, email, push]` list.
  static const int _inApp = 0;
  static const int _email = 1;
  static const int _push = 2;

  /// Loads saved preferences and folds them onto the row matrix.
  /// [roleFallback] is used only when no active-school role is stored.
  Future<void> load({String? roleFallback}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final userCode = await _read(StorageKeys.userCode);
      final schoolCode = await _read(StorageKeys.schoolCode);
      final organizationCode = await _read(StorageKeys.organizationCode);
      final role = await _resolveRole(roleFallback);

      final prefs = await _getPreferences(
        userCode: userCode,
        schoolCode: schoolCode,
        role: role,
        organizationCode: organizationCode,
      );

      emit(state.copyWith(
        settings: _foldOntoMatrix(prefs),
        isLoading: false,
      ));
    } catch (e) {
      // Keep the (default) matrix visible; surface the failure.
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Toggles one flag (`index`: 0 = in-app, 1 = email, 2 = push) for [key].
  void updateSetting(String key, int index, bool? value) {
    if (value == null) return;
    final current = state.settings;
    if (!current.containsKey(key)) return;
    final updated = <String, List<bool>>{
      for (final entry in current.entries)
        entry.key: List<bool>.from(entry.value),
    };
    updated[key]![index] = value;
    emit(state.copyWith(settings: updated, saved: false));
  }

  /// Saves the current matrix, expanding every row to all of its definition
  /// codes. Returns `true` on success.
  Future<bool> save({String? roleFallback}) async {
    emit(state.copyWith(isSaving: true, saved: false, errorMessage: null));
    try {
      final userCode = await _read(StorageKeys.userCode);
      final schoolCode = await _read(StorageKeys.schoolCode);
      final organizationCode = await _read(StorageKeys.organizationCode);
      final role = await _resolveRole(roleFallback);

      final updates = <NotificationPreferenceUpdate>[];
      for (final group in NotificationPreferenceCatalog.groups) {
        final row = state.settings[group.title];
        if (row == null) continue;
        for (final code in group.definitionCodes) {
          updates.add(NotificationPreferenceUpdate(
            definitionCode: code,
            enabledInApp: row[_inApp],
            enabledEmail: row[_email],
            enabledPush: row[_push],
          ));
        }
      }

      await _updatePreferences(
        userCode: userCode,
        request: UpdateNotificationPreferencesRequest(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          role: role,
          preferences: updates,
        ),
      );

      emit(state.copyWith(isSaving: false, saved: true));
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      return false;
    }
  }

  /// Builds the row matrix from the API response. Each row takes the channel
  /// flags of the first of its definition codes present in [prefs]; rows with no
  /// matching code keep their default.
  Map<String, List<bool>> _foldOntoMatrix(List<NotificationPreference> prefs) {
    final byCode = <String, NotificationPreference>{
      for (final p in prefs) p.definitionCode: p,
    };
    final matrix = _defaultSettings();
    for (final group in NotificationPreferenceCatalog.groups) {
      if (!matrix.containsKey(group.title)) continue;
      for (final code in group.definitionCodes) {
        final pref = byCode[code];
        if (pref != null) {
          matrix[group.title] = <bool>[
            pref.enabledInApp,
            pref.enabledEmail,
            pref.enabledPush,
          ];
          break;
        }
      }
    }
    return matrix;
  }

  Future<String> _read(String key) async =>
      (await _storage.getString(key) ?? '').trim();

  Future<String> _resolveRole(String? fallback) async {
    final stored = await _read(StorageKeys.activeSchoolRole);
    if (stored.isNotEmpty) return stored;
    return (fallback ?? '').trim();
  }

  // first bool = in-app, second bool = email, third bool = push
  static Map<String, List<bool>> _defaultSettings() => {
        'Receive a message from staff': [true, true, false],
        'Receive a message from parents': [true, true, false],
        'Ratio is breached': [true, true, false],
        'Student is signed‑in / signed‑out (or marked absent)': [
          true,
          true,
          false
        ],
        'Newsletter is received': [true, true, true],
        'Student’s birthday': [true, true, false],
        'Sign‑in alert just after shift start time (if not already done)': [
          true,
          true,
          false
        ],
        'Sign‑out alert just after shift end time (if not already done)': [
          true,
          true,
          false
        ],
        'My schedule when published/updated': [true, true, true],
        'Students – Immunization (not added, upcoming, expiry/overdue)': [
          true,
          true,
          true
        ],
        'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)':
            [true, true, true],
        'Students & Staff – Documents (expiry/overdue)': [true, true, true],
        'Students & Staff – Other details (not added, edits)': [
          true,
          true,
          true
        ],
        'Payment refunded / Failed': [true, true, true],
        'Upcoming student starting the school': [true, true, true],
        'Upcoming room movements': [true, true, true],
        'Overdue room movements': [true, true, true],
        'Classroom shifts/schedule needs attention': [true, true, true],
        'Today’s attendance is not marked for Students & Staff': [
          false,
          false,
          true
        ],
        'Incident is approved/rejected/acknowledged': [true, true, true],
        'My child is signed‑in/signed‑out or marked absent': [
          true,
          true,
          false
        ],
        'New activity is recorded for my child': [true, true, false],
        'Invoice is received': [true, true, true],
        'Payment is successful / failed': [true, true, true],
        'My child’s profile/details are updated': [true, true, false],
        'Sign‑in alert just after start time (if not already done)': [
          true,
          true,
          false
        ],
        'Sign‑out alert just after end time (if not already done)': [
          true,
          true,
          false
        ],
      };
}
