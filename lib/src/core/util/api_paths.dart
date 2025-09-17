// enum APIPath {
//   authenticate,
//   account,
//   userCount,
//   access,
//   staff,
//   room,
//   roomData,
//   countRoomDashboard,
//   totalRoomsData,
//   document,
//   documentdowload,
//   schooldata,
//   totalTransactions,
//   attendances,
//   totalAttendance,
//   absent,
//   absentStaff,
//   markAbsent,
//   masterlookup,
//   tag,
//   totalAbsentDays,
//   expectedStaff,
//   student,
//   studentsAbsent,
//   address,
//   expectedStudents,
//   physicalTracker,
//   regeneratePin,
//   school,
//   dailyActivity,
//   activityFeed,
//   photogallary,
//   activitiesCreate,
//   guardian,
//   physician,
//   authorizedPickups,
//   documentUpload,
//   messages,
//   createstaffmessages,
//   newsletters,
//   activitiesByStudent,
//   newslettersWithTagandRoom,
//   schedule,
//   generateEmailPin,
//   createstudentmessages,
//   parentDashboardData,
//   assignStudentToClassroom,
//   attendanceReport,
//   documents,
//   documentsdownload,
//   validateKioskPin,
//   validateScanner,
//   downloadByName,
//   payslip,
//   salaries,
//   documentsUpload,
//   employee,
//   holiday,
//   attendance,
//   timesheets,
//   punchinpunchout,
//   personalDetails,
//   employeeLeaveAccount,
//   totalEmployeeCount,
//   onLeaveEmployeeCount,
//   trainings,
//   bankDetails,
//   emergencyContact,
//   familyDetails,
//   educationDetails,
//   experienceDetails,
//   assetInventories,
//   masterLookups,
//   leaveApplication,
//   assetApplications,
//   formValidator,
//   designation,
//   department,
//   leaveType,
//   assignStaffToClassroom,
//   immunizations,
//   vaccines,
//   scheduleDoses,
//   staffSchedules,
//   invoiceDetails,
//   studentsInvoices,
//   specificUserIds,
//   futureEnrollments,
//   availableCount,
//   transactions,
//   yearlyRevenue,
//   physicalTrackers,
//   weeklyScheduleSummary,
//   weeklyRoomSchedule,
//   workingDays,
//   classRoomScheduleWeeklyRatio,
//   createSchoolPaymentGateway,
//   paymentGatewayMerchantSettings,
//   paymentGatewayTransactions,
//   ledgerAccounts,
// }

// class APIPathHelper {
//   static String getValue(APIPath path) {
//     switch (path) {
//       case APIPath.access:
//         return "api/auth/login";

//       case APIPath.account:
//         return "api/account";

//       case APIPath.userCount:
//         return "api/user/count";

//       case APIPath.room:
//         return "api/rooms";

//       case APIPath.totalAbsentDays:
//         return "api/absents/total-absent-days";

//       case APIPath.staff:
//         return "api/staff";

//       case APIPath.roomData:
//         return "api/rooms-data";

//       case APIPath.countRoomDashboard:
//         return "api/dashboard/count-rooms";

//       case APIPath.totalRoomsData:
//         return "api/total-rooms-data";

//       case APIPath.document:
//         return "api/documents";

//       case APIPath.documents:
//         return "api/documents";

//       case APIPath.documentdowload:
//         return "api/documents-download";

//       case APIPath.documentUpload:
//         return "api/documents-upload";

//       case APIPath.schooldata:
//         return "api/schools/school-data";

//       case APIPath.totalTransactions:
//         return "api/transactions/total-transactions";

//       case APIPath.attendances:
//         return "api/attendances";

//       case APIPath.totalAttendance:
//         return "api/attendances/total-attended-hours";

//       case APIPath.absent:
//         return "api/absents-all";

//       case APIPath.attendanceReport:
//         return "api/attendance-report";

//       case APIPath.absentStaff:
//         return "api/absent-staff";

//       case APIPath.markAbsent:
//         return "api/absents";

//       case APIPath.masterlookup:
//         return "api/master-lookups";

//       case APIPath.tag:
//         return "api/tags";

//       case APIPath.expectedStaff:
//         return "api/expected-staff";

//       case APIPath.student:
//         return "api/students";

//       case APIPath.studentsAbsent:
//         return "api/students-absent";

//       case APIPath.address:
//         return "api/addresses";

//       case APIPath.expectedStudents:
//         return "api/expected-students";

