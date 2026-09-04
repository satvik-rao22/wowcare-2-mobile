import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/staff/models/staff_member.dart';
import 'package:wowcare/redesign/features/staff/models/staff_status.dart';

/// The whole 6a screen: everybody on the school's books, and the two figures
/// over them.
///
/// The counts are the school's own rather than a tally of [members], because
/// that is where they come from: `GET /api/v1/staff/count` returns them
/// whatever page of the list is loaded.
@immutable
class StaffRoster extends Equatable {
  const StaffRoster({
    this.members = const <StaffMember>[],
    this.activeCount = 0,
    this.upcomingCount = 0,
    this.designations = const <String>[],
    this.classrooms = const <String>[],
    this.asOf,
  });

  final List<StaffMember> members;

  /// `StaffCount.active` and `StaffCount.upcoming`.
  final int activeCount;
  final int upcomingCount;

  /// Every designation held at this school, for the 6b sheet's chips.
  final List<String> designations;

  /// Every classroom, for the sheet's two classroom groups.
  final List<String> classrooms;

  /// When this was read. The offline banner says so.
  final DateTime? asOf;

  bool get isEmpty => members.isEmpty;

  int countOf(StaffStatus status) =>
      members.where((member) => member.status == status).length;

  /// The same roster with [updated] in place of the record it replaces, so a
  /// deactivate changes a row's pill without a refetch. The two counts move
  /// with it, because they are what the tiles over the list read.
  StaffRoster replacing(StaffMember updated) {
    final next = <StaffMember>[
      for (final member in members)
        if (member.id == updated.id) updated else member,
    ];
    return StaffRoster(
      members: next,
      activeCount: next.where((member) => member.isActive).length,
      upcomingCount: next.where((member) => member.isUpcoming).length,
      designations: designations,
      classrooms: classrooms,
      asOf: asOf,
    );
  }

  @override
  List<Object?> get props => [
    members,
    activeCount,
    upcomingCount,
    designations,
    classrooms,
    asOf,
  ];
}
