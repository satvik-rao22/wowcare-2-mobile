import 'package:wowcare/domain/features/staff/entities/staff_member.dart';

/// Resolves classroom codes to display names using the active-classrooms API map.
class ClassroomNameResolver {
  const ClassroomNameResolver([this._namesByCode = const {}]);

  final Map<String, String> _namesByCode;

  factory ClassroomNameResolver.fromMap(Map<String, String> namesByCode) {
    final normalized = <String, String>{};
    namesByCode.forEach((code, name) {
      final c = code.trim();
      if (c.isEmpty) return;
      final n = name.trim();
      normalized[c] = n.isNotEmpty ? n : c;
    });
    return ClassroomNameResolver(normalized);
  }

  String? _lookup(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;

    final direct = _namesByCode[c];
    if (direct != null && direct.isNotEmpty) return direct;

    final upper = c.toUpperCase();
    for (final entry in _namesByCode.entries) {
      if (entry.key.toUpperCase() == upper) {
        return entry.value.isNotEmpty ? entry.value : null;
      }
    }
    return null;
  }

  static bool looksLikeClassroomCode(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return v.startsWith('CLS_') ||
        v.startsWith('cls_') ||
        RegExp(r'^CLS[_-]', caseSensitive: false).hasMatch(v);
  }

  String resolve(String? code, {String fallback = ''}) {
    final c = code?.trim() ?? '';
    if (c.isEmpty) return fallback;

    final mapped = _lookup(c);
    if (mapped != null) return mapped;

    // Already a human-readable label (not a code).
    if (!looksLikeClassroomCode(c)) return c;

    final fb = fallback.trim();
    return fb.isNotEmpty ? fb : c;
  }

  String resolveForStaff(StaffMember staff) {
    final fromPrimaryName = staff.primaryClassroomName.trim();
    if (fromPrimaryName.isNotEmpty) return fromPrimaryName;

    final code = staff.primaryClassroomOrFirstAllowed.trim();
    if (code.isEmpty) return '';

    final fromAllowed = staff.allowedClassroomNameByCode[code]?.trim() ?? '';
    if (fromAllowed.isNotEmpty) return fromAllowed;

    return resolve(code);
  }

  /// Returns display label for a shift block room field (code or "Lunch Break").
  String resolveShiftRoom(String room) {
    final r = room.trim();
    if (r.isEmpty) return r;
    if (r.toLowerCase().contains('lunch')) return r;
    return resolve(r);
  }
}
