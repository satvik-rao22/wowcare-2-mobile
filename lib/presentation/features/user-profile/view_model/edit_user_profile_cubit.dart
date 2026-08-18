import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../data/features/student/datasources/student_remote_datasource.dart';
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
    required StudentRemoteDataSource studentRemoteDataSource,
  })  : _storageService = storageService,
        _staffRepository = staffRepository,
        _studentRemoteDataSource = studentRemoteDataSource,
        super(const EditUserProfileState.initial());

  final StorageService _storageService;
  final StaffRepository _staffRepository;
  final StudentRemoteDataSource _studentRemoteDataSource;

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

      final data = await _studentRemoteDataSource.getGuardianProfile(
        schoolCode: schoolCode,
        userCode: userCode,
      );
      if (isClosed) return;

      _guardianCode = (data['code'] ?? '').toString().trim();

      final firstName = (data['firstName'] ?? '').toString().trim();
      final lastName = (data['lastName'] ?? '').toString().trim();
      final fullName = (data['fullName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final phone =
          (data['mobile'] ?? data['phone'] ?? data['phoneNumber'] ?? '')
              .toString()
              .trim();

      final address = _parseGuardianAddress(data['address']);

      _emitProfile(
        StaffProfile(
          staffCode: '',
          userCode: userCode,
          organizationCode: '',
          schoolCode: schoolCode,
          firstName: firstName,
          lastName: lastName,
          fullName:
              fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim(),
          email: email,
          phoneNumber: phone,
          staffType: '',
          status: '',
          designation: '',
          allowedClassroomCodes: const [],
          address: address,
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

  /// Maps the guardian profile `address` (a nested object, or null) into a
  /// [StaffProfileAddress]. The guardian API uses `line1`/`postalCode`; also
  /// tolerates the `street`/`zipCode`/`addressStreet` key styles seen elsewhere.
  StaffProfileAddress _parseGuardianAddress(dynamic raw) {
    if (raw is! Map) return const StaffProfileAddress();
    final m = Map<String, dynamic>.from(raw);
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    return StaffProfileAddress(
      street: pick(['line1', 'street', 'addressStreet']),
      line2: pick(['line2', 'addressLine2']),
      city: pick(['city', 'addressCity']),
      state: pick(['state', 'addressState']),
      zipCode: pick(['postalCode', 'zipCode', 'addressZipCode']),
      country: pick(['country', 'addressCountry']),
    );
  }


  /// Persists the validated profile [fields]. If [email] differs from the cached
  /// email, the email-change API is attempted first (non-blocking on failure).
  ///
  /// The view is responsible for validating input before calling this.
  Future<EditProfileSaveResult> saveProfile({
    required Map<String, dynamic> fields,
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

      final repo = _staffRepository;

      // If email changed, call the email-change API before updating the rest
      // of the profile. Its own response `message` is the one that actually
      // matters here — the backend's email-change endpoint is what would say
      // something like "verification email sent to the new address", and
      // that message must reach the user, not get silently discarded in
      // favour of the unrelated /profile PATCH's generic message below.
      String? emailChangeMessage;
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
      final emailChanged =
          userCode.isNotEmpty &&
          oldEmail.isNotEmpty &&
          oldEmail.toLowerCase() != email.toLowerCase() &&
          organizationCode.isNotEmpty &&
          schoolCode.isNotEmpty;

      if (emailChanged) {
        try {
          emailChangeMessage = await repo.changeUserEmail(
            userCode: userCode,
            oldEmail: oldEmail,
            newEmail: email,
            organizationCode: organizationCode,
            schoolCode: schoolCode,
          );
          // The backend call succeeded — it either applied the change or
          // (per its own returned message) queued verification. Either way
          // this is the address the account will end up with, so the local
          // cache follows it; if verification is actually required, the
          // message surfaced below is what tells the user that, rather than
          // this app silently pretending nothing happened.
          await _storageService.saveString(StorageKeys.email, email);
        } catch (e) {
          // No longer swallowed: a failed email change must not be
          // indistinguishable from a successful one. The rest of the
          // profile (name/phone/address) still saves below — an email
          // failure alone shouldn't block those — but the final message
          // and `emailChangeFailed` flag tell the view to warn, not
          // congratulate.
          _emailChangeFailed = true;
          emailChangeMessage = ApiErrorHandler.extractErrorMessage(e);
        }
      }

      final profileMessage = await repo.updateMyProfile(
        staffCode: staffCode,
        fields: fields,
      );

      if (!emailChanged) {
        _lastSaveMessage = profileMessage;
      } else if (_emailChangeFailed) {
        _lastSaveMessage =
            'Profile updated, but the email change failed: '
            '${(emailChangeMessage ?? '').trim().isNotEmpty ? emailChangeMessage : 'please try again.'}';
      } else {
        // Prefer the email-change endpoint's own message (e.g. a
        // verification notice) — it's the more specific, actionable one
        // when an email change was actually attempted.
        final trimmed = (emailChangeMessage ?? '').trim();
        _lastSaveMessage = trimmed.isNotEmpty ? trimmed : profileMessage;
      }

      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.success;
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.failed;
    }
  }

  /// Formats a raw ZIP into the `12345` / `12345-6789` shape the guardian API
  /// returns (input may already contain a hyphen or be digits-only).
  String _formatPostalCode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5, digits.length.clamp(5, 9))}';
  }

  /// Persists a guardian's edits via `PATCH /api/v1/guardian/my-profile`. The
  /// backend identifies the guardian by the `code` in the body, so the payload
  /// mirrors the guardian contract: `code`, name, `mobile`, and a nested
  /// `address` (line1 + street, postalCode). Email is not part of this endpoint.
  Future<EditProfileSaveResult> _saveGuardianProfile({
    required Map<String, dynamic> fields,
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

      final phoneDigits =
          (fields['phoneNumber'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

      final body = <String, dynamic>{
        'code': guardianCode,
        'firstName': (fields['firstName'] ?? '').toString().trim(),
        'lastName': (fields['lastName'] ?? '').toString().trim(),
        'mobile': phoneDigits,
      };

      // Include address only when the guardian actually supplied one, in the
      // exact shape the guardian API uses (line1 holds the street; a separate
      // empty `street` is sent to match the contract).
      final street = (fields['addressStreet'] ?? '').toString().trim();
      final line2 = (fields['addressLine2'] ?? '').toString().trim();
      final city = (fields['addressCity'] ?? '').toString().trim();
      final stateVal = (fields['addressState'] ?? '').toString().trim();
      final zip = (fields['addressZipCode'] ?? '').toString().trim();
      final country = (fields['addressCountry'] ?? '').toString().trim();
      if ([street, line2, city, stateVal, zip].any((s) => s.isNotEmpty)) {
        body['address'] = <String, dynamic>{
          'line1': street,
          'line2': line2,
          'city': city,
          'state': stateVal,
          'country': country,
          'postalCode': _formatPostalCode(zip),
          'street': '',
        };
      }

      _lastSaveMessage =
          await _studentRemoteDataSource.updateGuardianMyProfile(body: body);

      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.success;
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditProfileSaveResult.failed;
    }
  }
}
