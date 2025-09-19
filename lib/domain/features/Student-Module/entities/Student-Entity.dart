import 'package:equatable/equatable.dart';

import '../../../../data/features/Student-Module/Student-Module-Models/invoice_dto_model.dart';
import '../../../../data/features/Student-Module/Student-Module-Models/schedule_data_model.dart';
import '../../../../data/features/Student-Module/Student-Module-Models/transaction_dto_model.dart';

class StudentEntity extends Equatable {
  final int id;
  final String fullName;
  final String photoUuid;
  final String? gender;
  final String? bloodGroup;
  final String? studentUniqueId;
  final String dateOfBirth;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String napStartOrEnd;
  final String movementDate;
  final double? studentFte;
  final String? foodProgram;
  final String registrationDate;
  final String? leavingDate;
  final String? roomStartDate;
  final String profileStatus;
  final String allergies;
  final String medications;
  final String dietRestriction;
  final bool isPhotoPermission;
  final String note;
  final int roomId;
  final String status;
  final int schoolId;
  final String lastModified;
  final String lastModifiedBy;
  final bool hasPrivateChat;
  final bool? isTagRemoved;
  final int? privatedByGuardian;
  final double subsidyInvoiced;
  final double subsidyBalance;
  final double subsidyReceived;
  final String? childCustody;
  final String? startDate;
  final String? expectedMoveDate;
  final bool isStateSubsidyAllowed;
  final List<Tag> tags;
  final List<String> siblings;
  final List<ActivityEntity> activities;
  final List<ScheduleDataModel> schedule;
  final List<TransactionDTO> transactions;
  final String? programRoom;
  final double openBalance;
  final String roomName;
  final List<InvoiceDTO> invoice;
  final List<int> students;
  final List<String> recurringPlan;
  final String? paymentMode;

