import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/models/staff_status.dart';

/// Which way the roster is sorted (6b "Order").
enum StaffOrder { aToZ, zToA }

/// What the 6b filter sheet has set.
///
/// Status is pick-one and defaults to Active, which is why the roster opens
/// on the people who are working rather than on everybody who ever was.
@immutable
class StaffFilters extends Equatable {
  const StaffFilters({
    this.status = StaffStatus.active,
    this.designations = const <String>{},
    this.primaryClassrooms = const <String>{},
    this.allowedIn = const <String>{},
    this.attendance = const <AttendanceStatus>{},
    this.order = StaffOrder.aToZ,
  });

  final StaffStatus status;
  final Set<String> designations;

  /// Where a staff member is rostered.
  final Set<String> primaryClassrooms;

  /// Every classroom they may cover. A wider net than [primaryClassrooms].
  final Set<String> allowedIn;

  final Set<AttendanceStatus> attendance;
  final StaffOrder order;

  bool get isClear =>
      status == StaffStatus.active &&
      designations.isEmpty &&
      primaryClassrooms.isEmpty &&
      allowedIn.isEmpty &&
      attendance.isEmpty &&
      order == StaffOrder.aToZ;

  /// How many groups are narrowing the list, which is what turns the filter
  /// key on. Status and order always have a value, so they never count.
  int get narrowingCount =>
      (designations.isEmpty ? 0 : 1) +
      (primaryClassrooms.isEmpty ? 0 : 1) +
      (allowedIn.isEmpty ? 0 : 1) +
      (attendance.isEmpty ? 0 : 1);

  StaffFilters copyWith({
    StaffStatus? status,
    Set<String>? designations,
    Set<String>? primaryClassrooms,
    Set<String>? allowedIn,
    Set<AttendanceStatus>? attendance,
    StaffOrder? order,
  }) => StaffFilters(
    status: status ?? this.status,
    designations: designations ?? this.designations,
    primaryClassrooms: primaryClassrooms ?? this.primaryClassrooms,
    allowedIn: allowedIn ?? this.allowedIn,
    attendance: attendance ?? this.attendance,
    order: order ?? this.order,
  );

  @override
  List<Object?> get props => [
    status,
    designations,
    primaryClassrooms,
    allowedIn,
    attendance,
    order,
  ];
}

/// One chip over the roster (6a). Which group it belongs to decides what
/// tapping its cross clears.
enum StaffChipGroup {
  status,
  designation,
  primaryClassroom,
  allowedIn,
  attendance,
  order,
}

/// A chip as the roster draws it: a label, the group it clears, and the value
/// within that group, if the group holds several.
@immutable
class StaffChip extends Equatable {
  const StaffChip({required this.label, required this.group, this.value});

  final String label;
  final StaffChipGroup group;

  /// The one value this chip stands for, when its group is a set. A
  /// designation or classroom name, or an [AttendanceStatus]; `Set.remove`
  /// takes it as it is, so nothing has to be parsed back out of a string.
  final Object? value;

  /// Status and order are always set to something, so their chip is a
  /// statement rather than something to remove.
  bool get isRemovable =>
      group != StaffChipGroup.status && group != StaffChipGroup.order;

  @override
  List<Object?> get props => [label, group, value];
}
