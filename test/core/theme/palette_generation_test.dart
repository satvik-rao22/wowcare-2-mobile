/// `AppPalette` is generated from the skin files by `tool/gen_palette.dart`.
/// These tests fail the build when the generated file is stale, and when a
/// skin overrides a role the base skin does not declare (a typo would
/// otherwise silently fall back to the base value).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/gen_palette.dart';

void main() {
  test('app_palette.gen.dart matches what the skin files generate', () {
    final String generated = generatePalette(
      config: File('$themeDir/app_theme_config.dart').readAsStringSync(),
      skins: readSkinSources(),
    );
    expect(
      File('$themeDir/$outputName').readAsStringSync(),
      generated,
      reason:
          'A skin changed without regenerating the palette. Run: '
          'dart run tool/gen_palette.dart',
    );
  });

  test('a skin cannot override a role the base does not declare', () {
    expect(
      () => generatePalette(
        config: 'enum AppSkin { base, other }',
        skins: <String, String>{
          'skin_base.dart': '''
abstract final class BaseSkin {
  static const Color brand = BrandRamps.pink600;
}
''',
          'skin_other.dart': '''
abstract final class OtherSkin {
  static const Color brnad = BrandRamps.teal500;
}
''',
        },
      ),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('brnad'),
        ),
      ),
    );
  });

  test('every AppSkin value needs a skin file, and the reverse', () {
    expect(
      () => generatePalette(
        config: 'enum AppSkin { base, missing }',
        skins: <String, String>{
          'skin_base.dart': '''
abstract final class BaseSkin {
  static const Color brand = BrandRamps.pink600;
}
''',
        },
      ),
      throwsStateError,
    );
  });
}
