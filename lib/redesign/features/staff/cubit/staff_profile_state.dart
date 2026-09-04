part of 'staff_profile_cubit.dart';

enum StaffProfileStatus { loading, ready, saving, saved, failed }

/// The five tabs 6c draws.
enum StaffProfileTab { profile, schedule, attendance, dates, documents }

@immutable
class StaffProfileState extends Equatable {
  const StaffProfileState({
    required this.staffId,
    required this.lens,
    this.status = StaffProfileStatus.loading,
    this.profile,
    this.tab = StaffProfileTab.profile,
  });

  final String staffId;
  final StaffLens lens;
  final StaffProfileStatus status;
  final StaffProfile? profile;
  final StaffProfileTab tab;

  bool get isLoading => status == StaffProfileStatus.loading;
  bool get isSaving => status == StaffProfileStatus.saving;
  bool get isSaved => status == StaffProfileStatus.saved;
  bool get isFailed => status == StaffProfileStatus.failed && profile == null;

  /// Everything but the name, the classroom and a way to call is private to
  /// each staff member, so a colleague's record shows only the top of it.
  bool get seesDetails => lens.seesDetailsOf(staffId);

  bool get isSelf => lens.isSelf(staffId);

  /// Editing a record, changing its schedule and deactivating it are Admin
  /// work. Keeping your own phone number and address up to date is not.
  bool get canEdit => lens.canWrite || isSelf;

  /// A work schedule is Admin-only. A staff member reads theirs and no more.
  bool get canEditSchedule => lens.canWrite;

  bool get canDeactivate => lens.canWrite && !isSelf;

  /// Which tabs this viewer gets. A colleague's record stops at the profile,
  /// because the rest of it is personal.
  List<StaffProfileTab> get tabs => seesDetails
      ? StaffProfileTab.values
      : const <StaffProfileTab>[StaffProfileTab.profile];

  StaffProfileState copyWith({
    StaffProfileStatus? status,
    StaffProfile? profile,
    StaffProfileTab? tab,
  }) => StaffProfileState(
    staffId: staffId,
    lens: lens,
    status: status ?? this.status,
    profile: profile ?? this.profile,
    tab: tab ?? this.tab,
  );

  @override
  List<Object?> get props => [staffId, lens, status, profile, tab];
}
