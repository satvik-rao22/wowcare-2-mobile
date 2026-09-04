part of 'classroom_profile_cubit.dart';

enum ClassroomProfileStatus { loading, ready, cached, failed }

/// The photo well's own four states (7f).
enum PhotoUploadStatus { idle, uploading, done, failed }

@immutable
class ClassroomProfileState extends Equatable {
  const ClassroomProfileState({
    required this.classroomId,
    required this.persona,
    this.status = ClassroomProfileStatus.loading,
    this.profile,
    this.upload = PhotoUploadStatus.idle,
    this.pendingFileName,
  });

  final String classroomId;
  final Persona persona;

  final ClassroomProfileStatus status;
  final ClassroomProfile? profile;

  final PhotoUploadStatus upload;

  /// The file the well is uploading, or the one a retry would send again.
  final String? pendingFileName;

  bool get isLoading => status == ClassroomProfileStatus.loading;
  bool get isFailed => status == ClassroomProfileStatus.failed;
  bool get isCached => status == ClassroomProfileStatus.cached;

  /// Admins change a classroom's record. Everybody else looks.
  bool get canEdit => persona == Persona.admin;

  ClassroomSummary? get summary => profile?.summary;

  ClassroomProfileState copyWith({
    ClassroomProfileStatus? status,
    ClassroomProfile? profile,
    PhotoUploadStatus? upload,
    String? pendingFileName,
    bool clearPendingFileName = false,
  }) => ClassroomProfileState(
    classroomId: classroomId,
    persona: persona,
    status: status ?? this.status,
    profile: profile ?? this.profile,
    upload: upload ?? this.upload,
    pendingFileName: clearPendingFileName
        ? null
        : (pendingFileName ?? this.pendingFileName),
  );

  @override
  List<Object?> get props => [
    classroomId,
    persona,
    status,
    profile,
    upload,
    pendingFileName,
  ];
}
