import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A time on the school's clock, stored on the 24-hour dial.
///
/// Mirrors the real `StudentAttendanceTime` / `StaffAttendanceTime`, which
/// come back as `{hour, minute}` rather than an instant, so nothing here has
/// to guess a timezone. Duration is arithmetic on two of these: the API sums
/// nothing, and the design's "Here 1 hour 39 minutes so far" is worked out on
/// the device.
@immutable
class ClockTime extends Equatable implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  ClockTime.fromDateTime(DateTime at) : hour = at.hour, minute = at.minute;

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// "8:42", "12:15", "3:40" — the 12-hour face the frames write, with no
  /// meridiem, because that is how every attendance row in the design reads.
  String get label {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${minute.toString().padLeft(2, '0')}';
  }

  /// Whole minutes from this time to [other], never negative.
  int minutesUntil(ClockTime other) {
    final span = other.minutesOfDay - minutesOfDay;
    return span < 0 ? 0 : span;
  }

  @override
  int compareTo(ClockTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  List<Object?> get props => <Object?>[hour, minute];
}
