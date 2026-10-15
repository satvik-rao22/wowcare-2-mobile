/// The app's String extensions. Add new ones here, not in a new file.
extension AppStringExtension on String {
  /// Up to two initials for an avatar: the first letters of the first and
  /// last words, split on spaces and hyphens. `Riya Kumari Sharma` → `RS`,
  /// `riya` → `R`, `Room-A` → `RA`, blank → ``.
  String get initials {
    final words = trim()
        .split(RegExp(r'[-\s]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    final first = words.first[0];
    return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
  }

  /// Turns a backend role code (`SCHOOL_ADMIN`, `lead_teacher`) into a
  /// display label (`School Admin`, `Lead Teacher`): lowercased, `_`
  /// replaced with spaces, each word capitalized.
  String get toDisplayRole {
    if (isEmpty) return '';
    final cleaned = toLowerCase().replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