  const StudentEntity({
    required this.id,
    required this.fullName,
    required this.photoUuid,
    required this.gender,
    required this.bloodGroup,
    required this.studentUniqueId,
    required this.dateOfBirth,
    required this.isSignedIn,
    required this.isAbsent,
    required this.isExpectedToday,
    required this.isPresentToday,
    required this.napStartOrEnd,
    required this.movementDate,
    required this.studentFte,
    required this.foodProgram,
    required this.isPhotoPermission,
    required this.registrationDate,
    required this.leavingDate,
    required this.roomStartDate,
    required this.profileStatus,
    required this.allergies,
    required this.medications,
    required this.dietRestriction,
    required this.note,
    required this.roomId,
    required this.status,
    required this.schoolId,
    required this.lastModified,
    required this.lastModifiedBy,
    required this.hasPrivateChat,
    required this.isTagRemoved,
    required this.privatedByGuardian,
    required this.subsidyInvoiced,
    required this.subsidyBalance,
    required this.subsidyReceived,
    required this.childCustody,
    required this.startDate,
    required this.expectedMoveDate,
    required this.isStateSubsidyAllowed,
    required this.tags,
    required this.siblings,
    required this.activities,
    required this.schedule,
    required this.transactions,
    required this.programRoom,
    required this.openBalance,
    required this.roomName,
    required this.invoice,
    required this.students,
    required this.recurringPlan,
    this.paymentMode,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    photoUuid,
    gender,
    bloodGroup,
    studentUniqueId,
    dateOfBirth,
    isSignedIn,
    isAbsent,
    isExpectedToday,
    isPresentToday,
    napStartOrEnd,
    movementDate,
    studentFte,
    foodProgram,
    registrationDate,
    leavingDate,
    roomStartDate,
    profileStatus,
    allergies,
    medications,
    dietRestriction,
    note,
    isPhotoPermission,
    roomId,
    status,
    schoolId,
    lastModified,
    lastModifiedBy,
    hasPrivateChat,
    isTagRemoved,
    privatedByGuardian,
    subsidyInvoiced,
    subsidyBalance,
    subsidyReceived,
    childCustody,
    startDate,
    expectedMoveDate,
    isStateSubsidyAllowed,
    tags,
    siblings,
    activities,
    schedule,
    transactions,
    programRoom,
    openBalance,
    roomName,
    invoice,
    students,
    recurringPlan,
    paymentMode,
  ];

  static const empty = StudentEntity(
    id: 0,
    fullName: '',
    photoUuid: '',
    gender: null,
    bloodGroup: null,
    studentUniqueId: null,
    dateOfBirth: '',
    isSignedIn: false,
    isAbsent: false,
    isExpectedToday: false,
    isPresentToday: false,
    napStartOrEnd: '',
    movementDate: '',
    studentFte: null,
    foodProgram: null,
    registrationDate: '',
    leavingDate: null,
    roomStartDate: null,
    profileStatus: '',
    allergies: '',
    medications: '',
    dietRestriction: '',
    isPhotoPermission: false,
    note: '',
    roomId: 0,
    status: '',
    schoolId: 0,
    lastModified: '',
    lastModifiedBy: '',
    hasPrivateChat: false,
    isTagRemoved: null,
    privatedByGuardian: null,
    subsidyInvoiced: 0.0,
    subsidyBalance: 0.0,
    subsidyReceived: 0.0,
    childCustody: null,
    startDate: null,
    expectedMoveDate: null,
    isStateSubsidyAllowed: false,
    tags: [],
    siblings: [],
    activities: [],
    schedule: [],
    transactions: [],
    programRoom: null,
    openBalance: 0.0,
    roomName: '',
    invoice: [],
    students: [],
    recurringPlan: [],
    paymentMode: null,
  );

  static final demo = StudentEntity(
    id: 1,
    fullName: 'John Doe',
    photoUuid: 'photo-uuid-123',
    gender: 'Male',
    bloodGroup: 'A+',
    studentUniqueId: 'STU001',
    dateOfBirth: '2018-05-15',
    isSignedIn: true,
    isAbsent: false,
    isExpectedToday: true,
    isPresentToday: true,
    napStartOrEnd: '12:00 PM',
    movementDate: '2025-09-01',
    studentFte: 1.0,
    foodProgram: 'Lunch Program',
    registrationDate: '2024-08-01',
    leavingDate: null,
    roomStartDate: '2024-08-01',
    profileStatus: 'Active',
    allergies: 'Peanuts',
    medications: 'None',
    dietRestriction: 'Vegetarian',
    isPhotoPermission: true,
    note: 'Loves painting',
    roomId: 101,
    status: 'Enrolled',
    schoolId: 1,
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
    hasPrivateChat: true,
    isTagRemoved: false,
    privatedByGuardian: null,
    subsidyInvoiced: 500.0,
    subsidyBalance: 200.0,
    subsidyReceived: 300.0,
    childCustody: 'Joint',
    startDate: '2024-08-01',
    expectedMoveDate: null,
    isStateSubsidyAllowed: true,
    tags: const [Tag.demo],
    siblings: const ['STU002'],
    activities: const [ActivityEntity.demo],
    schedule: const [ScheduleDataModel.demo],
    transactions: [TransactionDTO.demo],
    programRoom: 'Room A',
    openBalance: 150.0,
    roomName: 'Kindergarten A',
    invoice: const [InvoiceDTO.demo],
    students: const [2, 3],
    recurringPlan: const ['Monthly'],
    paymentMode: 'Credit Card',
  );
}

// -------------------------
// Activity Entity
// -------------------------
class ActivityEntity extends Equatable {
  final String lastModified;
  final String lastModifiedBy;
  final int schoolId;
  final int id;
  final String date;
  final String description;
  final String activityNote;
  final bool hasStaffOnly;
  final bool isDiaperCreamApplied;
  final String time;
  final bool hasParentNotify;
  final String activityRefValue1;
  final String activityRefValue2;
  final String activityRefValue3;
  final int activityTypeId;
  final int staffId;
  final String status;
  final String activityStatus;
  final String? photoUuid;
  final int roomId;
  final List<int> students;
  final bool absent;
  final int attendance;

