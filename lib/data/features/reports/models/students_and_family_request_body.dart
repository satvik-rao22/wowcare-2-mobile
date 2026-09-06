import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';

part 'students_and_family_request_body.g.dart';

/// Request body for the Students & Family report: a boolean per column, split
/// across student, guardian and pickup groups.
///
/// The pickup columns use a `pickup*` prefix on the wire but are selected from
/// the same parent field set in the form, which is why they read out of
/// [StudentsAndFamilyReportParams.parentFieldsSelected].
@JsonSerializable(includeIfNull: false, createFactory: false)
class StudentsAndFamilyRequestBody extends ReportRequestPayload {
  const StudentsAndFamilyRequestBody({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.fullName,
    required this.dob,
    required this.classroom,
    required this.address,
    required this.allergies,
    required this.dietRestriction,
    required this.enrollDate,
    required this.medications,
    required this.note,
    required this.schedule,
    required this.schoolLeavingDate,
    required this.status,
    required this.tags,
    required this.guardianFirstName,
    required this.guardianLastName,
    required this.guardianRelation,
    required this.guardianEmail,
    required this.guardianPhoneNumber,
    required this.guardianEmergencyContact,
    required this.guardianSignInPin,
    required this.pickupFirstName,
    required this.pickupLastName,
    required this.pickupRelation,
    required this.pickupEmail,
    required this.pickupPhoneNumber,
    required this.pickupEmergencyContact,
    required this.pickupSignInPin,
    required this.statusFilter,
    required this.format,
    required this.schoolName,
    this.roomCodes,
    this.tagCodes,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory StudentsAndFamilyRequestBody.fromParams(
    StudentsAndFamilyReportParams params,
    ReportRequestContext context,
  ) {
    final student = params.studentFieldsSelected;
    final parent = params.parentFieldsSelected;
    return StudentsAndFamilyRequestBody(
      reportType: 'STUDENTS_AND_FAMILY',
      startDate: ReportRequestPayload.ymd(params.startDate),
      endDate: ReportRequestPayload.ymd(params.endDate),
      fullName: student.contains('Full Name'),
      dob: student.contains('DOB'),
      classroom: student.contains('Classroom'),
      address: student.contains('Address'),
      allergies: student.contains('Allergies'),
      dietRestriction: student.contains('Diet Restriction'),
      enrollDate: student.contains('Enroll Date'),
      medications: student.contains('Medications'),
      note: student.contains('Note'),
      schedule: student.contains('Schedule'),
      schoolLeavingDate: student.contains('School Leaving Date'),
      status: student.contains('Status'),
      tags: student.contains('Tags'),
      guardianFirstName: parent.contains('First name'),
      guardianLastName: parent.contains('Last name'),
      guardianRelation: parent.contains('Relation'),
      guardianEmail: parent.contains('Email'),
      guardianPhoneNumber: parent.contains('Phone number'),
      guardianEmergencyContact: parent.contains('Emergency Contact'),
      guardianSignInPin: parent.contains('Sign-in-Pin'),
      pickupFirstName: parent.contains('Pickup First name'),
      pickupLastName: parent.contains('Pickup Last name'),
      pickupRelation: parent.contains('Pickup Relation'),
      pickupEmail: parent.contains('Pickup Email'),
      pickupPhoneNumber: parent.contains('Pickup Phone number'),
      pickupEmergencyContact: parent.contains('Pickup Emergency Contact'),
      pickupSignInPin: parent.contains('Pickup Sign-in-Pin'),
      roomCodes: ReportRequestPayload.emptyToNull(params.classroomCodes),
      tagCodes: ReportRequestPayload.emptyToNull(params.tagCodes),
      // The backend expects an array here even though the UI is single-select.
      statusFilter: [params.statusFilter.toUpperCase()],
      format: params.format,
      schoolName: ReportRequestPayload.resolveSchoolName(
        params.schoolName,
        context.schoolName,
      ),
      schoolCode: context.schoolCode,
      organizationCode: context.organizationCode,
      generatedBy: context.generatedBy,
    );
  }

  final String reportType;
  final String startDate;
  final String endDate;

  final bool fullName;
  final bool dob;
  final bool classroom;
  final bool address;
  final bool allergies;
  final bool dietRestriction;
  final bool enrollDate;
  final bool medications;
  final bool note;
  final bool schedule;
  final bool schoolLeavingDate;
  final bool status;
  final bool tags;

  final bool guardianFirstName;
  final bool guardianLastName;
  final bool guardianRelation;
  final bool guardianEmail;
  final bool guardianPhoneNumber;
  final bool guardianEmergencyContact;
  final bool guardianSignInPin;

  final bool pickupFirstName;
  final bool pickupLastName;
  final bool pickupRelation;
  final bool pickupEmail;
  final bool pickupPhoneNumber;
  final bool pickupEmergencyContact;
  final bool pickupSignInPin;

  final List<String>? roomCodes;
  final List<String>? tagCodes;
  final List<String> statusFilter;
  final String format;
  final String schoolName;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() => _$StudentsAndFamilyRequestBodyToJson(this);
}
