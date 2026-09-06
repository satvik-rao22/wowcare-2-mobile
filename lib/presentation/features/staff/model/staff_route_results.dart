import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';

/// Typed results the staff routes pop back to their caller.
///
/// These replace the untyped `Map<String, dynamic>` each screen used to
/// `Navigator.pop`, which the caller then had to probe key by key
/// (`result is Map && result['showPostAddPrompt'] == true`) — a shape no
/// compiler was checking on either side.

/// Popped by the add-staff form after a successful create.
class AddStaffResult {
  const AddStaffResult({
    required this.staffName,
    required this.userCode,
    required this.staffCode,
    this.showPostAddPrompt = true,
    this.firstName,
    this.lastName,
    this.email,
    this.designation,
    this.phoneNumber,
    this.primaryClassroom,
    this.allowedClassrooms,
    this.classroomNames,
    this.classroomCodeByName,
    this.status,
  });

  /// Whether the caller should offer "finish setting up this staff member".
  final bool showPostAddPrompt;

  final String staffName;
  final String userCode;
  final String staffCode;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? designation;
  final String? phoneNumber;
  final String? primaryClassroom;
  final List<String>? allowedClassrooms;
  final List<String>? classroomNames;
  final Map<String, String>? classroomCodeByName;
  final String? status;

  /// The post-add prompt continues straight into the edit form, seeded with
  /// what was just created — so the result carries exactly the edit route's
  /// arguments and converts to them rather than being re-keyed by the caller.
  EditStaffProfileArgs toEditProfileArgs() => EditStaffProfileArgs(
    staffCode: staffCode,
    initialFirstName: firstName,
    initialLastName: lastName,
    initialEmail: email,
    initialStatus: status,
    initialDesignation: designation,
    initialAllowedClassrooms: allowedClassrooms,
    initialPrimaryClassroom: primaryClassroom,
    initialPhoneNumber: phoneNumber,
    initialClassroomNames: classroomNames,
    initialClassroomCodeByName: classroomCodeByName,
  );
}

/// Popped by the shared staff-filter screen.
///
/// Every list is non-null: the screen returns an empty list for a section it
/// did not render, which callers read as "this filter is not applied".
class StaffFilterResult {
  const StaffFilterResult({
    this.status,
    this.designation,
    this.designations = const <String>[],
    this.primaryClassroomCodes = const <String>[],
    this.classCodes = const <String>[],
    this.sortBy = 'desc',
    this.attendanceStatuses = const <String>[],
  });

  /// Single selected status, or null when the status section was not shown or
  /// nothing was picked.
  final String? status;

  /// First selected designation (backend code), for callers that support one.
  final String? designation;

  /// All selected designations (backend codes), for callers that support
  /// multi-select.
  final List<String> designations;

  final List<String> primaryClassroomCodes;
  final List<String> classCodes;

  /// `'asc'` or `'desc'`.
  final String sortBy;

  final List<String> attendanceStatuses;
}
