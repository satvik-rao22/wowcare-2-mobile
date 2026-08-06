import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Staff Details report generation.
///
/// Captures field selections (13 total staff fields) and maps them to
/// boolean include flags in the backend payload.
class StaffDetailsReportParams extends Equatable implements ReportParams {
  const StaffDetailsReportParams({
    required this.reportType,
    this.startDate,
    this.endDate,
    required this.staffFieldsSelected,
    required this.statusFilter,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime? startDate;
  final String schoolName;

  final DateTime? endDate;

  /// Set of selected staff field names (e.g., {'Name', 'Email ID', 'Designation'})
  final Set<String> staffFieldsSelected;

  /// Status filter value (e.g., 'Active Staff', 'Inactive Staff', 'All Staff')
  final String statusFilter;

  @override
  final String format;

  /// Optional classroom codes (empty = all classrooms)
  final List<String>? classroomCodes;

  @override
  Map<String, dynamic> toRequestBody() {
    return {
      'reportType': 'STAFF_DETAILS',
      'status': _mapStatusToBackendValue(statusFilter),

      // Staff field selections (13 fields)
      'includeName': staffFieldsSelected.contains('Name'),
      'includeDateOfBirth': staffFieldsSelected.contains('Date Of Birth'),
      'includeEmailId': staffFieldsSelected.contains('Email ID'),
      'includePhoneNumber': staffFieldsSelected.contains('Phone Number'),
      'includeAddress': staffFieldsSelected.contains('Address'),
      'includePrimaryClassroom': staffFieldsSelected.contains(
        'Primary Classroom',
      ),

      'includeClockInOutPin': staffFieldsSelected.contains('Clock-In-Out Pin'),
      'includeHireDate': staffFieldsSelected.contains('Hire Date'),
      'includeDesignation': staffFieldsSelected.contains('Designation'),
      'includeCdaExpirationDate': staffFieldsSelected.contains(
        'CDA Expiration Date',
      ),
      'includeCprExpirationDate': staffFieldsSelected.contains(
        'CPR Expiration Date',
      ),
      'includeLastPhysicalDate': staffFieldsSelected.contains(
        'Last Physical Date',
      ),
      'includeIsActive': staffFieldsSelected.contains('Is Active'),

      // Optional classrooms
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classroomCodes': classroomCodes,

      'format': format,
      'schoolName': schoolName,
    };
  }

  /// Map UI status selection to backend status value.
  String _mapStatusToBackendValue(String uiStatus) {
    switch (uiStatus) {
      case 'Active Staff':
        return 'ACTIVE';
      case 'Inactive Staff':
        return 'INACTIVE';
      case 'All Staff':
        return 'ALL';
      default:
        return 'ACTIVE';
    }
  }

  @override
  String toCacheIdentifier() {
    final parts = <String>[
      'STAFF_DETAILS',
      if (startDate != null) startDate!.toIso8601String().split('T')[0],
      if (endDate != null) endDate!.toIso8601String().split('T')[0],
      'staffFields=${staffFieldsSelected.toList()..sort()}',
      'status=$statusFilter',
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classrooms=${classroomCodes!.join(',')}',
    ];

    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    staffFieldsSelected,
    statusFilter,
    format,
    schoolName,
    classroomCodes,
  ];
}
