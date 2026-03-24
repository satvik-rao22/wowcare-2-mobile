/// Static school catalog (offline/fallback).
///
/// Add your schools here when you want the app to work without relying on the
/// `/api/v1/schools/names-by-org/{orgCode}` endpoint.
///
/// Notes
/// - `organizationCode` can be `*` to make the school available for ANY org.
/// - Consumers typically need entries shaped as `{schoolCode, schoolName}`.
/// Default catalog is empty. Add real schools here if you need offline / static
/// school selection, e.g. for demos without calling the schools API.
const List<Map<String, String>> kStaticSchoolCatalog = <Map<String, String>>[
  // Example:
  // <String, String>{
  //   'organizationCode': '*',
  //   'schoolCode': 'SCHOOL_CODE',
  //   'schoolName': 'My Demo School',
  // },
];

List<Map<String, String>> staticSchoolSelectionEntriesForOrg({
  required String organizationCode,
  List<String> restrictToSchoolCodes = const <String>[],
}) {
  final org = organizationCode.trim();
  final restrict = restrictToSchoolCodes
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  final filtered = kStaticSchoolCatalog.where((e) {
    final eOrg = (e['organizationCode'] ?? '').trim();
    final eCode = (e['schoolCode'] ?? '').trim();
    if (eCode.isEmpty) return false;
    final orgMatch = eOrg == '*' || (org.isNotEmpty && eOrg == org);
    if (!orgMatch) return false;
    if (restrict.isEmpty) return true;
    return restrict.contains(eCode);
  }).toList();

  // Return in the shape the School Selection UI expects.
  return filtered
      .map((e) => <String, String>{
            'schoolCode': (e['schoolCode'] ?? '').trim(),
            'schoolName': (e['schoolName'] ?? e['schoolCode'] ?? '').trim(),
          })
      .where((e) => e['schoolCode']!.isNotEmpty)
      .toList();
}

String? staticSchoolNameForCode(String schoolCode) {
  final code = schoolCode.trim();
  if (code.isEmpty) return null;
  for (final e in kStaticSchoolCatalog) {
    if ((e['schoolCode'] ?? '').trim() == code) {
      final name = (e['schoolName'] ?? '').trim();
      return name.isEmpty ? code : name;
    }
  }
  return null;
}









