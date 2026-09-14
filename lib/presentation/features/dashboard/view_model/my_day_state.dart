part of 'my_day_cubit.dart';

enum MyDayStatus { initial, loading, loaded, error }

class MyDayState extends Equatable {
  const MyDayState({
    this.status = MyDayStatus.initial,
    this.todaySchedule,
    this.todayWorkSchedule,
    this.todayBreakSchedule,
    this.allSchoolSchedules = const [],
    this.allWorkSchedules = const [],
    this.allBreakSchedules = const [],
    this.schoolClosed = false,
    this.schoolTimeZone = '',
    this.errorMessage,
    // ── Staff identity + today's sign-in status ─────────────────────────────
    // Mandate 2 bucket A. These nine were `_MyDayCardState` fields driven by
    // six setState calls; every one is sourced from StorageService or from
    // GetStaffTodaySignInStatusUseCase, so they are cubit state by the rule's
    // own definition ("comes from an API" / "read by more than one widget").
    this.clockInPin = '',
    this.staffCode = '',
    this.userCode = '',
    this.staffDisplayName = '',
    this.staffDesignation = '',
    this.isSignedIn = false,
    this.signInStatusLoaded = false,
    this.staffIdentityLoaded = false,
    this.todayStatusRaw,
  });

  final MyDayStatus status;

  /// The ACTIVE school schedule entry for today, or null when [schoolClosed] is true.
  final SchoolRegularScheduleDay? todaySchedule;

  /// The staff member's own work schedule for today (from their profile).
  /// When non-null, the countdown uses this instead of [todaySchedule].
  final StaffProfileWorkSchedule? todayWorkSchedule;

  /// The staff member's break schedule for today (from their profile).
  final StaffProfileBreakSchedule? todayBreakSchedule;

  /// All school schedule days — used to build the weekly schedule grid.
  final List<SchoolRegularScheduleDay> allSchoolSchedules;

  /// All staff work schedule entries (one per day) — used for the weekly grid.
  final List<StaffProfileWorkSchedule> allWorkSchedules;

  /// All staff break schedule entries (one per day) — used for the weekly grid.
  final List<StaffProfileBreakSchedule> allBreakSchedules;

  /// True when today has no school schedule or the schedule is not ACTIVE.
  final bool schoolClosed;

  /// School's IANA timezone (e.g. "America/New_York"). Used by the card to
  /// compute the countdown in school-local time, not device-local time.
  final String schoolTimeZone;

  final String? errorMessage;

  /// The staff member's clock-in PIN, from storage.
  final String clockInPin;

  final String staffCode;
  final String userCode;
  final String staffDisplayName;
  final String staffDesignation;

  /// True when today's status resolves to `SIGNED_IN`.
  final bool isSignedIn;

  /// True once the today-sign-in-status fetch has resolved at least once
  /// (success OR failure). [isSignedIn] defaults to false until then, so the
  /// geofence-entry popup must not trust it before this is true — otherwise an
  /// already-signed-in user restarting inside the geofence would wrongly see
  /// the Sign-In sheet.
  final bool signInStatusLoaded;

  /// True once staff identity has been read from storage at least once.
  final bool staffIdentityLoaded;

  /// Raw today-status string from the API (e.g. SIGNED_IN, ABSENT,
  /// SIGNED_OUT). Kept alongside [isSignedIn] because the boolean alone cannot
  /// distinguish "not signed in" from "already marked absent today", which the
  /// attendance gate needs to disable actions correctly.
  final String? todayStatusRaw;

  /// Staff code if known, else the user code — the identifier attendance APIs
  /// accept for self-service actions.
  String get effectiveStaffCode => staffCode.isNotEmpty ? staffCode : userCode;

  bool get isInitial => status == MyDayStatus.initial;
  bool get isLoading => status == MyDayStatus.loading;
  bool get isLoaded => status == MyDayStatus.loaded;

  MyDayState copyWith({
    MyDayStatus? status,
    SchoolRegularScheduleDay? todaySchedule,
    StaffProfileWorkSchedule? todayWorkSchedule,
    StaffProfileBreakSchedule? todayBreakSchedule,
    List<SchoolRegularScheduleDay>? allSchoolSchedules,
    List<StaffProfileWorkSchedule>? allWorkSchedules,
    List<StaffProfileBreakSchedule>? allBreakSchedules,
    bool? schoolClosed,
    String? schoolTimeZone,
    String? errorMessage,
    bool clearTodaySchedule = false,
    bool clearWorkSchedule = false,
    bool clearBreakSchedule = false,
    String? clockInPin,
    String? staffCode,
    String? userCode,
    String? staffDisplayName,
    String? staffDesignation,
    bool? isSignedIn,
    bool? signInStatusLoaded,
    bool? staffIdentityLoaded,
    String? todayStatusRaw,
    bool clearTodayStatusRaw = false,
  }) {
    return MyDayState(
      status: status ?? this.status,
      todaySchedule: clearTodaySchedule
          ? null
          : (todaySchedule ?? this.todaySchedule),
      todayWorkSchedule: clearWorkSchedule
          ? null
          : (todayWorkSchedule ?? this.todayWorkSchedule),
      todayBreakSchedule: clearBreakSchedule
          ? null
          : (todayBreakSchedule ?? this.todayBreakSchedule),
      allSchoolSchedules: allSchoolSchedules ?? this.allSchoolSchedules,
      allWorkSchedules: allWorkSchedules ?? this.allWorkSchedules,
      allBreakSchedules: allBreakSchedules ?? this.allBreakSchedules,
      schoolClosed: schoolClosed ?? this.schoolClosed,
      schoolTimeZone: schoolTimeZone ?? this.schoolTimeZone,
      clockInPin: clockInPin ?? this.clockInPin,
      staffCode: staffCode ?? this.staffCode,
      userCode: userCode ?? this.userCode,
      staffDisplayName: staffDisplayName ?? this.staffDisplayName,
      staffDesignation: staffDesignation ?? this.staffDesignation,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      signInStatusLoaded: signInStatusLoaded ?? this.signInStatusLoaded,
      staffIdentityLoaded: staffIdentityLoaded ?? this.staffIdentityLoaded,
      todayStatusRaw: clearTodayStatusRaw
          ? null
          : (todayStatusRaw ?? this.todayStatusRaw),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    todaySchedule,
    todayWorkSchedule,
    todayBreakSchedule,
    allSchoolSchedules,
    allWorkSchedules,
    allBreakSchedules,
    schoolClosed,
    schoolTimeZone,
    errorMessage,
    clockInPin,
    staffCode,
    userCode,
    staffDisplayName,
    staffDesignation,
    isSignedIn,
    signInStatusLoaded,
    staffIdentityLoaded,
    todayStatusRaw,
  ];
}
