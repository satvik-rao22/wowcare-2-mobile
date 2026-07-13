import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Students & Family report generation.
///
/// Captures field selections (20 total: 13 student + 7 guardian/pickup fields)
/// and maps them to boolean include flags in the backend payload.
class StudentsAndFamilyReportParams extends Equatable implements ReportParams {
  const StudentsAndFamilyReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.studentFieldsSelected,
    required this.parentFieldsSelected,
    required this.statusFilter,
    required this.format,
    this.classroomCodes,
    this.tagCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime endDate;

  /// Set of selected student field names (e.g., {'Full Name', 'DOB', ...})
  final Set<String> studentFieldsSelected;

  /// Set of selected guardian/parent field names
  final Set<String> parentFieldsSelected;

  /// Status filter value (e.g., 'Active', 'Inactive', 'Upcoming')
  final String statusFilter;

  @override
  final String format;

  /// Optional classroom codes (empty = all classrooms)
  final List<String>? classroomCodes;

  /// Optional tag codes (empty = all tags)
  final List<String>? tagCodes;

  @override
  Map<String, dynamic> toRequestBody() {
    return {
      'reportType': 'STUDENTS_AND_FAMILY',
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],

      // Student field selections (13 fields)
      'fullName': studentFieldsSelected.contains('Full Name'),
      'dob': studentFieldsSelected.contains('DOB'),
      'classroom': studentFieldsSelected.contains('Classroom'),
      'address': studentFieldsSelected.contains('Address'),
      'allergies': studentFieldsSelected.contains('Allergies'),
      'dietRestriction': studentFieldsSelected.contains('Diet Restriction'),
      'enrollDate': studentFieldsSelected.contains('Enroll Date'),
      'medications': studentFieldsSelected.contains('Medications'),
      'note': studentFieldsSelected.contains('Note'),
      'schedule': studentFieldsSelected.contains('Schedule'),
      'schoolLeavingDate': studentFieldsSelected.contains('School Leaving Date'),
      'status': studentFieldsSelected.contains('Status'),
      'tags': studentFieldsSelected.contains('Tags'),

      // Parent/Guardian field selections (7 fields)
      'guardianFirstName': parentFieldsSelected.contains('First name'),
      'guardianLastName': parentFieldsSelected.contains('Last name'),
      'guardianRelation': parentFieldsSelected.contains('Relation'),
      'guardianEmail': parentFieldsSelected.contains('Email'),
      'guardianPhoneNumber': parentFieldsSelected.contains('Phone number'),
      'guardianEmergencyContact': parentFieldsSelected.contains('Emergency Contact'),
      'guardianSignInPin': parentFieldsSelected.contains('Sign-in-Pin'),

      // Pickup field selections (7 fields - mapped to guardian prefix)
      'pickupFirstName': parentFieldsSelected.contains('Pickup First name'),
      'pickupLastName': parentFieldsSelected.contains('Pickup Last name'),
      'pickupRelation': parentFieldsSelected.contains('Pickup Relation'),
      'pickupEmail': parentFieldsSelected.contains('Pickup Email'),
      'pickupPhoneNumber': parentFieldsSelected.contains('Pickup Phone number'),
      'pickupEmergencyContact': parentFieldsSelected.contains('Pickup Emergency Contact'),
      'pickupSignInPin': parentFieldsSelected.contains('Pickup Sign-in-Pin'),

      // Optional filters
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'roomCodes': classroomCodes,
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tagCodes': tagCodes,

      // Backend expects an array even though the UI is single-select
      // (confirmed against the web client's payload for this report type).
      'statusFilter': [statusFilter],
      'format': format,
    };
  }

  @override
  String toCacheIdentifier() {
    final parts = <String>[
      'STUDENTS_AND_FAMILY',
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
      'studentFields=${studentFieldsSelected.toList()..sort()}',
      'parentFields=${parentFieldsSelected.toList()..sort()}',
      'statusFilter=$statusFilter',
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'roomCodes=${classroomCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tagCodes=${tagCodes!.join(',')}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    studentFieldsSelected,
    parentFieldsSelected,
    statusFilter,
    format,
    classroomCodes,
    tagCodes,
  ];
}
