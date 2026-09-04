part of 'change_password_cubit.dart';

enum ChangePasswordStatus { editing, saving, saved, failed }

@immutable
class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    required this.userId,
    this.status = ChangePasswordStatus.editing,
    this.form = const PasswordFormData(),
    this.errors = PasswordFormErrors.none,
    this.hasTriedSave = false,
    this.hasSaveFailed = false,
  });

  final String userId;
  final ChangePasswordStatus status;
  final PasswordFormData form;
  final PasswordFormErrors errors;
  final bool hasTriedSave;
  final bool hasSaveFailed;

  bool get isSaving => status == ChangePasswordStatus.saving;
  bool get isSaved => status == ChangePasswordStatus.saved;

  bool get hasProblems => !errors.isEmpty;

  /// The key is off while anything is wrong, and while a change is in flight.
  bool get canSubmit => !hasProblems && !isSaving;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    PasswordFormData? form,
    PasswordFormErrors? errors,
    bool? hasTriedSave,
    bool? hasSaveFailed,
  }) => ChangePasswordState(
    userId: userId,
    status: status ?? this.status,
    form: form ?? this.form,
    errors: errors ?? this.errors,
    hasTriedSave: hasTriedSave ?? this.hasTriedSave,
    hasSaveFailed: hasSaveFailed ?? this.hasSaveFailed,
  );

  @override
  List<Object?> get props => <Object?>[
    userId,
    status,
    form,
    errors,
    hasTriedSave,
    hasSaveFailed,
  ];
}
