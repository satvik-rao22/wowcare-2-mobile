import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Where a staff member is on today's clock. On duty and on break both count
/// towards the ratio; the rest do not.
enum StaffDutyState { onDuty, onBreak, notMarked, absent, signedOut }

/// A staff member attached to a classroom (7c's Staff tab).
///
/// Mirrors `StaffClassroomItem` in
/// `lib/domain/features/staff_classroom/entities/`. Sign-in PINs are on the
/// module's costly list and are deliberately absent.
@immutable
class ClassroomStaffMember extends Equatable {
  const ClassroomStaffMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.designation,
    required this.state,
    this.timesLabel = '',
    this.classroomsLabel = '',
    this.phone,
  });

  final String id;
  final String name;
  final String initials;

  /// Lead Teacher, Assistant Teacher, Floater, Director.
  final String designation;

  final StaffDutyState state;

  /// "In 7:52 · 4h 38m worked".
  final String timesLabel;

  /// "Sunflower only", "Sunflower, Bluebell, Acorn".
  final String classroomsLabel;

  /// Present when the row offers a call key.
  final String? phone;

  String get firstName => name.split(' ').first;

  /// On the clock, break included: this is what the ratio counts.
  bool get isPresent =>
      state == StaffDutyState.onDuty || state == StaffDutyState.onBreak;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        designation.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    designation,
    state,
    timesLabel,
    classroomsLabel,
    phone,
  ];
}
