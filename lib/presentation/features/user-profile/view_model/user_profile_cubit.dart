import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/login_persona_util.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/string_utils.dart';
import '../../../../core/util/user_details_school_roles.dart';
import '../../../../data/features/auth/datasources/auth_local_datasource.dart';
import '../../../../data/features/auth/datasources/auth_remote_datasource.dart';
import '../../../../data/features/student/datasources/student_remote_datasource.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/services/image_upload/image_upload_service.dart';

part 'user_profile_state.dart';

/// Outcome of a profile-photo upload so the view can show the right snackbar
/// without inspecting cubit internals.
enum UserProfilePhotoStatus { success, validationError, uploadError }

class UserProfilePhotoResult {
  const UserProfilePhotoResult(this.status, this.message);

  final UserProfilePhotoStatus status;
  final String message;

  bool get isSuccess => status == UserProfilePhotoStatus.success;
}

/// Owns the data + business logic for the user-profile screen: login summary,
/// staff/guardian profile loading, persona-switch availability, and the
/// (multi-step, progress-tracked) profile-photo uploads.
///
/// Cross-cubit persona-switch *orchestration* (RoleCubit / ParentChildCubit /
/// AuthCubit) and all UI feedback (snackbars, navigation, image picking) stay
/// in the view; this cubit exposes the granular operations the view composes.
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit({
    required StorageService storageService,
    required StaffRepository staffRepository,
    required AuthRemoteDataSource authRemoteDataSource,
    required AuthLocalDataSource authLocalDataSource,
    required StudentRemoteDataSource studentRemoteDataSource,
    required ImageUploadService imageUploadService,
  })  : _storage = storageService,
        _staffRepository = staffRepository,
        _authRemoteDataSource = authRemoteDataSource,
        _authLocalDataSource = authLocalDataSource,
        _studentRemoteDataSource = studentRemoteDataSource,
        _imageUploadService = imageUploadService,
        super(const UserProfileState.initial());

  final StorageService _storage;
  final StaffRepository _staffRepository;
  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthLocalDataSource _authLocalDataSource;
  final StudentRemoteDataSource _studentRemoteDataSource;
  final ImageUploadService _imageUploadService;

  String _directStaffCode = '';
  bool _hasShownProfileLoadError = false;

  /// Seeds the login summary from navigation arguments so the screen doesn't
  /// render placeholders while storage loads.
  void seed({
    required String name,
    required String email,
    required String persona,
    String? directStaffCode,
  }) {
    _directStaffCode = (directStaffCode ?? '').trim();
    emit(
      state.copyWith(
        loginDisplayName: name.trim(),
        loginEmail: email.trim(),
        loginPersona: persona.trim(),
      ),
    );
  }

  String effectiveStaffCode() {
    final fromProfile = (state.profile?.staffCode ?? '').trim();
    if (fromProfile.isNotEmpty) return fromProfile;
    return _directStaffCode.trim();
  }

  Future<void> load({required bool isParent}) async {
    // Preload login-based user summary (name, email, persona) from storage.
    try {
      final loginDisplayName =
          (await _storage.getString(StorageKeys.displayName) ?? '').trim();
      final loginEmail =
          (await _storage.getString(StorageKeys.email) ?? '').trim();
      final cachedDesignation =
          (await _storage.getString(StorageKeys.staffDesignation) ?? '').trim();

      final activeSchoolRole =
          (await _storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
      final rolesJson =
          await _storage.getString(StorageKeys.roles); // JSON array from login
      String persona = '';
      if (activeSchoolRole.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(activeSchoolRole);
      }
      // For staff personas, show designation instead of staffType/role when available.
      if (persona.isEmpty && cachedDesignation.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(cachedDesignation);
      }
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      if (persona.isEmpty && rolesJson != null && rolesJson.isNotEmpty) {
        try {
          final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
          final matches =
              matchingRolesForOrgSchool(roles, org, school).toList();
          if (matches.isNotEmpty) {
            persona = StringUtils.staffTypeToDisplayRole(
              matches.first['role'] ?? '',
            );
          } else if (roles.isNotEmpty) {
            final first = roles.first as Map<String, dynamic>;
            final roleCode = (first['role'] ?? '').toString();
            persona = StringUtils.staffTypeToDisplayRole(roleCode);
          }
        } catch (_) {}
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          loginDisplayName: loginDisplayName,
          loginEmail: loginEmail,
          loginPersona: persona,
          schoolCode: school.isEmpty ? null : school,
          organizationCode: org.isEmpty ? null : org,
          cachedActiveSchoolRole:
              activeSchoolRole.isEmpty ? null : activeSchoolRole,
        ),
      );
      await refreshSwitchProfileAvailability();
    } catch (_) {}

    // For guardian/parent persona, load guardian profile fields for phone/address
    // and skip staff profile fetches.
    try {
      if (isParent) {
        await loadGuardianProfileForParent();
        if (isClosed) return;
        emit(state.copyWith(profile: null));
        return;
      }
    } catch (_) {}

    final direct = _directStaffCode.trim();
    if (direct.isNotEmpty) {
      await loadStaffProfile(direct);
      return;
    }

    final resolved = await resolveLoggedInStaffCode();
    if (isClosed) return;
    if (resolved.isEmpty) {
      emit(state.copyWith(profile: null));
    } else {
      await loadStaffProfile(resolved);
    }
  }

  /// Attempts to resolve staffCode for the logged-in user from local cache.
  /// Falls back to any cached staffCode to keep my-profile fetch non-blocking.
  Future<String> resolveLoggedInStaffCode() async {
    try {
      final currentUserCode =
          (await _storage.getString(StorageKeys.userCode) ?? '').trim();
      final cachedStaffCode =
          (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await _storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          currentUserCode.isNotEmpty &&
          cachedStaffUser == currentUserCode) {
        return cachedStaffCode;
      }
      if (cachedStaffCode.isNotEmpty) {
        return cachedStaffCode;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> refreshSwitchProfileAvailability() async {
    final org = (state.organizationCode ?? '').trim();
    final school = (state.schoolCode ?? '').trim();
    if (org.isEmpty || school.isEmpty) {
      if (isClosed) return;
      emit(
        state.copyWith(
          distinctRolesForCurrentSchool: const [],
          switchPersonasLoading: false,
        ),
      );
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(switchPersonasLoading: true));
    try {
      var users = await readCachedUserAccessDetailsUsers(_storage);
      if (users.isEmpty) {
        final token =
            (await _storage.getString(StorageKeys.accessToken) ?? '').trim();
        if (token.isNotEmpty) {
          users = await _authRemoteDataSource.getUserDetails(
            accessToken: token,
          );
          await _storage.saveString(
            StorageKeys.userAccessDetails,
            jsonEncode(users),
          );
        }
      }
      final distinct = distinctActiveRolesForCurrentSchoolFromUserDetails(
        users,
        org,
        school,
      );
      final active =
          (await _storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
      if (isClosed) return;
      emit(
        state.copyWith(
          distinctRolesForCurrentSchool: distinct,
          cachedActiveSchoolRole: active.isEmpty ? null : active,
          switchPersonasLoading: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          distinctRolesForCurrentSchool: const [],
          switchPersonasLoading: false,
        ),
      );
    }
  }

  void setSwitching(bool value) {
    if (isClosed) return;
    emit(state.copyWith(switchPersonasLoading: value));
  }

  /// Persists the persona switch in local auth caches (without touching the
  /// visible profile, which the view applies via [applySwitchedPersona] once
  /// the sibling cubits have refreshed).
  Future<void> persistPersonaSwitch(String backendRole) async {
    await _authLocalDataSource.clearPersonaVolatileCaches();
    await _authLocalDataSource.persistActiveSchoolPersonaRole(backendRole);
  }

  void applySwitchedPersona(String backendRole) {
    if (isClosed) return;
    emit(
      state.copyWith(
        profile: null,
        cachedActiveSchoolRole: backendRole,
        loginPersona: StringUtils.staffTypeToDisplayRole(backendRole),
      ),
    );
  }

  Future<void> loadStaffProfile(String staffCode) async {
    try {
      final repo = _staffRepository;
      // 1) Try cached profile first (fast, no loader).
      if (repo is StaffRepositoryWithCache) {
        final cached =
            await (repo as StaffRepositoryWithCache).loadCachedStaffProfile(
          staffCode,
        );
        if (isClosed) return;
        if (cached != null) {
          // Persist staffType for ProfileMenuHeader.
          if (cached.staffType.isNotEmpty) {
            await _storage.saveString(StorageKeys.staffType, cached.staffType);
          }
          if (cached.designation.trim().isNotEmpty) {
            await _storage.saveString(
              StorageKeys.staffDesignation,
              cached.designation.trim(),
            );
          }
          if (isClosed) return;
          emit(state.copyWith(profile: cached));
        }
      }

      // 2) Prefetch latest profile in the background (no loader shown).
      try {
        final fresh = await repo.getStaffProfile(staffCode: staffCode);
        if (isClosed) return;
        if (fresh.staffType.isNotEmpty) {
          await _storage.saveString(StorageKeys.staffType, fresh.staffType);
        }
        if (fresh.designation.trim().isNotEmpty) {
          await _storage.saveString(
            StorageKeys.staffDesignation,
            fresh.designation.trim(),
          );
        }
        if (isClosed) return;
        emit(state.copyWith(profile: fresh));
      } catch (e) {
        CoreUtils.logApiError(e.toString());
        if (state.profile == null && !_hasShownProfileLoadError) {
          _hasShownProfileLoadError = true;
          if (!isClosed) emit(state.copyWith(profileLoadFailed: true));
        }
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (state.profile == null && !_hasShownProfileLoadError) {
        _hasShownProfileLoadError = true;
        if (!isClosed) emit(state.copyWith(profileLoadFailed: true));
      }
    }
  }

  Future<void> loadGuardianProfileForParent() async {
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final userCode =
          (await _storage.getString(StorageKeys.userCode) ?? '').trim();
      if (schoolCode.isEmpty || userCode.isEmpty) return;

      // Seed from the persisted guardian photo first so the avatar is visible
      // immediately (and stays visible even if the live fetch returns an empty
      // asset code, as the guardian profile API sometimes does).
      final cachedAsset =
          (await _storage.getString(StorageKeys.guardianProfileAssetCode) ?? '')
              .trim();
      final cachedUrl =
          (await _storage.getString(StorageKeys.guardianProfilePhotoUrl) ?? '')
              .trim();
      if (!isClosed && (cachedAsset.isNotEmpty || cachedUrl.isNotEmpty)) {
        emit(
          state.copyWith(
            guardianPhotoAssetCode:
                cachedAsset.isNotEmpty ? cachedAsset : null,
            guardianPhotoUrl: cachedUrl.isNotEmpty ? cachedUrl : null,
          ),
        );
      }

      final profile = await _studentRemoteDataSource.getGuardianProfile(
        schoolCode: schoolCode,
        userCode: userCode,
      );

      final guardianCode = (profile['code'] ?? '').toString().trim();
      final photoAssetCode =
          (profile['profilePhotoAssetCode'] ?? '').toString().trim();
      final photoUrl =
          (profile['profilePhotoUrl'] ?? profile['photoUrl'] ?? '')
              .toString()
              .trim();
      final firstName = (profile['firstName'] ?? '').toString().trim();
      final lastName = (profile['lastName'] ?? '').toString().trim();
      final fullName = (profile['fullName'] ?? '').toString().trim();
      final resolvedName =
          fullName.isNotEmpty ? fullName : ('$firstName $lastName').trim();
      final resolvedEmail = (profile['email'] ?? '').toString().trim();
      final resolvedPhone =
          ((profile['mobile'] ?? profile['phone'] ?? '').toString().trim());

      String resolvedAddress = '';
      final rawAddress = profile['address'];
      if (rawAddress is Map) {
        final m = Map<String, dynamic>.from(rawAddress);
        final parts = <String>[
          (m['street'] ?? m['addressStreet'] ?? '').toString().trim(),
          (m['line2'] ?? m['addressLine2'] ?? '').toString().trim(),
          (m['city'] ?? m['addressCity'] ?? '').toString().trim(),
          (m['state'] ?? m['addressState'] ?? '').toString().trim(),
          (m['zipCode'] ?? m['addressZipCode'] ?? '').toString().trim(),
          (m['country'] ?? m['addressCountry'] ?? '').toString().trim(),
        ].where((e) => e.isNotEmpty).toList(growable: false);
        resolvedAddress = parts.join(', ');
      } else if (rawAddress is String) {
        resolvedAddress = rawAddress.trim();
      }

      if (isClosed) return;
      // Never clobber a known-good name/photo with an empty API value.
      emit(
        state.copyWith(
          loginDisplayName:
              resolvedName.isNotEmpty ? resolvedName : null,
          loginEmail: resolvedEmail.isNotEmpty ? resolvedEmail : null,
          guardianPhone: resolvedPhone,
          guardianAddress: resolvedAddress,
          guardianCode: guardianCode.isNotEmpty ? guardianCode : null,
          guardianPhotoAssetCode:
              photoAssetCode.isNotEmpty ? photoAssetCode : null,
          guardianPhotoUrl: photoUrl.isNotEmpty ? photoUrl : null,
        ),
      );

      // Mirror the guardian photo into storage (only when non-empty) so the
      // three-dot (kebab) menu header — which reads these keys — shows the same
      // photo and doesn't get wiped by an empty API response.
      try {
        if (photoAssetCode.isNotEmpty) {
          await _storage.saveString(
            StorageKeys.guardianProfileAssetCode,
            photoAssetCode,
          );
        }
        if (photoUrl.isNotEmpty) {
          await _storage.saveString(
            StorageKeys.guardianProfilePhotoUrl,
            photoUrl,
          );
        }
      } catch (_) {}
    } catch (_) {
      // Non-blocking: profile still renders with cached/login values.
    }
  }

  /// Uploads a new profile photo for the current persona. Staff and guardian
  /// flows share the multi-step shape but use different endpoints. Progress is
  /// streamed into [UserProfileState.profilePhotoUploadPercent].
  Future<UserProfilePhotoResult> uploadProfilePhoto({
    required String imagePath,
    required bool isParent,
  }) async {
    if (isParent) {
      return _uploadGuardianProfilePhoto(imagePath);
    }
    return _uploadStaffProfilePhoto(imagePath);
  }

  Future<UserProfilePhotoResult> _uploadStaffProfilePhoto(
    String imagePath,
  ) async {
    try {
      var staffCode = effectiveStaffCode();
      if (staffCode.isEmpty) {
        staffCode = (await resolveLoggedInStaffCode()).trim();
      }
      if (staffCode.isEmpty) {
        return const UserProfilePhotoResult(
          UserProfilePhotoStatus.validationError,
          'Staff code is required to upload profile photo.',
        );
      }

      if ((state.schoolCode ?? '').trim().isEmpty ||
          (state.organizationCode ?? '').trim().isEmpty) {
        final school =
            (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
        final org =
            (await _storage.getString(StorageKeys.organizationCode) ?? '')
                .trim();
        if (isClosed) {
          return const UserProfilePhotoResult(
            UserProfilePhotoStatus.uploadError,
            'Upload cancelled.',
          );
        }
        emit(
          state.copyWith(
            schoolCode: school.isEmpty ? null : school,
            organizationCode: org.isEmpty ? null : org,
          ),
        );
      }
      final schoolCode = (state.schoolCode ?? '').trim();
      final organizationCode = (state.organizationCode ?? '').trim();
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        return const UserProfilePhotoResult(
          UserProfilePhotoStatus.validationError,
          'Missing school or organization context.',
        );
      }

      emit(
        state.copyWith(
          isUploadingProfilePhoto: true,
          profilePhotoUploadPercent: 5,
        ),
      );
      final file = File(imagePath);
      final sessionCode =
          await _imageUploadService.createStaffProfilePhotoUploadSession(
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 15));
      final lowerPath = imagePath.toLowerCase();
      final fileName = lowerPath.split(Platform.pathSeparator).last;
      final contentType =
          lowerPath.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final presign = await _imageUploadService.createAssetPresign(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
        fileName: fileName.isNotEmpty
            ? fileName
            : 'staff-profile-photo-${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: 'IMAGE',
        ownerType: 'STAFF',
        ownerCode: staffCode,
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 25));
      await _imageUploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: contentType,
        onSendProgress: (int sent, int total) {
          if (isClosed || total <= 0) return;
          final uploadPhasePercent = (sent / total).clamp(0.0, 1.0);
          emit(
            state.copyWith(
              profilePhotoUploadPercent: 25 + (uploadPhasePercent * 55),
            ),
          );
        },
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 84));
      await _imageUploadService.completeAssetUpload(
        sessionCode: sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: '/api/v1',
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 90));
      await _imageUploadService.waitUntilAssetsReady(
        sessionCode: sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 100));
      await _imageUploadService.finalizeStaffProfilePhoto(
        staffCode: staffCode,
        assetCode: presign.assetCode,
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 100));

      DocumentImageWidget.clearProfilePhotoCache(staffCode: staffCode);
      await loadStaffProfile(staffCode);
      return const UserProfilePhotoResult(
        UserProfilePhotoStatus.success,
        'Profile photo updated successfully',
      );
    } catch (e) {
      return UserProfilePhotoResult(
        UserProfilePhotoStatus.uploadError,
        'Failed to update profile photo: $e',
      );
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploadingProfilePhoto: false,
            profilePhotoUploadPercent: 0,
          ),
        );
      }
    }
  }

  Future<UserProfilePhotoResult> _uploadGuardianProfilePhoto(
    String imagePath,
  ) async {
    try {
      // Resolve the guardian code — re-fetch the guardian profile if we don't
      // have it yet (e.g. tapped before the initial profile load settled).
      var guardianCode = state.guardianCode.trim();
      if (guardianCode.isEmpty) {
        await loadGuardianProfileForParent();
        if (isClosed) {
          return const UserProfilePhotoResult(
            UserProfilePhotoStatus.uploadError,
            'Upload cancelled.',
          );
        }
        guardianCode = state.guardianCode.trim();
      }
      if (guardianCode.isEmpty) {
        return const UserProfilePhotoResult(
          UserProfilePhotoStatus.validationError,
          'Guardian profile is still loading. Please try again.',
        );
      }

      if ((state.schoolCode ?? '').trim().isEmpty ||
          (state.organizationCode ?? '').trim().isEmpty) {
        final school =
            (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
        final org =
            (await _storage.getString(StorageKeys.organizationCode) ?? '')
                .trim();
        if (isClosed) {
          return const UserProfilePhotoResult(
            UserProfilePhotoStatus.uploadError,
            'Upload cancelled.',
          );
        }
        emit(
          state.copyWith(
            schoolCode: school.isEmpty ? null : school,
            organizationCode: org.isEmpty ? null : org,
          ),
        );
      }
      final schoolCode = (state.schoolCode ?? '').trim();
      final organizationCode = (state.organizationCode ?? '').trim();
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        return const UserProfilePhotoResult(
          UserProfilePhotoStatus.validationError,
          'Missing school or organization context.',
        );
      }
      final userCode =
          (await _storage.getString(StorageKeys.userCode) ?? '').trim();

      emit(
        state.copyWith(
          isUploadingProfilePhoto: true,
          profilePhotoUploadPercent: 5,
        ),
      );
      final file = File(imagePath);
      final sessionCode =
          await _imageUploadService.createGuardianProfilePhotoUploadSession(
        guardianCode: guardianCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 15));
      final lowerPath = imagePath.toLowerCase();
      final fileName = lowerPath.split(Platform.pathSeparator).last;
      final contentType =
          lowerPath.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final presign = await _imageUploadService.createAssetPresign(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
        fileName: fileName.isNotEmpty
            ? fileName
            : 'guardian-profile-photo-${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: 'IMAGE',
        ownerType: 'GUARDIAN',
        ownerCode: guardianCode,
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 25));
      await _imageUploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: contentType,
        onSendProgress: (int sent, int total) {
          if (isClosed || total <= 0) return;
          final uploadPhasePercent = (sent / total).clamp(0.0, 1.0);
          emit(
            state.copyWith(
              profilePhotoUploadPercent: 25 + (uploadPhasePercent * 55),
            ),
          );
        },
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 84));
      await _imageUploadService.completeAssetUpload(
        sessionCode: sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: '/api/v1',
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 90));
      await _imageUploadService.waitUntilAssetsReady(
        sessionCode: sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (!isClosed) emit(state.copyWith(profilePhotoUploadPercent: 100));
      final resolvedUrl = await _imageUploadService.finalizeGuardianProfilePhoto(
        guardianCode: guardianCode,
        assetCode: presign.assetCode,
        schoolCode: schoolCode,
        userCode: userCode,
      );

      DocumentImageWidget.clearProfilePhotoCache();
      // Persist the freshly-uploaded photo so the three-dot (kebab) menu header
      // (which reads these keys from storage) shows it immediately too.
      try {
        await _storage.saveString(
          StorageKeys.guardianProfileAssetCode,
          presign.assetCode.trim(),
        );
        await _storage.saveString(
          StorageKeys.guardianProfilePhotoUrl,
          resolvedUrl.trim(),
        );
      } catch (_) {}
      if (!isClosed) {
        emit(
          state.copyWith(
            guardianPhotoUrl: resolvedUrl.trim(),
            guardianPhotoAssetCode: presign.assetCode.trim(),
          ),
        );
      }
      await loadGuardianProfileForParent();
      return const UserProfilePhotoResult(
        UserProfilePhotoStatus.success,
        'Profile photo updated successfully',
      );
    } catch (e) {
      return UserProfilePhotoResult(
        UserProfilePhotoStatus.uploadError,
        'Failed to update profile photo: $e',
      );
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            isUploadingProfilePhoto: false,
            profilePhotoUploadPercent: 0,
          ),
        );
      }
    }
  }
}
