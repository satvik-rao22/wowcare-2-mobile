import 'package:wowcare/presentation/features/staff/model/schedule_entry.dart';
import 'package:wowcare/presentation/features/staff/model/staff_filter_data.dart';

/// Typed `extra` payloads for the staff module's GoRouter routes.
///
/// Mandate 1 requires route arguments to be typed: every staff route used to
/// pass an untyped `Map<String, dynamic>` through `extra` and cast each key at
/// the receiving end, so a renamed or mistyped key failed silently at runtime
/// (a null field, a blank screen) instead of at compile time.

/// `extra` for the staff list route.
class StaffListArgs {
  const StaffListArgs({this.statusFilter});

  /// Pre-applied status filter — set when the staff-attendance "Active" /
  /// "Upcoming" legend cards open the list already narrowed.
  final String? statusFilter;
}

/// `extra` for the staff profile route.
class StaffProfileArgs {
  const StaffProfileArgs({
    required this.staffCode,
    this.userCode = '',
    this.name = '-',
    this.classroom = '-',
    this.designation = '',
    this.phoneNumber = '',
    this.employmentStatus,
    this.classroomNames,
    this.classroomNameByCode,
  });

  final String staffCode;
  final String userCode;
  final String name;
  final String classroom;
  final String designation;
  final String phoneNumber;
  final String? employmentStatus;

  /// Classroom metadata already loaded by the caller, passed along so the
  /// profile does not re-fetch the classroom list.
  final List<String>? classroomNames;
  final Map<String, String>? classroomNameByCode;
}

/// `extra` for the add-staff route.
class AddStaffArgs {
  const AddStaffArgs({
    this.isEdit = false,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhone,
    this.initialRole,
    this.initialAllowedClassroomCodes,
    this.initialPrimaryClassroom,
    this.initialStatus,
    this.initialClassroomNames,
    this.initialClassroomCodeByName,
  });

  final bool isEdit;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialRole;
  final List<String>? initialAllowedClassroomCodes;
  final String? initialPrimaryClassroom;
  final String? initialStatus;
  final List<String>? initialClassroomNames;
  final Map<String, String>? initialClassroomCodeByName;
}

/// `extra` for the edit-staff-profile route.
class EditStaffProfileArgs {
  const EditStaffProfileArgs({
    required this.staffCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialStatus,
    this.initialDesignation,
    this.initialAllowedClassrooms,
    this.initialPrimaryClassroom,
    this.initialPhoneNumber,
    this.initialBirthDate,
    this.initialJobTag,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.initialClassroomNames,
    this.initialClassroomCodeByName,
  });

  final String staffCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialStatus;
  final String? initialDesignation;
  final List<String>? initialAllowedClassrooms;
  final String? initialPrimaryClassroom;
  final String? initialPhoneNumber;

  // The staff-profile tab has always passed these through `extra`, but the
  // router's untyped map reader never read the keys, so the form opened with
  // them blank until its own profile fetch landed. Declaring them here is what
  // makes that visible — and fixes it.
  final DateTime? initialBirthDate;
  final String? initialJobTag;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialZipCode;

  final List<String>? initialClassroomNames;
  final Map<String, String>? initialClassroomCodeByName;
}

/// `extra` for the add/edit staff-document route.
class StaffDocumentFormArgs {
  const StaffDocumentFormArgs({
    required this.staffCode,
    this.isEdit = false,
    this.documentUuid,
    this.initialDocumentName,
    this.initialDocumentType,
    this.initialExpiryDate,
    this.initialFilePath,
    this.initialMimeType,
    this.initialFileSizeKb,
    this.initialDocumentNotes,
    this.initialAssetCode,
  });

  final String staffCode;
  final bool isEdit;
  final String? documentUuid;
  final String? initialDocumentName;
  final String? initialDocumentType;
  final DateTime? initialExpiryDate;
  final String? initialFilePath;
  final String? initialMimeType;
  final int? initialFileSizeKb;
  final String? initialDocumentNotes;
  final String? initialAssetCode;
}

/// `extra` for the edit-schedule route.
class EditStaffScheduleArgs {
  const EditStaffScheduleArgs({
    required this.staffCode,
    this.initialSchedules = const <ScheduleEntry>[],
  });

  final String staffCode;
  final List<ScheduleEntry> initialSchedules;
}

/// `extra` for the edit-important-dates route.
class EditImportantDatesArgs {
  const EditImportantDatesArgs({
    required this.staffCode,
    this.initialHireDate,
    this.initialCdaExaminationDate,
    this.initialFirstAidCprExpirationDate,
    this.initialBackgroundRecordCheckExpirationDate,
    this.initialPhysicalCheckupDate,
    this.initialPhysicalCheckupStatus,
  });

  final String staffCode;
  final DateTime? initialHireDate;
  final DateTime? initialCdaExaminationDate;
  final DateTime? initialFirstAidCprExpirationDate;
  final DateTime? initialBackgroundRecordCheckExpirationDate;
  final DateTime? initialPhysicalCheckupDate;
  final String? initialPhysicalCheckupStatus;
}

/// `extra` for the shared staff-filter route.
class StaffFilterArgs {
  const StaffFilterArgs({
    this.initialFilters,
    this.selectedDate,
    this.sections,
  });

  final FilterData? initialFilters;

  /// The day the caller is filtering. Only the attendance callers set it.
  final DateTime? selectedDate;

  /// Which facets the filter shows. `null` keeps `StaffFilterScreen`'s own
  /// default set (the full staff-roster filter); attendance passes the reduced
  /// Classroom + Designation pair.
  final List<StaffFilterSection>? sections;
}
