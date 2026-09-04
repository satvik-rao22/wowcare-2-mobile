part of 'edit_staff_cubit.dart';

enum EditStaffStatus { loading, editing, saving, saved, failed }

@immutable
class EditStaffState extends Equatable {
  const EditStaffState({
    required this.staffId,
    required this.lens,
    this.status = EditStaffStatus.loading,
    this.draft = const StaffDetailsDraft(),
    this.profile,
    this.errors = const <StaffField, String>{},
  });

  final String staffId;
  final StaffLens lens;
  final EditStaffStatus status;
  final StaffDetailsDraft draft;

  /// The record as saved, so the profile behind can take it back.
  final StaffProfile? profile;

  final Map<StaffField, String> errors;

  bool get isLoading => status == EditStaffStatus.loading;
  bool get isSaving => status == EditStaffStatus.saving;
  bool get isSaved => status == EditStaffStatus.saved;
  bool get isFailed => status == EditStaffStatus.failed && profile == null;

  /// An Admin edits anybody; a staff member edits themselves and nobody else.
  bool get canEdit => lens.canWrite || lens.isSelf(staffId);

  String? errorFor(StaffField field) => errors[field];

  EditStaffState copyWith({
    EditStaffStatus? status,
    StaffDetailsDraft? draft,
    StaffProfile? profile,
    Map<StaffField, String>? errors,
  }) => EditStaffState(
    staffId: staffId,
    lens: lens,
    status: status ?? this.status,
    draft: draft ?? this.draft,
    profile: profile ?? this.profile,
    errors: errors ?? this.errors,
  );

  EditStaffState cleared() => errors.isEmpty
      ? this
      : copyWith(
          errors: const <StaffField, String>{},
          status: EditStaffStatus.editing,
        );

  @override
  List<Object?> get props => [staffId, lens, status, draft, profile, errors];
}
