part of 'user_profile_cubit.dart';

/// Sentinel so [UserProfileState.copyWith] can distinguish "leave unchanged"
/// from "set to null" for the nullable fields.
const Object _kUnset = Object();

class UserProfileState extends Equatable {
  const UserProfileState({
    required this.profile,
    required this.loginDisplayName,
    required this.loginEmail,
    required this.loginPersona,
    required this.schoolCode,
    required this.organizationCode,
    required this.isUploadingProfilePhoto,
    required this.profilePhotoUploadPercent,
    required this.distinctRolesForCurrentSchool,
    required this.switchPersonasLoading,
    required this.cachedActiveSchoolRole,
    required this.guardianPhone,
    required this.guardianAddress,
    required this.guardianCode,
    required this.guardianPhotoAssetCode,
    required this.guardianPhotoUrl,
    required this.profileLoadFailed,
  });

  const UserProfileState.initial()
      : profile = null,
        loginDisplayName = '',
        loginEmail = '',
        loginPersona = '',
        schoolCode = null,
        organizationCode = null,
        isUploadingProfilePhoto = false,
        profilePhotoUploadPercent = 0,
        distinctRolesForCurrentSchool = const [],
        switchPersonasLoading = false,
        cachedActiveSchoolRole = null,
        guardianPhone = '',
        guardianAddress = '',
        guardianCode = '',
        guardianPhotoAssetCode = '',
        guardianPhotoUrl = '',
        profileLoadFailed = false;

  final StaffProfile? profile;
  final String loginDisplayName;
  final String loginEmail;
  final String loginPersona;
  final String? schoolCode;
  final String? organizationCode;
  final bool isUploadingProfilePhoto;
  final double profilePhotoUploadPercent;
  final List<String> distinctRolesForCurrentSchool;
  final bool switchPersonasLoading;
  final String? cachedActiveSchoolRole;
  final String guardianPhone;
  final String guardianAddress;
  final String guardianCode;
  final String guardianPhotoAssetCode;
  final String guardianPhotoUrl;

  /// Set when a profile fetch fails with no cached fallback. The view shows a
  /// one-time snackbar in response.
  final bool profileLoadFailed;

  UserProfileState copyWith({
    Object? profile = _kUnset,
    String? loginDisplayName,
    String? loginEmail,
    String? loginPersona,
    Object? schoolCode = _kUnset,
    Object? organizationCode = _kUnset,
    bool? isUploadingProfilePhoto,
    double? profilePhotoUploadPercent,
    List<String>? distinctRolesForCurrentSchool,
    bool? switchPersonasLoading,
    Object? cachedActiveSchoolRole = _kUnset,
    String? guardianPhone,
    String? guardianAddress,
    String? guardianCode,
    String? guardianPhotoAssetCode,
    String? guardianPhotoUrl,
    bool? profileLoadFailed,

    /// Forces the guardian photo fields back to empty.
    ///
    /// Needed because the `?? this.x` merge above cannot express "set this to
    /// ''" — passing `guardianPhotoUrl: ''` is indistinguishable from passing
    /// nothing. Every other writer of these fields deliberately never clobbers
    /// a known-good photo with an empty value (see
    /// `loadGuardianProfileForParent`), so a delete needs an explicit opt-in.
    bool clearGuardianPhoto = false,
  }) {
    return UserProfileState(
      profile: identical(profile, _kUnset)
          ? this.profile
          : profile as StaffProfile?,
      loginDisplayName: loginDisplayName ?? this.loginDisplayName,
      loginEmail: loginEmail ?? this.loginEmail,
      loginPersona: loginPersona ?? this.loginPersona,
      schoolCode: identical(schoolCode, _kUnset)
          ? this.schoolCode
          : schoolCode as String?,
      organizationCode: identical(organizationCode, _kUnset)
          ? this.organizationCode
          : organizationCode as String?,
      isUploadingProfilePhoto:
          isUploadingProfilePhoto ?? this.isUploadingProfilePhoto,
      profilePhotoUploadPercent:
          profilePhotoUploadPercent ?? this.profilePhotoUploadPercent,
      distinctRolesForCurrentSchool:
          distinctRolesForCurrentSchool ?? this.distinctRolesForCurrentSchool,
      switchPersonasLoading:
          switchPersonasLoading ?? this.switchPersonasLoading,
      cachedActiveSchoolRole: identical(cachedActiveSchoolRole, _kUnset)
          ? this.cachedActiveSchoolRole
          : cachedActiveSchoolRole as String?,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianAddress: guardianAddress ?? this.guardianAddress,
      guardianCode: guardianCode ?? this.guardianCode,
      guardianPhotoAssetCode: clearGuardianPhoto
          ? ''
          : (guardianPhotoAssetCode ?? this.guardianPhotoAssetCode),
      guardianPhotoUrl: clearGuardianPhoto
          ? ''
          : (guardianPhotoUrl ?? this.guardianPhotoUrl),
      profileLoadFailed: profileLoadFailed ?? this.profileLoadFailed,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        loginDisplayName,
        loginEmail,
        loginPersona,
        schoolCode,
        organizationCode,
        isUploadingProfilePhoto,
        profilePhotoUploadPercent,
        distinctRolesForCurrentSchool,
        switchPersonasLoading,
        cachedActiveSchoolRole,
        guardianPhone,
        guardianAddress,
        guardianCode,
        guardianPhotoAssetCode,
        guardianPhotoUrl,
        profileLoadFailed,
      ];
}
