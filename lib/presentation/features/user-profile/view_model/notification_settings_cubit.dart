import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the notification-settings toggle matrix.
///
/// Each entry maps a notification type to `[inApp, push, email]` flags.
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState(this.settings);

  final Map<String, List<bool>> settings;

  @override
  List<Object?> get props => [settings];
}

/// Owns the notification-settings state so the screen stays display-only
/// (replaces a static mutable map mutated via `setState`).
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit()
      : super(NotificationSettingsState(_defaultSettings()));

  /// Toggles one flag (`index`: 0 = in-app, 1 = push, 2 = email) for [key].
  void updateSetting(String key, int index, bool? value) {
    if (value == null) return;
    final current = state.settings;
    if (!current.containsKey(key)) return;
    final updated = <String, List<bool>>{
      for (final entry in current.entries)
        entry.key: List<bool>.from(entry.value),
    };
    updated[key]![index] = value;
    emit(NotificationSettingsState(updated));
  }

  // first bool = in-app, second bool = push, third bool = email
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
