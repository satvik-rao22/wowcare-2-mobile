part of 'my_attendance_cubit.dart';

/// Which records tab is currently active in [MyAttendanceCard].
enum MyAttendanceTab { attendance, absent }

enum _Status { initial, loading, loaded, loadingMore, error }

class MyAttendanceState extends Equatable {
  const MyAttendanceState({
    this.status = _Status.initial,
    this.tab = MyAttendanceTab.attendance,
    this.staffCode = '',
    this.staffName = '',
    this.fromDate,
    this.toDate,
    // ── Attendance records ────────────────────────────────────────────────
    this.attendanceRecords = const [],
    this.attendancePage = 0,
    this.attendanceHasMore = false,
    this.attendanceLoaded = false,
    // ── Absent records ────────────────────────────────────────────────────
    this.absentRecords = const [],
    this.absentPage = 0,
    this.absentHasMore = false,
    this.absentLoaded = false,
    // ── Aggregations (from first item, stable across pagination) ──────────
    this.attendedDays = 0,
    this.attendedHours = 0,
    this.attendedMinutes = 0,
    this.totalAttendedTime = '',
    this.absentDays = 0,
    // ─────────────────────────────────────────────────────────────────────
    this.errorMessage,
  });

  final _Status status;
  final MyAttendanceTab tab;
  final String staffCode;
  final String staffName;
  final DateTime? fromDate;
  final DateTime? toDate;

  final List<StaffAttendanceDailyItemModel> attendanceRecords;
  final int attendancePage;
  final bool attendanceHasMore;
  final bool attendanceLoaded;

  final List<StaffAttendanceAbsentItemModel> absentRecords;
  final int absentPage;
  final bool absentHasMore;
  final bool absentLoaded;

  final int attendedDays;
  final int attendedHours;
  final int attendedMinutes;
  final String totalAttendedTime;
  final int absentDays;

  final String? errorMessage;

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isInitial => status == _Status.initial;
  bool get isLoading => status == _Status.loading;
  bool get isLoaded => status == _Status.loaded;
  bool get isLoadingMore => status == _Status.loadingMore;
  bool get isError => status == _Status.error;

  MyAttendanceState copyWith({
    _Status? status,
    MyAttendanceTab? tab,
    String? staffCode,
    String? staffName,
    DateTime? fromDate,
    DateTime? toDate,
    List<StaffAttendanceDailyItemModel>? attendanceRecords,
    int? attendancePage,
    bool? attendanceHasMore,
    bool? attendanceLoaded,
    List<StaffAttendanceAbsentItemModel>? absentRecords,
    int? absentPage,
    bool? absentHasMore,
    bool? absentLoaded,
    int? attendedDays,
    int? attendedHours,
    int? attendedMinutes,
    String? totalAttendedTime,
    int? absentDays,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyAttendanceState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      attendancePage: attendancePage ?? this.attendancePage,
      attendanceHasMore: attendanceHasMore ?? this.attendanceHasMore,
      attendanceLoaded: attendanceLoaded ?? this.attendanceLoaded,
      absentRecords: absentRecords ?? this.absentRecords,
      absentPage: absentPage ?? this.absentPage,
      absentHasMore: absentHasMore ?? this.absentHasMore,
      absentLoaded: absentLoaded ?? this.absentLoaded,
      attendedDays: attendedDays ?? this.attendedDays,
      attendedHours: attendedHours ?? this.attendedHours,
      attendedMinutes: attendedMinutes ?? this.attendedMinutes,
      totalAttendedTime: totalAttendedTime ?? this.totalAttendedTime,
      absentDays: absentDays ?? this.absentDays,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    tab,
    staffCode,
    staffName,
    fromDate,
    toDate,
    attendanceRecords,
    attendancePage,
    attendanceHasMore,
    attendanceLoaded,
    absentRecords,
    absentPage,
    absentHasMore,
    absentLoaded,
    attendedDays,
    attendedHours,
    attendedMinutes,
    totalAttendedTime,
    absentDays,
    errorMessage,
  ];
}
