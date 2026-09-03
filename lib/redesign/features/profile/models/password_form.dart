import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// The three wells on Change Password.
@immutable
class PasswordFormData extends Equatable {
  const PasswordFormData({
    this.current = '',
    this.next = '',
    this.confirm = '',
  });

  final String current;
  final String next;
  final String confirm;

  PasswordFormData copyWith({String? current, String? next, String? confirm}) =>
      PasswordFormData(
        current: current ?? this.current,
        next: next ?? this.next,
        confirm: confirm ?? this.confirm,
      );

  @override
  List<Object?> get props => <Object?>[current, next, confirm];
}

/// One error line per well, or null where the well is fine.
@immutable
class PasswordFormErrors extends Equatable {
  const PasswordFormErrors({this.current, this.next, this.confirm});

  static const PasswordFormErrors none = PasswordFormErrors();

  final String? current;
  final String? next;
  final String? confirm;

  bool get isEmpty => current == null && next == null && confirm == null;

  @override
  List<Object?> get props => <Object?>[current, next, confirm];
}

/// The rules `change_password_screen.dart` applies: current required, new at
/// least 8 characters with a special character, confirm matching, and new
/// different from current.
abstract final class PasswordFormValidator {
  static const int minLength = 8;
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  static bool isStrong(String password) =>
      password.length >= minLength && _special.hasMatch(password);

  static PasswordFormErrors validate(PasswordFormData form) {
    final current = form.current.trim();
    final next = form.next.trim();
    final confirm = form.confirm.trim();

    return PasswordFormErrors(
      current: current.isEmpty ? ProfileStrings.currentPasswordRequired : null,
      next: next.isEmpty
          ? ProfileStrings.newPasswordRequired
          : !isStrong(next)
          ? ProfileStrings.newPasswordInvalid
          : next == current
          ? ProfileStrings.newSameAsCurrent
          : null,
      confirm: next.isNotEmpty && next != confirm
          ? ProfileStrings.confirmMismatch
          : null,
    );
  }
}
