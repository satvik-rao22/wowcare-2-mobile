part of 'student_profile_cubit.dart';

enum ProfileStatus { loading, ready, failed }

/// The five tabs across the top of 5c.
enum ProfileTab { profile, health, attendance, dates, documents }

/// The Profile tab's own three sections.
enum ProfileSection { about, family, pickup }

/// The Health tab's own four sections.
enum HealthSection { health, physician, exam, immunization }

@immutable
class StudentProfileState extends Equatable {
  const StudentProfileState({
    required this.studentId,
    required this.persona,
    this.status = ProfileStatus.loading,
    this.record,
    this.tab = ProfileTab.profile,
    this.profileSection = ProfileSection.about,
    this.healthSection = HealthSection.health,
  });

  final String studentId;
  final Persona persona;
  final ProfileStatus status;
  final StudentProfileRecord? record;

  final ProfileTab tab;
  final ProfileSection profileSection;
  final HealthSection healthSection;

  bool get isLoading => status == ProfileStatus.loading;
  bool get isFailed => status == ProfileStatus.failed;

  /// Editing a record is admin work; a staff member reads it.
  bool get canWrite => persona == Persona.admin;

  /// The Health tab is the one place a family may write, when the center has
  /// let them keep those records up to date.
  bool get canEditHealth => canWrite || (record?.health.canFamilyEdit ?? false);

  /// Only the Profile and Health tabs have a second row of sections.
  bool get hasSections => tab == ProfileTab.profile || tab == ProfileTab.health;

  StudentProfileState copyWith({
    ProfileStatus? status,
    StudentProfileRecord? record,
    ProfileTab? tab,
    ProfileSection? profileSection,
    HealthSection? healthSection,
  }) => StudentProfileState(
    studentId: studentId,
    persona: persona,
    status: status ?? this.status,
    record: record ?? this.record,
    tab: tab ?? this.tab,
    profileSection: profileSection ?? this.profileSection,
    healthSection: healthSection ?? this.healthSection,
  );

  @override
  List<Object?> get props => [
    studentId,
    persona,
    status,
    record,
    tab,
    profileSection,
    healthSection,
  ];
}