//       case APIPath.physicalTracker:
//         return "api/physical-trackers";

//       case APIPath.regeneratePin:
//         return "api/guardians/update-pin-and-send-email";

//       case APIPath.school:
//         return "api/schools";

//       case APIPath.dailyActivity:
//         return "api/activity-types";

//       case APIPath.activityFeed:
//         return "api/activities-feed";

//       case APIPath.photogallary:
//         return "api/documents-download/day";

//       case APIPath.activitiesCreate:
//         return "api/activities";

//       case APIPath.activitiesByStudent:
//         return "api/activities-by-student";

//       case APIPath.guardian:
//         return "api/guardians";

//       case APIPath.physician:
//         return "api/physicians";

//       case APIPath.authorizedPickups:
//         return "api/authorized-pickups";

//       case APIPath.messages:
//         return "api/messages";

//       case APIPath.createstaffmessages:
//         return "api/messages-list/staff";

//       case APIPath.newsletters:
//         return "api/newsletters";

//       case APIPath.newslettersWithTagandRoom:
//         return "api/newsletters-with-room-tag-ids";
//       case APIPath.schedule:
//         return "api/schedules";

//       case APIPath.generateEmailPin:
//         return "api/guardians/sign-in-pin/separate";

//       case APIPath.parentDashboardData:
//         return "api/parent-dashboard/count";

//       case APIPath.documentsdownload:
//         return "api/documents-download";

//       case APIPath.assignStudentToClassroom:
//         return "api/students-batch-update";

//       case APIPath.assignStaffToClassroom:
//         return "api/staff-batch-update";

//       case APIPath.physicalTrackers:
//         return "api/physical-trackers";

//       case APIPath.immunizations:
//         return "api/immunizations";

//       case APIPath.vaccines:
//         return "api/vaccines";

//       case APIPath.scheduleDoses:
//         return "api/schedule-doses";

//       case APIPath.staffSchedules:
//         return "api/staff-schedules";

//       case APIPath.validateScanner:
//         return "api/validate";

//       case APIPath.validateKioskPin:
//         return "api/user-validate-pin";

//       case APIPath.invoiceDetails:
//         return "api/invoice-details";

//       case APIPath.transactions:
//         return "api/transactions";

//       case APIPath.studentsInvoices:
//         return "api/invoices/all-students-invoices";

//       case APIPath.specificUserIds:
//         return "api/specific-user-ids";

//       case APIPath.yearlyRevenue:
//         return "api/transactions/yearly-revenue";

//       case APIPath.weeklyScheduleSummary:
//         return "api/staff-shifts/weekly-schedule-summary";

//       case APIPath.weeklyRoomSchedule:
//         return "api/weekly-room-schedule";

//       case APIPath.classRoomScheduleWeeklyRatio:
//         return "api/classroom-schedule/weekly-ratio/all";

//       case APIPath.futureEnrollments:
//         return "api/future-enrollments";

//       case APIPath.availableCount:
//         return "${APIPathHelper.getValue(APIPath.futureEnrollments)}/available-count";

//       case APIPath.workingDays:
//         return "api/working-days";

//       case APIPath.createSchoolPaymentGateway:
//         return "api/v1/school-payment-gateway/createSchoolPaymentGateway";

//       case APIPath.paymentGatewayMerchantSettings:
//         return "api/v1/payment-gateway-merchant-settings";

//       case APIPath.paymentGatewayTransactions:
//         return "api/v1/payment-gateway-transactions";

//       case APIPath.ledgerAccounts:
//         return "api/ledger-accounts";

//       default:
//         return "";
//     }
//   }
// }

