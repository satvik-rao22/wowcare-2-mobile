part of 'school_status_cubit.dart';

enum SchoolStatusEnum { initial, loading, loaded, error }

class SchoolStatusState extends Equatable {
  const SchoolStatusState({
    required this.status,
    required this.schoolCode,
    required this.activeCount,
    required this.upcomingCount,
    required this.enrolledCount,
    required this.capacity,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.totalClassrooms,
    required this.adminClassrooms,
    required this.classroomClassrooms,
    required this.schoolFte,
    required this.staffExpected,
    required this.staffPresent,
    required this.staffAbsent,
    required this.staffSignOut,
    required this.staffNotMarked,
    required this.studentExpected,
    required this.studentPresent,
    required this.studentAbsent,
    required this.studentSignOut,
    required this.studentNotMarked,
    this.errorMessage,
  });

  const SchoolStatusState.initial()
      : status = SchoolStatusEnum.initial,
        schoolCode = '',
        activeCount = 0,
        upcomingCount = 0,
        enrolledCount = 0,
        capacity = 0,
        minAgeMonths = 0,
        maxAgeMonths = 0,
        totalClassrooms = 0,
        adminClassrooms = 0,
        classroomClassrooms = 0,
        schoolFte = 0.0,
        staffExpected = 0,
        staffPresent = 0,
        staffAbsent = 0,
        staffSignOut = 0,
        staffNotMarked = 0,
        studentExpected = 0,
        studentPresent = 0,
        studentAbsent = 0,
        studentSignOut = 0,
        studentNotMarked = 0,
        errorMessage = null;

  const SchoolStatusState.loaded({
    required String schoolCode,
    required int activeCount,
    required int upcomingCount,
    required int enrolledCount,
    required int capacity,
    required int minAgeMonths,
    required int maxAgeMonths,
    required int totalClassrooms,
    required int adminClassrooms,
    required int classroomClassrooms,
    required double schoolFte,
    required int staffExpected,
    required int staffPresent,
    required int staffAbsent,
    required int staffSignOut,
    required int staffNotMarked,
    required int studentExpected,
    required int studentPresent,
    required int studentAbsent,
    required int studentSignOut,
    required int studentNotMarked,
  })  : status = SchoolStatusEnum.loaded,
        schoolCode = schoolCode,
        activeCount = activeCount,
        upcomingCount = upcomingCount,
        enrolledCount = enrolledCount,
        capacity = capacity,
        minAgeMonths = minAgeMonths,
        maxAgeMonths = maxAgeMonths,
        totalClassrooms = totalClassrooms,
        adminClassrooms = adminClassrooms,
        classroomClassrooms = classroomClassrooms,
        schoolFte = schoolFte,
        staffExpected = staffExpected,
        staffPresent = staffPresent,
        staffAbsent = staffAbsent,
        staffSignOut = staffSignOut,
        staffNotMarked = staffNotMarked,
        studentExpected = studentExpected,
        studentPresent = studentPresent,
        studentAbsent = studentAbsent,
        studentSignOut = studentSignOut,
        studentNotMarked = studentNotMarked,
        errorMessage = null;

  final SchoolStatusEnum status;
  final String schoolCode;
  final int activeCount;
  final int upcomingCount;
  final int enrolledCount;
  final int capacity;
  final int minAgeMonths;
  final int maxAgeMonths;
  final int totalClassrooms;
  final int adminClassrooms;
  final int classroomClassrooms;
  final double schoolFte;
  final int staffExpected;
  final int staffPresent;
  final int staffAbsent;
  final int staffSignOut;
  final int staffNotMarked;
  final int studentExpected;
  final int studentPresent;
  final int studentAbsent;
  final int studentSignOut;
  final int studentNotMarked;
  final String? errorMessage;

  bool get isInitial => status == SchoolStatusEnum.initial;
  bool get isLoading => status == SchoolStatusEnum.loading;
  bool get isLoaded => status == SchoolStatusEnum.loaded;
  bool get isError => status == SchoolStatusEnum.error;

  SchoolStatusState copyWith({
    SchoolStatusEnum? status,
    String? schoolCode,
    int? activeCount,
    int? upcomingCount,
    int? enrolledCount,
    int? capacity,
    int? minAgeMonths,
    int? maxAgeMonths,
    int? totalClassrooms,
    int? adminClassrooms,
    int? classroomClassrooms,
    double? schoolFte,
    int? staffExpected,
    int? staffPresent,
    int? staffAbsent,
    int? staffSignOut,
    int? staffNotMarked,
    int? studentExpected,
    int? studentPresent,
    int? studentAbsent,
    int? studentSignOut,
    int? studentNotMarked,
    String? errorMessage,
  }) {
    return SchoolStatusState(
      status: status ?? this.status,
      schoolCode: schoolCode ?? this.schoolCode,
      activeCount: activeCount ?? this.activeCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      capacity: capacity ?? this.capacity,
      minAgeMonths: minAgeMonths ?? this.minAgeMonths,
      maxAgeMonths: maxAgeMonths ?? this.maxAgeMonths,
      totalClassrooms: totalClassrooms ?? this.totalClassrooms,
      adminClassrooms: adminClassrooms ?? this.adminClassrooms,
      classroomClassrooms: classroomClassrooms ?? this.classroomClassrooms,
      schoolFte: schoolFte ?? this.schoolFte,
      staffExpected: staffExpected ?? this.staffExpected,
      staffPresent: staffPresent ?? this.staffPresent,
      staffAbsent: staffAbsent ?? this.staffAbsent,
      staffSignOut: staffSignOut ?? this.staffSignOut,
      staffNotMarked: staffNotMarked ?? this.staffNotMarked,
      studentExpected: studentExpected ?? this.studentExpected,
      studentPresent: studentPresent ?? this.studentPresent,
      studentAbsent: studentAbsent ?? this.studentAbsent,
      studentSignOut: studentSignOut ?? this.studentSignOut,
      studentNotMarked: studentNotMarked ?? this.studentNotMarked,
      // Naked assignment — allows null to explicitly clear a stale error.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        schoolCode,
        activeCount,
        upcomingCount,
        enrolledCount,
        capacity,
        minAgeMonths,
        maxAgeMonths,
        totalClassrooms,
        adminClassrooms,
        classroomClassrooms,
        schoolFte,
        staffExpected,
        staffPresent,
        staffAbsent,
        staffSignOut,
        staffNotMarked,
        studentExpected,
        studentPresent,
        studentAbsent,
        studentSignOut,
        studentNotMarked,
        errorMessage,
      ];
}
