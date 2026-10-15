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

  /// "Associate Teacher · Office" (omits blanks).
  String get subtitle {
    final d = designation.trim();
    final c = classroomName.trim();
    if (d.isNotEmpty && c.isNotEmpty) return '$d · $c';
    return d.isNotEmpty ? d : c;
  }
}
