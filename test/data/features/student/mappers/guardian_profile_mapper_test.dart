import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/guardian_profile_mapper.dart';

void main() {
  test('extracts fields from camelCase keys', () {
    final p = guardianProfileFromMap(<String, dynamic>{
      'code': ' G1 ',
      'firstName': ' Jane ',
      'lastName': ' Doe ',
      'profilePhotoAssetCode': 'A1',
      'profilePhotoUrl': 'https://cdn/j.png',
    });
    expect(p.code, 'G1');
    expect(p.firstName, 'Jane');
    expect(p.lastName, 'Doe');
    expect(p.photoAssetCode, 'A1');
    expect(p.photoUrl, 'https://cdn/j.png');
  });

  test('falls back through key aliases (Pascal/snake, alt code keys)', () {
    final p = guardianProfileFromMap(<String, dynamic>{
      'ParentCode': 'G9',
      'first_name': 'Al',
      'LastName': 'Bee',
      'photoAssetCode': 'A2',
      'imageUrl': 'https://cdn/a.png',
    });
    expect(p.code, 'G9');
    expect(p.firstName, 'Al');
    expect(p.lastName, 'Bee');
    expect(p.photoAssetCode, 'A2');
    expect(p.photoUrl, 'https://cdn/a.png');
  });

  test('missing keys default to empty strings', () {
    final p = guardianProfileFromMap(<String, dynamic>{});
    expect(p.code, '');
    expect(p.firstName, '');
    expect(p.photoUrl, '');
  });
}