enum APIPath {
  authenticate,
  account,
  userCount,
  access,
  staff,
  room,
  roomData,
  countRoomDashboard,
  totalRoomsData,
  document,
  activitiesByStudent,
  documentdowload,
  schooldata,
  studentsByRoom,
  physicalTrackers,
  totalTransactions,
  attendances,
  totalAttendance,
  absent,
  napping,
  absentStaff,
  markAbsent,
  masterlookup,
  tag,
  totalAbsentDays,
  expectedStaff,
  student,
  studentsParents,
  studentsAbsent,
  address,
  expectedStudents,
  physicalTracker,
  regeneratePin,
  school,
  dailyActivity,
  activityFeed,
  photogallary,
  activitiesCreate,
  guardian,
  physician,
  authorizedPickups,
  documentUpload,
  messages,
  createstaffmessages,
  newsletters,
  newslettersWithTagandRoom,
  schedule,
  generateEmailPin,
  createstudentmessages,
  parentDashboardData,
  assignStudentToClassroom,
  attendanceReport,
  documents,
  documentsdownload,
  validateKioskPin,
  validateScanner,
  downloadByName,
  payslip,
  salaries,
  documentsUpload,
  employee,
  holiday,
  attendance,
  timesheets,
  punchinpunchout,
  personalDetails,
  employeeLeaveAccount,
  totalEmployeeCount,
  onLeaveEmployeeCount,
  trainings,
  getAbsentStudents,
  getPresentStudents,
  bankDetails,
  emergencyContact,
  familyDetails,
  educationDetails,
  experienceDetails,
  assetInventories,
  leaveApplication,
  assetApplications,
  formValidator,
  designation,
  department,
  leaveType,
  assignStaffToClassroom,
  immunizations,
  vaccines,
  scheduleDoses,
  staffSchedules,
  invoiceDetails,
  invoiceDetailsById,
  studentsInvoices,
  createInvoice,
  sendInvoice,
  specificUserIds,
  futureEnrollments,
  availableCount,
  transactions,
  transactionsWithIds,
  yearlyRevenue,
  weeklyScheduleSummary,
  weeklyRoomSchedule,
  workingDays,
  classRoomScheduleWeeklyRatio,
  createSchoolPaymentGateway,
  paymentGatewayMerchantSettings,
  paymentGatewayTransactions,
  ledgerAccounts,
  ledgerAccountById,
  recurringPlans,
  recurringPlansStudentList,
  recurringPlansStudentsMultiple,
  studentsList,
  billingItemSettings,
  allStudentsInvoicesNoSibling,
  pauseResumePlan,
  cancelPlan,
  studentsWithAssignedRecurringPlans,
  assignedPlan,
}

