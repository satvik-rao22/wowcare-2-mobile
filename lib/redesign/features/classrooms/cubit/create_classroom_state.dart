part of 'create_classroom_cubit.dart';

enum CreateClassroomStatus { editing, saving, saved, failed }

/// Which field an error belongs under.
enum ClassroomField { name, ageFrom, ageTo, capacity, studentsPerStaff }

@immutable
class CreateClassroomState extends Equatable {
  const CreateClassroomState({
    this.status = CreateClassroomStatus.editing,
    this.draft = const ClassroomDraft(),
    this.errors = const <ClassroomField, String>{},
    this.created,
  });

  final CreateClassroomStatus status;
  final ClassroomDraft draft;
  final Map<ClassroomField, String> errors;

  /// The classroom that was created, so the floor can name it.
  final ClassroomSummary? created;

  bool get isSaving => status == CreateClassroomStatus.saving;
  bool get isSaved => status == CreateClassroomStatus.saved;
  bool get isFailed => status == CreateClassroomStatus.failed;

  String? errorFor(ClassroomField field) => errors[field];

  CreateClassroomState copyWith({
    CreateClassroomStatus? status,
    ClassroomDraft? draft,
    Map<ClassroomField, String>? errors,
    ClassroomSummary? created,
  }) => CreateClassroomState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    created: created ?? this.created,
  );

  /// Typing clears whatever the last submit complained about, so a field does
  /// not keep shouting while it is being fixed.
  CreateClassroomState cleared() => errors.isEmpty
      ? this
      : copyWith(
          errors: const <ClassroomField, String>{},
          status: CreateClassroomStatus.editing,
        );

  @override
  List<Object?> get props => [status, draft, errors, created];
}
