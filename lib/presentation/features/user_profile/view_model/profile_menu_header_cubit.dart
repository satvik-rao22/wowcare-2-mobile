import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/string_utils.dart';

/// Summary shown in the profile menu header (name, persona, avatar sources).
class ProfileMenuHeaderState extends Equatable {
  const ProfileMenuHeaderState({
    this.displayName = 'User',
    this.persona = 'Profile',
    this.staffCode = '',
    this.guardianAssetCode = '',
    this.guardianPhotoUrl = '',
  });

  final String displayName;
  final String persona;
  final String staffCode;
  final String guardianAssetCode;
  final String guardianPhotoUrl;

  @override
  List<Object?> get props => [
        displayName,
        persona,
        staffCode,
        guardianAssetCode,
        guardianPhotoUrl,
      ];
}

/// Loads the current user's header summary from storage so the widget stays
/// display-only (replaces in-widget storage reads + `setState`).
class ProfileMenuHeaderCubit extends Cubit<ProfileMenuHeaderState> {
  ProfileMenuHeaderCubit(this._storage)
      : super(const ProfileMenuHeaderState());

  final StorageService _storage;

  /// [isGuardian] is the current active persona. In the guardian persona the
  /// header must show the **guardian's** own name + "Guardian" (and the guardian
  /// avatar) — not the staff/admin identity, which is a different name/role for
  /// dual-persona users.
  Future<void> loadSummary({bool isGuardian = false}) async {
    try {
      final name =
          (await _storage.getString(StorageKeys.displayName) ?? '').trim();
      final staffCode =
          (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
      final guardianAssetCode =
          (await _storage.getString(StorageKeys.guardianProfileAssetCode) ?? '')
              .trim();
      final guardianPhotoUrl =
          (await _storage.getString(StorageKeys.guardianProfilePhotoUrl) ?? '')
              .trim();

      if (isGuardian) {
        final first =
            (await _storage.getString(StorageKeys.guardianProfileFirstName) ??
                    '')
                .trim();
        final last =
            (await _storage.getString(StorageKeys.guardianProfileLastName) ??
                    '')
                .trim();
        final guardianName = '$first $last'.trim();
        emit(ProfileMenuHeaderState(
          // Fall back to the login name only if the guardian name isn't cached
          // yet (profile still loading).
          displayName: guardianName.isNotEmpty
              ? guardianName
              : (name.isNotEmpty ? name : 'User'),
          persona: 'Guardian',
          // Guardian avatar only — never the staff photo.
          staffCode: '',
          guardianAssetCode: guardianAssetCode,
          guardianPhotoUrl: guardianPhotoUrl,
        ));
        return;
      }

      // Prefer staffType from storage (from staff profile API); fallback to roles.
      var persona = '';
      final staffDesignation =
          (await _storage.getString(StorageKeys.staffDesignation) ?? '').trim();
      final staffType =
          (await _storage.getString(StorageKeys.staffType) ?? '').trim();
      if (staffDesignation.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(staffDesignation);
      } else if (staffType.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(staffType);
      }
      if (persona.isEmpty) {
        final rolesJson = await _storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.isNotEmpty) {
          try {
            final roles = jsonDecode(rolesJson) as List<dynamic>;
            if (roles.isNotEmpty) {
              final first = roles.first as Map<String, dynamic>;
              final roleCode = (first['role'] ?? '').toString().toUpperCase();
              persona = StringUtils.staffTypeToDisplayRole(roleCode);
            }
          } catch (_) {}
        }
      }

      emit(ProfileMenuHeaderState(
        displayName: name.isNotEmpty ? name : 'User',
        persona: persona.isNotEmpty ? persona : 'Profile',
        staffCode: staffCode,
        guardianAssetCode: guardianAssetCode,
        guardianPhotoUrl: guardianPhotoUrl,
      ));
    } catch (_) {
      emit(const ProfileMenuHeaderState());
    }
  }
}
