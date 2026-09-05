/// Composable, pure validation rules shared across forms. No Flutter
/// imports — these are plain functions so they can be unit tested and
/// reused from both cubits and views.
abstract final class AppValidators {
  /// A new/changed password must be at least 8 characters and contain at
  /// least one special character.
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.isNotEmpty && trimmed.contains('@');
  }
}
