/// Lightweight staff record for the admin "switch staff" picker.
class Av2StaffSummary {
  const Av2StaffSummary({
    required this.code,
    required this.name,
    this.designation = '',
    this.classroomName = '',
  });

  final String code;
  final String name;
  final String designation;
  final String classroomName;

  /// "Chaitanya Bhave" -> "CB".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// "Associate Teacher · Office" (omits blanks).
  String get subtitle {
    final d = designation.trim();
    final c = classroomName.trim();
    if (d.isNotEmpty && c.isNotEmpty) return '$d · $c';
    return d.isNotEmpty ? d : c;
  }
}