  const ActivityEntity({
    required this.lastModified,
    required this.lastModifiedBy,
    required this.schoolId,
    required this.id,
    required this.date,
    required this.description,
    required this.activityNote,
    required this.hasStaffOnly,
    required this.isDiaperCreamApplied,
    required this.time,
    required this.hasParentNotify,
    required this.activityRefValue1,
    required this.activityRefValue2,
    required this.activityRefValue3,
    required this.activityTypeId,
    required this.staffId,
    required this.status,
    required this.activityStatus,
    required this.photoUuid,
    required this.roomId,
    required this.students,
    required this.absent,
    required this.attendance,
  });

  @override
  List<Object?> get props => [
    lastModified,
    lastModifiedBy,
    schoolId,
    id,
    date,
    description,
    activityNote,
    hasStaffOnly,
    isDiaperCreamApplied,
    time,
    hasParentNotify,
    activityRefValue1,
    activityRefValue2,
    activityRefValue3,
    activityTypeId,
    staffId,
    status,
    activityStatus,
    photoUuid,
    roomId,
    students,
    absent,
    attendance,
  ];

  static const empty = ActivityEntity(
    lastModified: '',
    lastModifiedBy: '',
    schoolId: 0,
    id: 0,
    date: '',
    description: '',
    activityNote: '',
    hasStaffOnly: false,
    isDiaperCreamApplied: false,
    time: '',
    hasParentNotify: false,
    activityRefValue1: '',
    activityRefValue2: '',
    activityRefValue3: '',
    activityTypeId: 0,
    staffId: 0,
    status: '',
    activityStatus: '',
    photoUuid: null,
    roomId: 0,
    students: [],
    absent: false,
    attendance: 0,
  );

  static const demo = ActivityEntity(
    lastModified: '2025-09-18',
    lastModifiedBy: 'Teacher Jane',
    schoolId: 1,
    id: 1,
    date: '2025-09-18',
    description: 'Art Class',
    activityNote: 'Created a watercolor painting',
    hasStaffOnly: false,
    isDiaperCreamApplied: false,
    time: '10:00 AM',
    hasParentNotify: true,
    activityRefValue1: 'Painting',
    activityRefValue2: 'Watercolor',
    activityRefValue3: 'Beginner',
    activityTypeId: 1,
    staffId: 101,
    status: 'Completed',
    activityStatus: 'Active',
    photoUuid: 'photo-uuid-act1',
    roomId: 101,
    students: [1, 2],
    absent: false,
    attendance: 10,
  );
}

// -------------------------
// Tag Entity
// -------------------------
class Tag extends Equatable {
  final int id;
  final String name;
  final int? schoolId;
  final String? status;
  final String? lastModified;
  final String? lastModifiedBy;

