import 'package:wowcare/redesign/features/staff/models/models.dart';

/// Where M06 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation fans out across the calls the module already makes:
/// `GET /api/v1/staff` for the roster, `/api/v1/staff/count` for the two
/// figures over it, `/api/v1/staff/{code}` for a record, `/api/v1/staff-dates`,
/// `/api/v1/staff-schedules`, `/api/v1/staff-documents` and
/// `/api/v1/staff-attendance/profile` for its tabs, `/api/v1/school-users/staff`
/// to create one, and `/api/v1/school-users/{code}/deactivate` and its
/// activate twin for 6f.
///
/// Nothing here is new API work. The Sign-In PIN is read only, so there is no
/// method to set or reset one: `getStaffSignInPin` is a read on the existing
/// repository and that is all the module ever does with it.
abstract interface class StaffSource {
  /// The whole 6a screen: everybody, and the counts over them.
  Future<StaffRoster> loadRoster();

  /// One record with its five tabs (6c).
  Future<StaffProfile> loadProfile(String id);

  /// What the wizard and the edit form may pick from (6d).
  Future<StaffOptions> loadOptions();

  /// Create the record, its classrooms and its Sign-In PIN. It does not
  /// create a password: that still comes from the web.
  Future<StaffMember> createStaff(StaffDraft draft);

  /// Name, contact and address. Everything else on a record is set elsewhere.
  Future<StaffProfile> updateDetails({
    required String id,
    required StaffDetailsDraft draft,
  });

  /// Replace the working week. Admin only, and the cubit refuses before this
  /// is ever reached.
  Future<StaffProfile> updateSchedule({
    required String id,
    required List<StaffShift> week,
  });

  /// 6f, and the reactivate that undoes it. Nothing is deleted either way.
  Future<StaffMember> setActive({required String id, required bool isActive});

  /// Put a file on the record (6c Documents).
  Future<StaffDocument> addDocument({
    required String staffId,
    required String name,
    required String type,
    DateTime? expiresOn,
  });
}
