import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

part 'edit_user_profile_state.dart';

/// Outcome of a profile save, returned to the view so it can pick the right
/// snackbar / navigation without inspecting cubit internals.
enum EditProfileSaveResult { success, unresolvedStaff, failed }

/// Owns the data/business logic for the edit-profile screen: resolving the
/// logged-in staff code, loading the profile (cache-first then refresh) and
/// persisting edits (including the email-change side effect).
///
/// The view keeps its text controllers and validation (input concerns) and
/// hydrates them whenever the cubit emits a fresh [EditUserProfileState.profile].
class EditUserProfileCubit extends Cubit<EditUserProfileState> {
  EditUserProfileCubit({
    required StorageService storageService,
    required StaffRepository staffRepository,
  })  : _storageService = storageService,
        _staffRepository = staffRepository,
        super(const EditUserProfileState.initial());

  final StorageService _storageService;
  final StaffRepository _staffRepository;

  /// Resolves the staffCode for the currently logged-in user from local cache.
  Future<String> _resolveLoggedInStaffCode() async {
    try {
      final currentUserCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      final cachedStaffCode =
          (await _storageService.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await _storageService.getString(StorageKeys.staffCodeUser) ?? '')
              .trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          currentUserCode.isNotEmpty &&
          cachedStaffUser == currentUserCode) {
        return cachedStaffCode;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Loads the staff profile (cached first for instant UI, then a background
  /// refresh). Each successful fetch is emitted as a new [profile] with a bumped
  /// [profileRevision] so the view re-hydrates its controllers.
  Future<void> loadProfile() async {
    final staffCode = await _resolveLoggedInStaffCode();
    if (staffCode.isEmpty) return;

    try {
      final repo = _staffRepository;
      var hadCached = false;

      if (repo is StaffRepositoryWithCache) {
        final cached =
            await (repo as StaffRepositoryWithCache).loadCachedStaffProfile(
          staffCode,
        );
        if (isClosed) return;
        if (cached != null) {
          hadCached = true;
          _emitProfile(cached);
        }
      }

      try {
        final fresh = await repo.getStaffProfile(staffCode: staffCode);
        if (isClosed) return;
        _emitProfile(fresh);
      } catch (e) {
        CoreUtils.logApiError(e.toString());
        if (isClosed) return;
        if (!hadCached) {
          emit(state.copyWith(loadFailed: true));
        }
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (isClosed) return;
      emit(state.copyWith(loadFailed: true));
    }
  }

  void _emitProfile(StaffProfile profile) {
    emit(
      state.copyWith(
        profile: profile,
        profileRevision: state.profileRevision + 1,
        loadFailed: false,
      ),
    );
  }

  /// Persists the validated profile [fields]. If [email] differs from the cached
  /// email, the email-change API is attempted first (non-blocking on failure).
  ///
  /// The view is responsible for validating input before calling this.
  Future<EditProfileSaveResult> saveProfile({
    required Map<String, dynamic> fields,
    required String email,
  }) async {
    emit(state.copyWith(isSubmitting: true));

    try {
      final staffCode = await _resolveLoggedInStaffCode();
      if (staffCode.isEmpty) {
        if (!isClosed) emit(state.copyWith(isSubmitting: false));
        return EditProfileSaveResult.unresolvedStaff;
      }

      final repo = _staffRepository;

      // If email changed, call email-change API before updating the profile.
      try {
        final userCode =
            (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
        final oldEmail =
            (await _storageService.getString(StorageKeys.email) ?? '').trim();
        final organizationCode =
            (await _storageService.getString(StorageKeys.organizationCode) ?? '')
                .trim();
        final schoolCode =
            (await _storageService.getString(StorageKeys.schoolCode) ?? '')
                .trim();

        if (userCode.isNotEmpty &&
            oldEmail.isNotEmpty &&
            oldEmail.toLowerCase() != email &&
            organizationCode.isNotEmpty &&
            schoolCode.isNotEmpty) {
          await repo.changeUserEmail(
            userCode: userCode,
            oldEmail: oldEmail,
            newEmail: email,
            organizationCode: organizationCode,
            schoolCode: schoolCode,
          );
          // Keep local storage in sync with the new email.
          await _storageService.saveString(StorageKeys.email, email);
        }
      } catch (_) {
        // Non-blocking: email-change failure should not block the profile save.
      }

      await repo.updateMyProfile(staffCode: staffCode, fields: fields);

      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.success;
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.failed;
    }
  }
}