class APIPathHelper {
  static String getValue(APIPath path) {
    switch (path) {
      case APIPath.access:
        return "api/auth/login";

      case APIPath.account:
        return "api/account";

      case APIPath.recurringPlansStudentList:
        return "api/recurring-plans/student-list";

      case APIPath.userCount:
        return "api/user/count";

      case APIPath.room:
        return "api/rooms";

      case APIPath.totalAbsentDays:
        return "api/absents/total-absent-days";

      case APIPath.staff:
        return "api/staff";

      case APIPath.roomData:
        return "api/rooms-data";

      case APIPath.countRoomDashboard:
        return "api/dashboard/count-rooms";

      case APIPath.totalRoomsData:
        return "api/total-rooms-data";

      case APIPath.document:
        return "api/documents";

      case APIPath.documents:
        return "api/documents";

      case APIPath.documentdowload:
        return "api/documents-download";

      case APIPath.documentUpload:
        return "api/documents-upload";

      case APIPath.schooldata:
        return "api/schools/school-data";

      case APIPath.physicalTrackers:
        return "api/physical-trackers";

      case APIPath.getAbsentStudents:
        return "api/absents-all";

      case APIPath.getPresentStudents:
        return "api/attendances";

      case APIPath.totalTransactions:
        return "api/transactions/total-transactions";

      case APIPath.attendances:
        return "api/attendances";

      case APIPath.totalAttendance:
        return "api/attendances/total-attended-hours";

      case APIPath.absent:
        return "api/absents-all";

      case APIPath.attendanceReport:
        return "api/attendance-report";

      case APIPath.absentStaff:
        return "api/absent-staff";

      case APIPath.markAbsent:
        return "api/absents";

      case APIPath.masterlookup:
        return "api/master-lookups";

      case APIPath.tag:
        return "api/tags";

      case APIPath.expectedStaff:
        return "api/expected-staff";

      case APIPath.student:
        return "api/students";

      case APIPath.studentsParents:
        return "api/students-parents";

      case APIPath.studentsAbsent:
        return "api/students-absent";

      case APIPath.address:
        return "api/addresses";

      case APIPath.expectedStudents:
        return "api/expected-students";

      case APIPath.physicalTracker:
        return "api/physical-trackers";

      case APIPath.studentsByRoom:
        return "api/students-by-room";

      case APIPath.regeneratePin:
        return "api/guardians/update-pin-and-send-email";

      case APIPath.school:
        return "api/schools"; //api/schools/

      case APIPath.dailyActivity:
        return "api/activity-types";

      case APIPath.activityFeed:
        return "api/activities-feed";

      case APIPath.photogallary:
        return "api/documents-download/day";

      case APIPath.activitiesCreate:
        return "api/activities";

      case APIPath.guardian:
        return "api/guardians";

      case APIPath.physician:
        return "api/physicians";

      case APIPath.authorizedPickups:
        return "api/authorized-pickups";

      case APIPath.messages:
        return "api/messages";

      case APIPath.createstaffmessages:
        return "api/messages-list/staff";

      case APIPath.newsletters:
        return "api/newsletters";

      case APIPath.newslettersWithTagandRoom:
        return "api/newsletters-with-room-tag-ids";
      case APIPath.schedule:
        return "api/schedules";

      case APIPath.generateEmailPin:
        return "api/guardians/sign-in-pin/separate";

      case APIPath.parentDashboardData:
        return "api/parent-dashboard/count";

      case APIPath.documentsdownload:
        return "api/documents-download";

      case APIPath.assignStudentToClassroom:
        return "api/students-batch-update";

      case APIPath.assignStaffToClassroom:
        return "api/staff-batch-update";

      case APIPath.immunizations:
        return "api/immunizations";

      case APIPath.vaccines:
        return "api/vaccines";

      case APIPath.napping:
        return "api/students-by-room";

      case APIPath.activitiesByStudent:
        return "api/activities-by-student";

      case APIPath.scheduleDoses:
        return "api/schedule-doses";

      case APIPath.staffSchedules:
        return "api/staff-schedules";

      case APIPath.validateScanner:
        return "api/validate";

      case APIPath.validateKioskPin:
        return "api/user-validate-pin";

      case APIPath.invoiceDetails:
        return "api/invoice-details";

      case APIPath.invoiceDetailsById:
        return "api/invoices";

      case APIPath.transactions:
        return "api/transactions";

      case APIPath.transactionsWithIds:
        return "api/transactions/transactions-with-ids";

      case APIPath.studentsInvoices:
        return "api/invoices/all-students-invoices";

      case APIPath.createInvoice:
        return "api/invoices";

      case APIPath.sendInvoice:
        return "api/invoices/send-invoice";

      case APIPath.specificUserIds:
        return "api/specific-user-ids";

      case APIPath.yearlyRevenue:
        return "api/transactions/yearly-revenue";

      case APIPath.weeklyScheduleSummary:
        return "api/staff-shifts/weekly-schedule-summary";

      case APIPath.weeklyRoomSchedule:
        return "api/weekly-room-schedule";

      case APIPath.classRoomScheduleWeeklyRatio:
        return "api/classroom-schedule/weekly-ratio/all";

      case APIPath.futureEnrollments:
        return "api/future-enrollments";

      case APIPath.availableCount:
        return "${APIPathHelper.getValue(APIPath.futureEnrollments)}/available-count";

      case APIPath.workingDays:
        return "api/working-days";

      case APIPath.createSchoolPaymentGateway:
        return "api/v1/school-payment-gateway/createSchoolPaymentGateway";

      case APIPath.paymentGatewayMerchantSettings:
        return "api/v1/payment-gateway-merchant-settings";

      case APIPath.paymentGatewayTransactions:
        return "api/v1/payment-gateway-transactions";

      case APIPath.ledgerAccounts:
        return "api/ledger-accounts";

      case APIPath.ledgerAccountById:
        return "api/ledger-accounts";

      case APIPath.recurringPlans:
        return "api/recurring-plans";

      case APIPath.recurringPlansStudentList:
        return "api/recurring-plans/student-list";

      case APIPath.recurringPlansStudentsMultiple:
        return "api/recurring-plans/students-multiple-recurring-plans";

      case APIPath.studentsList:
        return "api/invoices/students-list";

      case APIPath.billingItemSettings:
        return "api/billing-item-settings";

      case APIPath.allStudentsInvoicesNoSibling:
        return "api/invoices/all-students-invoices-no-sibling";

      case APIPath.pauseResumePlan:
        return "api/recurring-plans/pause-resume";

      case APIPath.cancelPlan:
        return "api/recurring-plans/deactivate";

      case APIPath.studentsWithAssignedRecurringPlans:
        return "api/recurring-plans/students-with-assigned-recurring-plans";

      case APIPath.assignedPlan:
        return "api/recurring-plans/assignedPlan";

      default:
        return "";
    }
  }
}
