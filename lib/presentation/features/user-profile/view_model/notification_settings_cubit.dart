import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/config/notification_preference_catalog.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
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

  /// Row titles the user actually toggled this session. Only these are sent on
  /// save — so tapping one row PATCHes just that row's definition codes, not the
  /// whole matrix.
  final Set<String> _changedRowTitles = <String>{};

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

      // The service 500s on an empty schoolCode/userCode, so don't fire a
      // request we know is malformed — show the (unticked) default matrix
      // instead. Mirrors PaymentSettingsCubit's empty-school guard.
      if (userCode.isEmpty || schoolCode.isEmpty) {
        _changedRowTitles.clear();
        emit(state.copyWith(
          settings: _defaultSettings(),
          isLoading: false,
        ));
        return;
      }

      final prefs = await _getPreferences(
        userCode: userCode,
        schoolCode: schoolCode,
        role: role,
        organizationCode: organizationCode,
      );

      _changedRowTitles.clear();
      emit(state.copyWith(
        settings: _foldOntoMatrix(prefs, role),
        isLoading: false,
      ));
    } catch (e) {
      // Keep the (default) matrix visible; surface the failure.
      emit(state.copyWith(isLoading: false, errorMessage: ApiErrorHandler.extractErrorMessage(e)));
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
    _changedRowTitles.add(key);
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

      // Can't persist preferences without an active school — the service 500s
      // on an empty schoolCode. Surface it instead of silently "saving".
      if (userCode.isEmpty || schoolCode.isEmpty) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: 'No active school selected. Please reselect a school '
              'and try again.',
        ));
        return false;
      }

      // Send ONLY the rows the user toggled (scoped to the active role). Each
      // changed row still fans out to all of its definition codes.
      final updates = <NotificationPreferenceUpdate>[];
      for (final group in NotificationPreferenceCatalog.groupsForRole(role)) {
        if (!_changedRowTitles.contains(group.title)) continue;
        final row = state.settings[group.title];
        if (row == null) continue;
        for (final code in group.definitionCodes) {
          // Only send codes the backend recognises — unknown codes 500 it.
          if (!NotificationPreferenceCatalog.allowedDefinitionCodes
              .contains(code)) {
            continue;
          }
          updates.add(NotificationPreferenceUpdate(
            definitionCode: code,
            enabledInApp: row[_inApp],
            enabledEmail: row[_email],
            enabledPush: row[_push],
          ));
        }
      }

      // Nothing changed → no-op save (don't PATCH an empty list).
      if (updates.isEmpty) {
        emit(state.copyWith(isSaving: false, saved: true));
        return true;
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

      _changedRowTitles.clear();
      emit(state.copyWith(isSaving: false, saved: true));
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: ApiErrorHandler.extractErrorMessage(e)));
      return false;
    }
  }

  /// Builds the row matrix from the API response. Each row takes the channel
  /// flags of the first of its definition codes present in [prefs]; rows with no
  /// matching code are left **unticked** (all channels off) — so when the GET
  /// returns no data, every checkbox shows empty rather than the seeded default.
  Map<String, List<bool>> _foldOntoMatrix(
      List<NotificationPreference> prefs, String role) {
    final byCode = <String, NotificationPreference>{
      for (final p in prefs) p.definitionCode: p,
    };
    final matrix = _defaultSettings();
    // Fold only the active role's rows so a code shared by an admin row and a
    // parent row doesn't cross-populate the wrong persona's matrix.
    for (final group in NotificationPreferenceCatalog.groupsForRole(role)) {
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
    final raw = stored.isNotEmpty ? stored : (fallback ?? '').trim();
    return _normalizeRole(raw);
  }

  /// Collapses backend role codes (e.g. SCHOOL_ADMIN, ORGANIZATION_ADMIN,
  /// TEACHER) into the enum the notification service expects:
  /// ADMIN | GUARDIAN | STAFF. Anything unrecognised (incl. empty) → STAFF.
  String _normalizeRole(String raw) {
    final r = raw.trim().toUpperCase();
    if (r.contains('GUARDIAN') || r.contains('PARENT')) return 'GUARDIAN';
    if (r.contains('ADMIN')) return 'ADMIN';
    return 'STAFF';
  }

  /// Row titles shown on the settings screen (must match the screen's keys
  /// byte-for-byte, incl. non-breaking hyphen `‑` and curly apostrophe `’`).
  ///
  /// No seeded channel values: every row starts **unticked**. Ticked state comes
  /// only from the API response (see [_foldOntoMatrix]).
  static const List<String> _rowTitles = <String>[
    'Receive a message from staff',
    'Receive a message from parents',
    'Ratio is breached',
    'Student is signed‑in / signed‑out (or marked absent)',
    'Newsletter is received',
    'Student’s birthday',
    'Sign‑in alert just after shift start time (if not already done)',
    'Sign‑out alert just after shift end time (if not already done)',
    'My schedule when published/updated',
    'Students – Immunization (not added, upcoming, expiry/overdue)',
    'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
    'Students & Staff – Documents (expiry/overdue)',
    'Students & Staff – Other details (not added, edits)',
    'Payment refunded / Failed',
    'Upcoming student starting the school',
    'Upcoming room movements',
    'Overdue room movements',
    'Classroom shifts/schedule needs attention',
    'Today’s attendance is not marked for Students & Staff',
    'Incident is approved/rejected/acknowledged',
    'My child is signed‑in/signed‑out or marked absent',
    'New activity is recorded for my child',
    'Invoice is received',
    'Payment is successful / failed',
    'Refund is initiated/successful/failed',
    'My child’s profile/details are updated',
    'Sign‑in alert just after start time (if not already done)',
    'Sign‑out alert just after end time (if not already done)',
  ];

  // first bool = in-app, second bool = email, third bool = push (all off).
  static Map<String, List<bool>> _defaultSettings() => <String, List<bool>>{
        for (final title in _rowTitles) title: <bool>[false, false, false],
      };
}
