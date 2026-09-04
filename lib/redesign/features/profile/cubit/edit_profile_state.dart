part of 'edit_profile_cubit.dart';

enum EditProfileStatus { loading, ready, saving, saved, failed }

@immutable
class EditProfileState extends Equatable {
  const EditProfileState({
    required this.userId,
    this.status = EditProfileStatus.loading,
    this.record,
    this.form = const ProfileFormData(),
    this.errors = ProfileFormErrors.none,
    this.stateNames = const <String>[],
    this.hasTriedSave = false,
    this.hasSaveFailed = false,
  });

  final String userId;
  final EditProfileStatus status;

  /// The record as it was loaded, for the two locked wells (email, country)
  /// and for the country the saved address keeps.
  final ProfileRecord? record;

  final ProfileFormData form;
  final ProfileFormErrors errors;

  /// The states the dropdown offers.
  final List<String> stateNames;

  final bool hasTriedSave;
  final bool hasSaveFailed;

  bool get isLoading => status == EditProfileStatus.loading;
  bool get isSaving => status == EditProfileStatus.saving;
  bool get isSaved => status == EditProfileStatus.saved;
  bool get isFailed => status == EditProfileStatus.failed;

  /// A guardian's address is optional; a staff member's is not.
  bool get isAddressRequired => !(record?.isGuardian ?? false);

  bool get hasProblems => !errors.isEmpty;

  /// Save is off while anything is wrong, and while a save is in flight.
  bool get canSave => !hasProblems && !isSaving;

  String get email => record?.email ?? '';
  String get country => record?.address.country ?? '';

  /// [form] run through the rules this record is held to.
  ProfileFormErrors checked(ProfileFormData form) =>
      ProfileFormValidator.validate(form, addressRequired: isAddressRequired);

  EditProfileState copyWith({
    EditProfileStatus? status,
    ProfileRecord? record,
    ProfileFormData? form,
    ProfileFormErrors? errors,
    List<String>? stateNames,
    bool? hasTriedSave,
    bool? hasSaveFailed,
  }) => EditProfileState(
    userId: userId,
    status: status ?? this.status,
    record: record ?? this.record,
    form: form ?? this.form,
    errors: errors ?? this.errors,
    stateNames: stateNames ?? this.stateNames,
    hasTriedSave: hasTriedSave ?? this.hasTriedSave,
    hasSaveFailed: hasSaveFailed ?? this.hasSaveFailed,
  );

  @override
  List<Object?> get props => <Object?>[
    userId,
    status,
    record,
    form,
    errors,
    stateNames,
    hasTriedSave,
    hasSaveFailed,
  ];
}
