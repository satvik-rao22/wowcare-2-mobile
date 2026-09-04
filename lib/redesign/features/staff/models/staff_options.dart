import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/staff/models/staff_role.dart';

/// What the 6d wizard and the edit form may pick from.
///
/// The two designation lists are `add_staff_screen.dart`'s own
/// `_adminDesignationOptions` and `_staffDesignationOptions`, kept apart
/// because the existing screen refuses a designation that does not belong to
/// the role that is picked.
@immutable
class StaffOptions extends Equatable {
  const StaffOptions({
    this.adminDesignations = const <String>[],
    this.staffDesignations = const <String>[],
    this.classrooms = const <String>[],
    this.jobTags = const <String>[],
  });

  final List<String> adminDesignations;
  final List<String> staffDesignations;
  final List<String> classrooms;
  final List<String> jobTags;

  List<String> designationsFor(StaffRole role) => switch (role) {
    StaffRole.admin => adminDesignations,
    StaffRole.staff => staffDesignations,
  };

  /// Every designation either role can hold, for the 6b filter sheet when the
  /// roster has not named them itself.
  List<String> get allDesignations => <String>[
    ...staffDesignations,
    ...adminDesignations,
  ];

  bool get isEmpty => classrooms.isEmpty && allDesignations.isEmpty;

  @override
  List<Object?> get props => [
    adminDesignations,
    staffDesignations,
    classrooms,
    jobTags,
  ];
}