  const Tag({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.status,
    required this.lastModified,
    required this.lastModifiedBy,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    schoolId,
    status,
    lastModified,
    lastModifiedBy,
  ];

  static const empty = Tag(
    id: 0,
    name: '',
    schoolId: null,
    status: null,
    lastModified: null,
    lastModifiedBy: null,
  );

  static const demo = Tag(
    id: 1,
    name: 'Creative',
    schoolId: 1,
    status: 'Active',
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
  );
}

// -------------------------
// CopyWith Extension for Dummy Data
// -------------------------
extension StudentEntityCopy on StudentEntity {
  StudentEntity copyWith({
    int? id,
    String? fullName,
    String? photoUuid,
    String? gender,
    String? bloodGroup,
    String? studentUniqueId,
    String? dateOfBirth,
    bool? isSignedIn,
    bool? isAbsent,
    bool? isExpectedToday,
    bool? isPresentToday,
    String? napStartOrEnd,
    String? movementDate,
    double? studentFte,
    String? foodProgram,
    String? registrationDate,
    String? leavingDate,
    String? roomStartDate,
    String? profileStatus,
    String? allergies,
    String? medications,
    String? dietRestriction,
    bool? isPhotoPermission,
    String? note,
    int? roomId,
    String? status,
    int? schoolId,
    String? lastModified,
    String? lastModifiedBy,
    bool? hasPrivateChat,
    bool? isTagRemoved,
    int? privatedByGuardian,
    double? subsidyInvoiced,
    double? subsidyBalance,
    double? subsidyReceived,
    String? childCustody,
    String? startDate,
    String? expectedMoveDate,
    bool? isStateSubsidyAllowed,
    List<Tag>? tags,
    List<String>? siblings,
    List<ActivityEntity>? activities,
    List<ScheduleDataModel>? schedule,
    List<TransactionDTO>? transactions,
    String? programRoom,
    double? openBalance,
    String? roomName,
    List<InvoiceDTO>? invoice,
    List<int>? students,
    List<String>? recurringPlan,
    String? paymentMode,
  }) {
    return StudentEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      photoUuid: photoUuid ?? this.photoUuid,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      studentUniqueId: studentUniqueId ?? this.studentUniqueId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isAbsent: isAbsent ?? this.isAbsent,
      isExpectedToday: isExpectedToday ?? this.isExpectedToday,
      isPresentToday: isPresentToday ?? this.isPresentToday,
      napStartOrEnd: napStartOrEnd ?? this.napStartOrEnd,
      movementDate: movementDate ?? this.movementDate,
      studentFte: studentFte ?? this.studentFte,
      foodProgram: foodProgram ?? this.foodProgram,
      registrationDate: registrationDate ?? this.registrationDate,
      leavingDate: leavingDate ?? this.leavingDate,
      roomStartDate: roomStartDate ?? this.roomStartDate,
      profileStatus: profileStatus ?? this.profileStatus,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      dietRestriction: dietRestriction ?? this.dietRestriction,
      isPhotoPermission: isPhotoPermission ?? this.isPhotoPermission,
      note: note ?? this.note,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      schoolId: schoolId ?? this.schoolId,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      hasPrivateChat: hasPrivateChat ?? this.hasPrivateChat,
      isTagRemoved: isTagRemoved ?? this.isTagRemoved,
      privatedByGuardian: privatedByGuardian ?? this.privatedByGuardian,
      subsidyInvoiced: subsidyInvoiced ?? this.subsidyInvoiced,
      subsidyBalance: subsidyBalance ?? this.subsidyBalance,
      subsidyReceived: subsidyReceived ?? this.subsidyReceived,
      childCustody: childCustody ?? this.childCustody,
      startDate: startDate ?? this.startDate,
      expectedMoveDate: expectedMoveDate ?? this.expectedMoveDate,
      isStateSubsidyAllowed:
          isStateSubsidyAllowed ?? this.isStateSubsidyAllowed,
      tags: tags ?? this.tags,
      siblings: siblings ?? this.siblings,
      activities: activities ?? this.activities,
      schedule: schedule ?? this.schedule,
      transactions: transactions ?? this.transactions,
      programRoom: programRoom ?? this.programRoom,
      openBalance: openBalance ?? this.openBalance,
      roomName: roomName ?? this.roomName,
      invoice: invoice ?? this.invoice,
      students: students ?? this.students,
      recurringPlan: recurringPlan ?? this.recurringPlan,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }
}

// -------------------------
// Dummy Students List
// -------------------------
final List<StudentEntity> dummyStudents = [
  StudentEntity.demo,
  StudentEntity.demo.copyWith(
    id: 2,
    fullName: 'Emma Watson',
    studentUniqueId: 'STU002',
    roomName: 'Kindergarten B',
    gender: 'Female',
    bloodGroup: 'B+',
    photoUuid: 'photo-uuid-456',
    allergies: 'None',
    medications: 'Asthma Inhaler',
    dietRestriction: 'Gluten Free',
    profileStatus: 'Upcoming',
  ),
  StudentEntity.demo.copyWith(
    id: 3,
    fullName: 'Liam Johnson',
    studentUniqueId: 'STU003',
    roomName: 'Preschool A',
    gender: 'Male',
    bloodGroup: 'O-',
    photoUuid: 'photo-uuid-789',
    allergies: 'Milk',
    medications: 'None',
    dietRestriction: '',
    profileStatus: 'Active',
  ),
];
