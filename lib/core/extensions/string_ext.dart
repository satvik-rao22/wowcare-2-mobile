extension StringDisplayExt on String {
  /// Turns a backend role code (`SCHOOL_ADMIN`, `lead_teacher`) into a
  /// display label (`School Admin`, `Lead Teacher`): lowercased, `_`
  /// replaced with spaces, each word capitalized.
  String get toDisplayRole {
    if (isEmpty) return '';
    final cleaned = toLowerCase().replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
