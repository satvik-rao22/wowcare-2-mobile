import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/annual_state_immunization_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';

final s = DateTime.utc(2026, 1, 2, 3, 4, 5);
final e = DateTime.utc(2026, 2, 3, 6, 7, 8);
final d = DateTime.utc(2026, 3, 4, 9, 10, 11);

/// One fixture per interesting branch of the old `toRequestBody()` methods:
/// each report-type date branch, the `roomCodes`/`classroomCodes` split, the
/// blank-string guards, and the empty-list guards.
Map<String, ReportParams> fixtures() => {
  'req_dailyAttendance_min': ReportRequestParams(
    reportType: ReportType.studentDailyAttendance,
    startDate: s,
    schoolName: 'Sunny School',
  ),
  'req_dailyAttendance_withDate': ReportRequestParams(
    reportType: ReportType.studentDailyAttendance,
    startDate: s,
    date: d,
    schoolName: 'Sunny School',
    format: 'PDF',
  ),
  'req_billingOutstanding': ReportRequestParams(
    reportType: ReportType.billingOutstanding,
    startDate: s,
    endDate: e,
    schoolName: 'Sunny School',
    format: 'XLSX',
    roomCodes: ['R1'],
  ),
  'req_billingInvoice_full': ReportRequestParams(
    reportType: ReportType.billingInvoice,
    startDate: s,
    endDate: e,
    schoolName: 'Sunny School',
    format: 'XLSX',
    periodType: 'MONTHLY',
    roomCodes: ['R1', 'R2'],
    studentCodes: ['S1'],
    invoiceStatuses: ['Paid'],
    transactionStatuses: ['OK'],
    transactionTypes: ['CARD'],
    paymentMethods: ['ACH'],
  ),
  'req_billingRefund_roomCodesDropped': ReportRequestParams(
    reportType: ReportType.billingRefund,
    startDate: s,
    schoolName: '',
    roomCodes: ['R1'],
  ),
  'req_studentAbsent_roomCodes': ReportRequestParams(
    reportType: ReportType.studentAbsent,
    startDate: s,
    endDate: e,
    schoolName: '  ',
    roomCodes: ['R1'],
    tagCodes: ['T1'],
  ),
  'req_staffAbsent_roomCodes': ReportRequestParams(
    reportType: ReportType.staffAbsent,
    startDate: s,
    endDate: e,
    schoolName: 'Sunny School',
    roomCodes: ['R1'],
    staffCodes: ['ST1'],
  ),
  'req_immunization_classroomCodes': ReportRequestParams(
    reportType: ReportType.immunization,
    startDate: s,
    endDate: e,
    schoolName: 'Sunny School',
    roomCodes: ['R1'],
    search: '  needle  ',
    folderClassGrouping: 'CLASS',
  ),
  'req_emptyOptionalLists': ReportRequestParams(
    reportType: ReportType.studentIncident,
    startDate: s,
    schoolName: 'Sunny School',
    roomCodes: [],
    studentCodes: [],
    tagCodes: [],
    invoiceStatuses: [],
    transactionStatuses: [],
    transactionTypes: [],
    paymentMethods: [],
    search: '   ',
    folderClassGrouping: '',
    periodType: '  ',
  ),
  'annual_min': AnnualStateImmunizationReportParams(
    reportType: ReportType.annualStateImmunization,
    startDate: s,
    endDate: e,
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'family_min': StudentsAndFamilyReportParams(
    reportType: ReportType.studentsAndFamily,
    startDate: s,
    endDate: e,
    studentFieldsSelected: const {},
    parentFieldsSelected: const {},
    statusFilter: 'active',
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'family_full': StudentsAndFamilyReportParams(
    reportType: ReportType.studentsAndFamily,
    startDate: s,
    endDate: e,
    studentFieldsSelected: const {
      'Full Name',
      'DOB',
      'Classroom',
      'Address',
      'Allergies',
      'Diet Restriction',
      'Enroll Date',
      'Medications',
      'Note',
      'Schedule',
      'School Leaving Date',
      'Status',
      'Tags',
    },
    parentFieldsSelected: const {
      'First name',
      'Last name',
      'Relation',
      'Email',
      'Phone number',
      'Emergency Contact',
      'Sign-in-Pin',
      'Pickup First name',
      'Pickup Last name',
      'Pickup Relation',
      'Pickup Email',
      'Pickup Phone number',
      'Pickup Emergency Contact',
      'Pickup Sign-in-Pin',
    },
    statusFilter: 'Upcoming',
    format: 'XLSX',
    schoolName: 'Sunny School',
    classroomCodes: ['R1'],
    tagCodes: ['T1'],
  ),
  'family_emptyLists': StudentsAndFamilyReportParams(
    reportType: ReportType.studentsAndFamily,
    startDate: s,
    endDate: e,
    studentFieldsSelected: const {'DOB'},
    parentFieldsSelected: const {'Email'},
    statusFilter: 'Inactive',
    format: 'PDF',
    schoolName: '',
    classroomCodes: [],
    tagCodes: [],
  ),
  'staffDetails_min': StaffDetailsReportParams(
    reportType: ReportType.staffDetails,
    staffFieldsSelected: const {},
    statusFilter: 'Unknown Status',
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'staffDetails_full': StaffDetailsReportParams(
    reportType: ReportType.staffDetails,
    startDate: s,
    endDate: e,
    staffFieldsSelected: const {
      'Name',
      'Date Of Birth',
      'Email ID',
      'Phone Number',
      'Address',
      'Primary Classroom',
      'Clock-In-Out Pin',
      'Hire Date',
      'Designation',
      'CDA Expiration Date',
      'CPR Expiration Date',
      'Last Physical Date',
      'Is Active',
    },
    statusFilter: 'Active Staff',
    format: 'XLSX',
    schoolName: 'Sunny School',
    classroomCodes: ['R1', 'R2'],
  ),
  'staffDetails_inactive_emptyRooms': StaffDetailsReportParams(
    reportType: ReportType.staffDetails,
    staffFieldsSelected: const {'Name'},
    statusFilter: 'Inactive Staff',
    format: 'PDF',
    schoolName: 'Sunny School',
    classroomCodes: [],
  ),
  'staffDetails_activeStaff': StaffDetailsReportParams(
    reportType: ReportType.staffDetails,
    staffFieldsSelected: const {'Name'},
    statusFilter: 'Active Staff',
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'staffSchedule_min': StaffSchedulingReportParams(
    reportType: ReportType.staffScheduling,
    startDate: s,
    endDate: e,
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'staffSchedule_full': StaffSchedulingReportParams(
    reportType: ReportType.staffScheduling,
    startDate: s,
    endDate: e,
    format: 'XLSX',
    schoolName: 'Sunny School',
    classroomCodes: ['R1'],
  ),
  'staffSchedule_emptyRooms': StaffSchedulingReportParams(
    reportType: ReportType.staffScheduling,
    startDate: s,
    endDate: e,
    format: 'PDF',
    schoolName: 'Sunny School',
    classroomCodes: [],
  ),
  'immunization_min': SchoolImmunizationReportParams(
    reportType: ReportType.immunization,
    startDate: s,
    endDate: e,
    vaccineCodes: const ['DTaP'],
    statusFilters: const ['ACTIVE'],
    includeParentName: false,
    includeParentEmail: false,
    format: 'PDF',
    schoolName: 'Sunny School',
  ),
  'immunization_full': SchoolImmunizationReportParams(
    reportType: ReportType.immunization,
    startDate: s,
    endDate: e,
    vaccineCodes: const ['DTaP', 'MMR'],
    statusFilters: const ['ACTIVE', 'UPCOMING'],
    includeParentName: true,
    includeParentEmail: true,
    format: 'XLSX',
    schoolName: 'Sunny School',
    classroomCodes: ['R1'],
    tagCodes: ['T1'],
  ),
  'immunization_emptyLists': SchoolImmunizationReportParams(
    reportType: ReportType.immunization,
    startDate: s,
    endDate: e,
    vaccineCodes: const [],
    statusFilters: const [],
    includeParentName: false,
    includeParentEmail: true,
    format: 'PDF',
    schoolName: '',
    classroomCodes: [],
    tagCodes: [],
  ),
};

/// The exact payload every fixture produced *before* the request-model
/// migration (§8), captured from the hand-written `toRequestBody()` methods
/// and pinned here verbatim.
///
/// The mandate requires proving the new path is identical on every fixture —
/// including empty lists, blank strings and the report-type branches that
/// switch `roomCodes`/`classroomCodes` and the date keys — so these goldens
/// are asserted against the generated `toJson()` output rather than
/// regenerated from it.
const String goldenJson = r'''
{
  "annual_min": {
    "endDate": "2026-02-03",
    "format": "PDF",
    "reportType": "ANNUAL_STATE_IMMUNIZATION",
    "schoolName": "Sunny School",
    "startDate": "2026-01-02"
  },
  "family_emptyLists": {
    "address": false,
    "allergies": false,
    "classroom": false,
    "dietRestriction": false,
    "dob": true,
    "endDate": "2026-02-03",
    "enrollDate": false,
    "format": "PDF",
    "fullName": false,
    "guardianEmail": true,
    "guardianEmergencyContact": false,
    "guardianFirstName": false,
    "guardianLastName": false,
    "guardianPhoneNumber": false,
    "guardianRelation": false,
    "guardianSignInPin": false,
    "medications": false,
    "note": false,
    "pickupEmail": false,
    "pickupEmergencyContact": false,
    "pickupFirstName": false,
    "pickupLastName": false,
    "pickupPhoneNumber": false,
    "pickupRelation": false,
    "pickupSignInPin": false,
    "reportType": "STUDENTS_AND_FAMILY",
    "schedule": false,
    "schoolLeavingDate": false,
    "schoolName": "",
    "startDate": "2026-01-02",
    "status": false,
    "statusFilter": [
      "INACTIVE"
    ],
    "tags": false
  },
  "family_full": {
    "address": true,
    "allergies": true,
    "classroom": true,
    "dietRestriction": true,
    "dob": true,
    "endDate": "2026-02-03",
    "enrollDate": true,
    "format": "XLSX",
    "fullName": true,
    "guardianEmail": true,
    "guardianEmergencyContact": true,
    "guardianFirstName": true,
    "guardianLastName": true,
    "guardianPhoneNumber": true,
    "guardianRelation": true,
    "guardianSignInPin": true,
    "medications": true,
    "note": true,
    "pickupEmail": true,
    "pickupEmergencyContact": true,
    "pickupFirstName": true,
    "pickupLastName": true,
    "pickupPhoneNumber": true,
    "pickupRelation": true,
    "pickupSignInPin": true,
    "reportType": "STUDENTS_AND_FAMILY",
    "roomCodes": [
      "R1"
    ],
    "schedule": true,
    "schoolLeavingDate": true,
    "schoolName": "Sunny School",
    "startDate": "2026-01-02",
    "status": true,
    "statusFilter": [
      "UPCOMING"
    ],
    "tagCodes": [
      "T1"
    ],
    "tags": true
  },
  "family_min": {
    "address": false,
    "allergies": false,
    "classroom": false,
    "dietRestriction": false,
    "dob": false,
    "endDate": "2026-02-03",
    "enrollDate": false,
    "format": "PDF",
    "fullName": false,
    "guardianEmail": false,
    "guardianEmergencyContact": false,
    "guardianFirstName": false,
    "guardianLastName": false,
    "guardianPhoneNumber": false,
    "guardianRelation": false,
    "guardianSignInPin": false,
    "medications": false,
    "note": false,
    "pickupEmail": false,
    "pickupEmergencyContact": false,
    "pickupFirstName": false,
    "pickupLastName": false,
    "pickupPhoneNumber": false,
    "pickupRelation": false,
    "pickupSignInPin": false,
    "reportType": "STUDENTS_AND_FAMILY",
    "schedule": false,
    "schoolLeavingDate": false,
    "schoolName": "Sunny School",
    "startDate": "2026-01-02",
    "status": false,
    "statusFilter": [
      "ACTIVE"
    ],
    "tags": false
  },
  "immunization_emptyLists": {
    "endDate": "2026-02-03",
    "format": "PDF",
    "includeParentEmail": true,
    "includeParentName": false,
    "reportType": "IMMUNIZATION",
    "schoolName": "",
    "startDate": "2026-01-02",
    "statusFilter": [],
    "vaccineCodes": []
  },
  "immunization_full": {
    "endDate": "2026-02-03",
    "format": "XLSX",
    "includeParentEmail": true,
    "includeParentName": true,
    "reportType": "IMMUNIZATION",
    "roomCodes": [
      "R1"
    ],
    "schoolName": "Sunny School",
    "startDate": "2026-01-02",
    "statusFilter": [
      "ACTIVE",
      "UPCOMING"
    ],
    "tagCodes": [
      "T1"
    ],
    "vaccineCodes": [
      "DTaP",
      "MMR"
    ]
  },
  "immunization_min": {
    "endDate": "2026-02-03",
    "format": "PDF",
    "includeParentEmail": false,
    "includeParentName": false,
    "reportType": "IMMUNIZATION",
    "schoolName": "Sunny School",
    "startDate": "2026-01-02",
    "statusFilter": [
      "ACTIVE"
    ],
    "vaccineCodes": [
      "DTaP"
    ]
  },
  "req_billingInvoice_full": {
    "classroomCodes": [
      "R1",
      "R2"
    ],
    "dateFrom": "2026-01-02T03:04:05.000Z",
    "dateTo": "2026-02-03T06:07:08.000Z",
    "format": "XLSX",
    "invoiceStatuses": [
      "Paid"
    ],
    "paymentMethods": [
      "ACH"
    ],
    "periodType": "MONTHLY",
    "reportType": "INVOICE",
    "schoolName": "Sunny School",
    "studentCodes": [
      "S1"
    ],
    "transactionStatuses": [
      "OK"
    ],
    "transactionTypes": [
      "CARD"
    ]
  },
  "req_billingOutstanding": {
    "asOfDate": "2026-01-02T03:04:05.000Z",
    "format": "XLSX",
    "reportType": "OUTSTANDING",
    "schoolName": "Sunny School"
  },
  "req_billingRefund_roomCodesDropped": {
    "dateFrom": "2026-01-02T03:04:05.000Z",
    "format": "",
    "reportType": "REFUND"
  },
  "req_dailyAttendance_min": {
    "date": "2026-01-02",
    "format": "",
    "reportType": "STUDENT_DAILY_ATTENDANCE",
    "schoolName": "Sunny School"
  },
  "req_dailyAttendance_withDate": {
    "date": "2026-03-04",
    "format": "PDF",
    "reportType": "STUDENT_DAILY_ATTENDANCE",
    "schoolName": "Sunny School"
  },
  "req_emptyOptionalLists": {
    "format": "",
    "reportType": "SCHOOL_INCIDENT",
    "roomCodes": [],
    "schoolName": "Sunny School",
    "startDate": "2026-01-02",
    "studentCodes": [],
    "tagCodes": []
  },
  "req_immunization_classroomCodes": {
    "classroomCodes": [
      "R1"
    ],
    "endDate": "2026-02-03",
    "format": "",
    "grouping": "CLASS",
    "reportType": "IMMUNIZATION",
    "schoolName": "Sunny School",
    "search": "needle",
    "startDate": "2026-01-02"
  },
  "req_staffAbsent_roomCodes": {
    "endDate": "2026-02-03",
    "format": "",
    "reportType": "STAFF_ABSENT",
    "roomCodes": [
      "R1"
    ],
    "schoolName": "Sunny School",
    "staffCodes": [
      "ST1"
    ],
    "startDate": "2026-01-02"
  },
  "req_studentAbsent_roomCodes": {
    "endDate": "2026-02-03",
    "format": "",
    "reportType": "STUDENT_ABSENT",
    "roomCodes": [
      "R1"
    ],
    "startDate": "2026-01-02",
    "tagCodes": [
      "T1"
    ]
  },
  "staffDetails_activeStaff": {
    "format": "PDF",
    "includeAddress": false,
    "includeCdaExpirationDate": false,
    "includeClockInOutPin": false,
    "includeCprExpirationDate": false,
    "includeDateOfBirth": false,
    "includeDesignation": false,
    "includeEmailId": false,
    "includeHireDate": false,
    "includeIsActive": false,
    "includeLastPhysicalDate": false,
    "includeName": true,
    "includePhoneNumber": false,
    "includePrimaryClassroom": false,
    "reportType": "STAFF_DETAILS",
    "schoolName": "Sunny School",
    "status": "ACTIVE"
  },
  "staffDetails_full": {
    "classroomCodes": [
      "R1",
      "R2"
    ],
    "format": "XLSX",
    "includeAddress": true,
    "includeCdaExpirationDate": true,
    "includeClockInOutPin": true,
    "includeCprExpirationDate": true,
    "includeDateOfBirth": true,
    "includeDesignation": true,
    "includeEmailId": true,
    "includeHireDate": true,
    "includeIsActive": true,
    "includeLastPhysicalDate": true,
    "includeName": true,
    "includePhoneNumber": true,
    "includePrimaryClassroom": true,
    "reportType": "STAFF_DETAILS",
    "schoolName": "Sunny School",
    "status": "ACTIVE"
  },
  "staffDetails_inactive_emptyRooms": {
    "format": "PDF",
    "includeAddress": false,
    "includeCdaExpirationDate": false,
    "includeClockInOutPin": false,
    "includeCprExpirationDate": false,
    "includeDateOfBirth": false,
    "includeDesignation": false,
    "includeEmailId": false,
    "includeHireDate": false,
    "includeIsActive": false,
    "includeLastPhysicalDate": false,
    "includeName": true,
    "includePhoneNumber": false,
    "includePrimaryClassroom": false,
    "reportType": "STAFF_DETAILS",
    "schoolName": "Sunny School",
    "status": "INACTIVE"
  },
  "staffDetails_min": {
    "format": "PDF",
    "includeAddress": false,
    "includeCdaExpirationDate": false,
    "includeClockInOutPin": false,
    "includeCprExpirationDate": false,
    "includeDateOfBirth": false,
    "includeDesignation": false,
    "includeEmailId": false,
    "includeHireDate": false,
    "includeIsActive": false,
    "includeLastPhysicalDate": false,
    "includeName": false,
    "includePhoneNumber": false,
    "includePrimaryClassroom": false,
    "reportType": "STAFF_DETAILS",
    "schoolName": "Sunny School",
    "status": "ACTIVE"
  },
  "staffSchedule_emptyRooms": {
    "endDate": "2026-02-03",
    "format": "PDF",
    "reportType": "STAFF_SCHEDULING",
    "schoolName": "Sunny School",
    "startDate": "2026-01-02"
  },
  "staffSchedule_full": {
    "classroomCodes": [
      "R1"
    ],
    "endDate": "2026-02-03",
    "format": "XLSX",
    "reportType": "STAFF_SCHEDULING",
    "schoolName": "Sunny School",
    "startDate": "2026-01-02"
  },
  "staffSchedule_min": {
    "endDate": "2026-02-03",
    "format": "PDF",
    "reportType": "STAFF_SCHEDULING",
    "schoolName": "Sunny School",
    "startDate": "2026-01-02"
  }
}
''';

void main() {
  final golden = jsonDecode(goldenJson) as Map<String, dynamic>;

  group('report request payloads are unchanged by the model migration', () {
    fixtures().forEach((name, params) {
      test(name, () {
        expect(
          ReportRequestPayload.fromParams(params).toJson(),
          golden[name],
          reason: 'payload for $name drifted from the pre-migration golden',
        );
      });
    });
  });

  test('every fixture is covered by a golden', () {
    expect(fixtures().keys.toSet(), golden.keys.toSet());
  });
}
