class StringUtils {
  /// Returns staffType/role as-is for display (underscores → spaces, title case).
  static String staffTypeToDisplayRole(String code) {
    if (code.trim().isEmpty) return '';
    return code
        .split('_')
        .map(
          (e) => e.isNotEmpty
              ? '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
