part of 'create_staff_cubit.dart';

enum CreateStaffStatus { loading, editing, saving, saved, failed }

@immutable
class CreateStaffState extends Equatable {
  const CreateStaffState({
    this.status = CreateStaffStatus.loading,
    this.step = 1,
    this.draft = const StaffDraft(),
    this.options = const StaffOptions(),
    this.errors = const <StaffField, String>{},
    this.created,
  });

  /// Name and contact, what they can do, their shifts.
  static const int lastStep = 3;

  final CreateStaffStatus status;

  /// 1, 2 or 3.
  final int step;

  final StaffDraft draft;
  final StaffOptions options;
  final Map<StaffField, String> errors;

  /// The record that was created, so the roster can name it in its toast.
  final StaffMember? created;

  bool get isLoading => status == CreateStaffStatus.loading;
  bool get isSaving => status == CreateStaffStatus.saving;
  bool get isSaved => status == CreateStaffStatus.saved;
  bool get isFailed => status == CreateStaffStatus.failed;

  bool get hasBack => step > 1;

  /// The last step is the one that may be left for later.
  bool get canSkip => step == lastStep;

  bool get isLastStep => step == lastStep;

  /// The classroom fields belong to a staff member. An Admin covers every
  /// classroom by role, which is what makes those two fields theirs to skip.
  bool get needsClassrooms => draft.role == StaffRole.staff;

  List<String> get designations => options.designationsFor(draft.role);

  String? errorFor(StaffField field) => errors[field];

  CreateStaffState copyWith({
    CreateStaffStatus? status,
    int? step,
    StaffDraft? draft,
    StaffOptions? options,
    Map<StaffField, String>? errors,
    StaffMember? created,
  }) => CreateStaffState(
    status: status ?? this.status,
    step: step ?? this.step,
    draft: draft ?? this.draft,
    options: options ?? this.options,
    errors: errors ?? this.errors,
    created: created ?? this.created,
  );

  /// Typing clears whatever the last step complained about, so a field does
  /// not keep shouting while it is being fixed.
  CreateStaffState cleared() => errors.isEmpty
      ? this
      : copyWith(
          errors: const <StaffField, String>{},
          status: CreateStaffStatus.editing,
        );

  @override
  List<Object?> get props => [status, step, draft, options, errors, created];
}
