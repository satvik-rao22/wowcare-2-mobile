part of 'edit_user_profile_cubit.dart';

class EditUserProfileState extends Equatable {
  const EditUserProfileState({
    required this.profile,
    required this.profileRevision,
    required this.isSubmitting,
    required this.loadFailed,
  });

  const EditUserProfileState.initial()
    : profile = null,
      profileRevision = 0,
      isSubmitting = false,
      loadFailed = false;

  /// The most recently fetched profile, or null before the first load.
  final StaffProfile? profile;

  /// Increments on every successful fetch so the view knows to re-hydrate even
  /// if the profile object compares equal.
  final int profileRevision;

  /// Whether a save is in flight (drives the Save button's disabled state).
  final bool isSubmitting;

  /// Whether the initial load failed with no cached fallback.
  final bool loadFailed;

  EditUserProfileState copyWith({
    StaffProfile? profile,
    int? profileRevision,
    bool? isSubmitting,
    bool? loadFailed,
  }) {
    return EditUserProfileState(
      profile: profile ?? this.profile,
      profileRevision: profileRevision ?? this.profileRevision,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    profileRevision,
    isSubmitting,
    loadFailed,
  ];
}
