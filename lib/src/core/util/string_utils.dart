class StringUtils {
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
