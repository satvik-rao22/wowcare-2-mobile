class StringUtils {
  /// Returns staffType/role as-is for display (underscores → spaces, title case).
  static String staffTypeToDisplayRole(String code) {
    if (code.trim().isEmpty) return '';
    return code
        .split('_')
        .map((e) => e.isNotEmpty ? '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  static String getInitials(String roomName) {
    final parts = roomName
        .split(RegExp(r'[-\s]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
  }
}
