import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One school an account can open (1c). Mirrors the `{schoolCode,
/// schoolName}` pair `getSchoolNamesByOrg` returns, plus the status the
/// `/users/details` call adds: a school that is not `ACTIVE` is [isLocked].
@immutable
class AuthSchool extends Equatable {
  const AuthSchool({
    required this.id,
    required this.code,
    required this.name,
    this.isLocked = false,
    this.isCurrent = false,
  });

  final String id;

  /// The backend's school code, shown under the name (1c "SCH_2481").
  final String code;
  final String name;

  /// Pending approval: drawn, but cannot be opened.
  final bool isLocked;

  /// The school the account last worked in.
  final bool isCurrent;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  @override
  List<Object?> get props => [id, code, name, isLocked, isCurrent];
}

/// One organization an account belongs to (1b). Mirrors the organization
/// codes lifted off the login response's roles, with the display name
/// `getOrganizationNames` resolves and the role the account holds there.
@immutable
class AuthOrganization extends Equatable {
  const AuthOrganization({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.schools,
  });

  final String id;
  final String name;

  /// "Admin", "Lead Teacher": the role this account holds here.
  final String roleLabel;
  final List<AuthSchool> schools;

  /// The schools this account can actually open.
  List<AuthSchool> get openSchools =>
      schools.where((s) => !s.isLocked).toList();

  @override
  List<Object?> get props => [id, name, roleLabel, schools];
}
