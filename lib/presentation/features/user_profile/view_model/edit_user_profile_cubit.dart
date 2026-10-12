import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_my_profile_update.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/usecases/change_user_email_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_cached_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_my_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/user_profile/entities/guardian_profile_update.dart';
import 'package:wowcare/domain/features/user_profile/usecases/get_guardian_profile_usecase.dart';
import 'package:wowcare/domain/features/user_profile/usecases/update_guardian_profile_usecase.dart';

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
    required GetStaffProfileUseCase getStaffProfileUseCase,
    required GetCachedStaffProfileUseCase getCachedStaffProfileUseCase,
    required UpdateMyStaffProfileUseCase updateMyStaffProfileUseCase,
    required ChangeUserEmailUseCase changeUserEmailUseCase,
    required GetGuardianProfileUseCase getGuardianProfileUseCase,
    required UpdateGuardianProfileUseCase updateGuardianProfileUseCase,
  })  : _storageService = storageService,
        _getStaffProfileUseCase = getStaffProfileUseCase,
        _getCachedStaffProfileUseCase = getCachedStaffProfileUseCase,
        _updateMyStaffProfileUseCase = updateMyStaffProfileUseCase,
        _changeUserEmailUseCase = changeUserEmailUseCase,
        _getGuardianProfileUseCase = getGuardianProfileUseCase,
        _updateGuardianProfileUseCase = updateGuardianProfileUseCase,
        super(const EditUserProfileState.initial());

  final StorageService _storageService;
  final GetStaffProfileUseCase _getStaffProfileUseCase;
  final GetCachedStaffProfileUseCase _getCachedStaffProfileUseCase;
  final UpdateMyStaffProfileUseCase _updateMyStaffProfileUseCase;
  final ChangeUserEmailUseCase _changeUserEmailUseCase;
  final GetGuardianProfileUseCase _getGuardianProfileUseCase;
  final UpdateGuardianProfileUseCase _updateGuardianProfileUseCase;

  /// Backend `message` from the most recent successful save, so the view can
  /// surface it (like other APIs) instead of a hardcoded string.
  String? _lastSaveMessage;
  String? get lastSaveMessage => _lastSaveMessage;

  /// True when this save attempted an email change and the email-change API
  /// call itself failed (network error, backend rejection, etc.) — the rest
  /// of the profile (name/phone/address) may still have saved fine. The view
  /// uses this to show a warning instead of a plain success snackbar, so a
  /// failed email change is never silently indistinguishable from a real
  /// success — see [lastSaveMessage] for the reason, which is included in it
  /// when this is true.
  bool _emailChangeFailed = false;
  bool get emailChangeFailed => _emailChangeFailed;

  /// Shown on a successful email change instead of the raw email-change API
  /// response text (e.g. "User email change request added successfully") —
  /// matches the web app's "Verification Email Sent" banner copy so both
  /// clients tell the user the same thing in the same words.
  static const String _emailVerificationSentMessage =
      'A verification email has been sent to your new email address.';

  /// True once [loadProfile] runs for a guardian/parent persona, so [saveProfile]
  /// routes to the guardian update endpoint instead of the staff one.
  bool _isGuardian = false;

  /// Guardian record `code` (e.g. GUA_...) from the loaded profile — the
  /// my-profile PATCH identifies the guardian by this `code` in the body.
  String _guardianCode = '';

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

  /// Loads the profile for the current persona and emits it so the view can
  /// hydrate its controllers. For a guardian/parent this fetches the guardian
  /// profile; otherwise it loads the staff profile (cached first, then a
  /// background refresh). Each success bumps [profileRevision] so the view
  /// re-hydrates.
  Future<void> loadProfile({bool isParent = false}) async {
    if (isParent) {
      _isGuardian = true;
      await _loadGuardianProfile();
      return;
    }

    final staffCode = await _resolveLoggedInStaffCode();
    if (staffCode.isEmpty) return;

    try {
      var hadCached = false;

      final cached = await _getCachedStaffProfileUseCase(staffCode);
      if (isClosed) return;
      if (cached != null) {
        hadCached = true;
        _emitProfile(cached);
      }

      try {
        final fresh = await _getStaffProfileUseCase(
          staffCode: staffCode,
          forEditStaff: false,
        );
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

  /// Fetches the logged-in guardian's profile (`GET /api/v1/guardian/profile`)
  /// and emits it as a [StaffProfile] so the shared form hydrates its fields.
  Future<void> _loadGuardianProfile() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      if (schoolCode.isEmpty || userCode.isEmpty) {
        emit(state.copyWith(loadFailed: true));
        return;
      }

      final guardian = await _getGuardianProfileUseCase(
        schoolCode: schoolCode,
        userCode: userCode,
      );
      if (isClosed) return;

      _guardianCode = guardian.code;

      _emitProfile(
        StaffProfile(
          staffCode: '',
          userCode: userCode,
          organizationCode: '',
          schoolCode: schoolCode,
          firstName: guardian.firstName,
          lastName: guardian.lastName,
          fullName: guardian.fullName,
          email: guardian.email,
          phoneNumber: guardian.phoneNumber,
          staffType: '',
          status: '',
          designation: '',
          allowedClassroomCodes: const [],
          address: guardian.address,
          workSchedules: const [],
          breakSchedules: const [],
        ),
      );
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (isClosed) return;
      emit(state.copyWith(loadFailed: true));
    }
  }

  /// Persists the validated profile [fields]. If [email] differs from the cached
  /// email, the email-change API is attempted first (non-blocking on failure).
  ///
  /// The view is responsible for validating input before calling this.
  Future<EditProfileSaveResult> saveProfile({
    required StaffMyProfileUpdate fields,
    required String email,
    bool isParent = false,
  }) async {
    emit(state.copyWith(isSubmitting: true));
    _emailChangeFailed = false;

    if (isParent || _isGuardian) {
      return _saveGuardianProfile(fields: fields, email: email);
    }

    try {
      final staffCode = await _resolveLoggedInStaffCode();
      if (staffCode.isEmpty) {
        if (!isClosed) emit(state.copyWith(isSubmitting: false));
        return EditProfileSaveResult.unresolvedStaff;
      }

      // If email changed, call the email-change API before updating the rest
      // of the profile. Its own response `message` is the one that actually
      // matters here — the backend's email-change endpoint is what would say
      // something like "verification email sent to the new address", and
      // that message must reach the user, not get silently discarded in
      // favour of the unrelated /profile PATCH's generic message below.
      String? emailChangeMessage;
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      // The loaded profile's own email — what the form was actually
      // hydrated from and what's on screen — is the correct baseline for
      // "did the user change it", NOT the separate StorageKeys.email cache
      // (only written at login or on a previous successful email change,
      // so it can silently drift from the real current email and make a
      // genuine edit compare as "unchanged", skipping the email-change API
      // entirely while still reporting a plain success). Falls back to the
      // cache only in the unexpected case the profile hasn't loaded.
      final loadedProfileEmail = state.profile?.email.trim() ?? '';
      final cachedEmail =
          (await _storageService.getString(StorageKeys.email) ?? '').trim();
      final oldEmail = loadedProfileEmail.isNotEmpty
          ? loadedProfileEmail
          : cachedEmail;
      final organizationCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      final emailChanged =
          userCode.isNotEmpty &&
          oldEmail.isNotEmpty &&
          oldEmail.toLowerCase() != email.toLowerCase() &&
          organizationCode.isNotEmpty &&
          schoolCode.isNotEmpty;
      AppLogger.d(
        '[EmailChange][staff] typedEmail="$email" oldEmail="$oldEmail" '
        '(loadedProfileEmail="$loadedProfileEmail" cachedEmail="$cachedEmail") '
        'userCode="$userCode" org="$organizationCode" school="$schoolCode" '
        'emailChanged=$emailChanged',
      );

      if (emailChanged) {
        try {
          final apiMessage = await _changeUserEmailUseCase(
            userCode: userCode,
            oldEmail: oldEmail,
            newEmail: email,
            organizationCode: organizationCode,
            schoolCode: schoolCode,
          );
          AppLogger.d(
            '[EmailChange][staff] changeUserEmail OK apiMessage="$apiMessage"',
          );
          // The backend call succeeded — it either applied the change or
          // (per its own returned message) queued verification. Either way
          // this is the address the account will end up with, so the local
          // cache follows it; if verification is actually required, the
          // message surfaced below is what tells the user that, rather than
          // this app silently pretending nothing happened.
          await _storageService.saveString(StorageKeys.email, email);
          emailChangeMessage = _emailVerificationSentMessage;
        } catch (e) {
          // No longer swallowed: a failed email change must not be
          // indistinguishable from a successful one. The rest of the
          // profile (name/phone/address) still saves below — an email
          // failure alone shouldn't block those — but the final message
          // and `emailChangeFailed` flag tell the view to warn, not
          // congratulate.
          _emailChangeFailed = true;
          emailChangeMessage = ApiErrorHandler.extractErrorMessage(e);
          AppLogger.w(
            '[EmailChange][staff] changeUserEmail FAILED error=$e '
            'extractedMessage="$emailChangeMessage"',
          );
        }
      }

      final profileMessage = await _updateMyStaffProfileUseCase(
        staffCode: staffCode,
        fields: fields,
      );

      _lastSaveMessage = _combineSaveMessages(
        emailChanged: emailChanged,
        otherFieldsChanged: _didOtherProfileFieldsChange(fields, state.profile),
        emailChangeFailed: _emailChangeFailed,
        emailChangeMessage: emailChangeMessage,
        profileMessage: profileMessage,
      );
      AppLogger.w(
        '[EmailChange][staff] final lastSaveMessage="$_lastSaveMessage" '
        'emailChangeFailed=$_emailChangeFailed profileMessage="$profileMessage"',
      );

      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.success;
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      AppLogger.w('[EmailChange][staff] outer save FAILED error=$e');
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.failed;
    }
  }

  /// Picks the right banner message for the three cases the web app
  /// distinguishes:
  ///  - only the email changed → the email-change endpoint's own message
  ///    alone (e.g. "Verification Email Sent" — matches the web app exactly,
  ///    which shows only that notification when nothing else was edited).
  ///  - only other fields changed (email untouched) → the profile message
  ///    alone, as before.
  ///  - both changed → both messages combined into one banner. The web app
  ///    shows these as two separate stacked notifications, but this app's
  ///    top banner ([CoreUtils.showTopSnackBar]) is deliberately single-slot
  ///    — only one visible at a time, replacing any prior one instantly
  ///    (see its own comment: "prevents 'double banners' when multiple
  ///    events fire back-to-back") — so firing two banners in a row would
  ///    just have the second instantly replace the first, silently dropping
  ///    it. Concatenating both messages into one banner is what actually
  ///    guarantees the user sees both pieces of information in that case.
  String _combineSaveMessages({
    required bool emailChanged,
    required bool otherFieldsChanged,
    required bool emailChangeFailed,
    required String? emailChangeMessage,
    required String profileMessage,
  }) {
    if (!emailChanged) return profileMessage;
    if (emailChangeFailed) {
      return 'Profile updated, but the email change failed: '
          '${(emailChangeMessage ?? '').trim().isNotEmpty ? emailChangeMessage : 'please try again.'}';
    }
    final trimmedEmail = (emailChangeMessage ?? '').trim();
    if (!otherFieldsChanged) {
      return trimmedEmail.isNotEmpty ? trimmedEmail : profileMessage.trim();
    }
    final trimmedProfile = profileMessage.trim();
    if (trimmedEmail.isEmpty) return trimmedProfile;
    if (trimmedProfile.isEmpty) return trimmedEmail;
    return '$trimmedProfile $trimmedEmail';
  }

  /// Whether [fields] (the submitted name/phone/address values) differ from
  /// what was actually loaded into [profile] — this form always resubmits
  /// every field on every save (there's no per-field dirty tracking), so
  /// `updateMyProfile`/`updateGuardianMyProfile` always returns its generic
  /// success message even when nothing but the email actually changed. This
  /// is what lets [_combineSaveMessages] tell "only email changed" apart
  /// from "email + other fields changed". Comparisons are normalized
  /// (trimmed/lower-cased text, digits-only phone/zip) so formatting
  /// differences alone (title-casing, phone punctuation) don't cause a
  /// false positive. `addressCountry` is deliberately excluded — the form
  /// always hardcodes it to `'United States'` regardless of what's loaded,
  /// so comparing it would false-positive on every save for accounts whose
  /// stored value differs in casing/abbreviation.
  bool _didOtherProfileFieldsChange(
    StaffMyProfileUpdate fields,
    StaffProfile? profile,
  ) {
    if (profile == null) return true;
    String norm(String v) => v.trim().toLowerCase();
    String digits(String v) => v.replaceAll(RegExp(r'\D'), '');

    if (norm(fields.firstName) != norm(profile.firstName)) return true;
    if (norm(fields.lastName) != norm(profile.lastName)) return true;
    if (digits(fields.phoneNumber) != digits(profile.phoneNumber)) {
      return true;
    }
    final addr = profile.address;
    if (norm(fields.addressStreet) != norm(addr.street)) return true;
    if (norm(fields.addressLine2) != norm(addr.line2)) return true;
    if (norm(fields.addressCity) != norm(addr.city)) return true;
    if (norm(fields.addressState) != norm(addr.state)) return true;
    if (digits(fields.addressZipCode) != digits(addr.zipCode)) {
      return true;
    }
    return false;
  }

  /// Persists a guardian's edits via `PATCH /api/v1/guardian/my-profile`. The
  /// backend identifies the guardian by the `code` in the body, so the payload
  /// mirrors the guardian contract: `code`, name, `mobile`, and a nested
  /// `address` (line1 + street, postalCode). Email changes go through the
  /// separate user-generic email-change endpoint above, since this PATCH
  /// body has no `email` field in its own contract.
  Future<EditProfileSaveResult> _saveGuardianProfile({
    required StaffMyProfileUpdate fields,
    required String email,
  }) async {
    try {
      var guardianCode = _guardianCode.trim();
      if (guardianCode.isEmpty) {
        guardianCode =
            (await _storageService.getString(StorageKeys.guardianCode) ?? '')
                .trim();
      }
      if (guardianCode.isEmpty) {
        if (!isClosed) emit(state.copyWith(isSubmitting: false));
        return EditProfileSaveResult.failed;
      }

      // Mirrors the staff path above: `updateGuardianMyProfile`'s PATCH body
      // has no `email` field in its contract (only name/mobile/address), so
      // this used to silently drop an email edit entirely, with the screen
      // still reporting a plain success. The email-change endpoint is
      // user-generic (`POST /api/v1/users/{userCode}/email-change`, keyed
      // by userCode, not staffCode) despite living on StaffRepository —
      // reusable here as-is via [ChangeUserEmailUseCase].
      String? emailChangeMessage;
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      // See the matching comment in saveProfile's staff branch above: the
      // loaded profile's own email (what the form was hydrated from) is the
      // correct baseline, not the separate StorageKeys.email cache, which
      // can drift stale and make a genuine edit silently compare as
      // "unchanged".
      final loadedProfileEmail = state.profile?.email.trim() ?? '';
      final cachedEmail =
          (await _storageService.getString(StorageKeys.email) ?? '').trim();
      final oldEmail = loadedProfileEmail.isNotEmpty
          ? loadedProfileEmail
          : cachedEmail;
      final organizationCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      final emailChanged =
          userCode.isNotEmpty &&
          oldEmail.isNotEmpty &&
          oldEmail.toLowerCase() != email.toLowerCase() &&
          organizationCode.isNotEmpty &&
          schoolCode.isNotEmpty;
      AppLogger.d(
        '[EmailChange][guardian] typedEmail="$email" oldEmail="$oldEmail" '
        '(loadedProfileEmail="$loadedProfileEmail" cachedEmail="$cachedEmail") '
        'userCode="$userCode" org="$organizationCode" school="$schoolCode" '
        'emailChanged=$emailChanged',
      );

      if (emailChanged) {
        try {
          final apiMessage = await _changeUserEmailUseCase(
            userCode: userCode,
            oldEmail: oldEmail,
            newEmail: email,
            organizationCode: organizationCode,
            schoolCode: schoolCode,
          );
          await _storageService.saveString(StorageKeys.email, email);
          AppLogger.d(
            '[EmailChange][guardian] changeUserEmail OK apiMessage="$apiMessage"',
          );
          emailChangeMessage = _emailVerificationSentMessage;
        } catch (e) {
          _emailChangeFailed = true;
          emailChangeMessage = ApiErrorHandler.extractErrorMessage(e);
          AppLogger.w(
            '[EmailChange][guardian] changeUserEmail FAILED error=$e '
            'extractedMessage="$emailChangeMessage"',
          );
        }
      }

      // fields.phoneNumber carries the staff form's '+<digits>' shape (see
      // the view) — strip everything but digits for the guardian contract's
      // plain `mobile` field.
      final phoneDigits = fields.phoneNumber.replaceAll(RegExp(r'\D'), '');

      final profileMessage = await _updateGuardianProfileUseCase(
        GuardianProfileUpdate(
          guardianCode: guardianCode,
          firstName: fields.firstName.trim(),
          lastName: fields.lastName.trim(),
          phoneDigits: phoneDigits,
          addressStreet: fields.addressStreet.trim(),
          addressLine2: fields.addressLine2.trim(),
          addressCity: fields.addressCity.trim(),
          addressState: fields.addressState.trim(),
          addressZipCode: fields.addressZipCode.trim(),
          addressCountry: fields.addressCountry.trim(),
        ),
      );

      _lastSaveMessage = _combineSaveMessages(
        emailChanged: emailChanged,
        otherFieldsChanged: _didOtherProfileFieldsChange(fields, state.profile),
        emailChangeFailed: _emailChangeFailed,
        emailChangeMessage: emailChangeMessage,
        profileMessage: profileMessage,
      );

      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.success;
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.failed;
    }
  }
}
