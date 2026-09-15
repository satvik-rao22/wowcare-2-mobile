import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/shared/common/app/cubits/theme_cubit.dart';

/// Guards the invariant that makes `lib/core/theme/app_theme_config.dart` the
/// single control point for the app's colours and fonts: no other file in
/// `lib/` may name a colour or a font family of its own.
///
/// If one of these fails, the fix is to add (or reuse) a token in the config
/// file and reference it, not to relax the test.
void main() {
  /// `surfaceTint` is satisfied either by transparent or by not being set.
  final Matcher isTransparent = anyOf(
    isNull,
    equals(AppColors.transparentColor),
  );

  /// Every `.dart` file under `lib/`, paired with its source, with the theme
  /// definitions themselves excluded — those are where the values live.
  final List<({String path, String source})> sources =
      <({String path, String source})>[
        for (final FileSystemEntity e in Directory(
          'lib',
        ).listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart'))
            if (!e.path.startsWith('lib/core/theme/'))
              (path: e.path, source: e.readAsStringSync()),
      ];

  /// Blanks out `//`, `///` and `/* */` comments, preserving line numbers, so
  /// the scans below only look at code. Prose is free to mention `Colors.red`.
  String stripComments(String text) {
    final List<String> out = text.split('');
    int i = 0;
    String? quote;
    while (i < text.length) {
      final String ch = text[i];
      if (quote != null) {
        if (ch == r'\') {
          i += 2;
          continue;
        }
        if (ch == quote) quote = null;
        i++;
        continue;
      }
      // Comments are recognised *before* quotes. The other way round, an
      // apostrophe in a comment ("// don't") opens a string that swallows
      // the rest of the file and the scan goes blind.
      if (ch == '/' && i + 1 < text.length && text[i + 1] == '/') {
        int j = text.indexOf('\n', i);
        if (j == -1) j = text.length;
        for (int k = i; k < j; k++) {
          out[k] = ' ';
        }
        i = j;
        continue;
      }
      if (ch == '/' && i + 1 < text.length && text[i + 1] == '*') {
        int j = text.indexOf('*/', i);
        j = j == -1 ? text.length : j + 2;
        for (int k = i; k < j; k++) {
          if (out[k] != '\n') out[k] = ' ';
        }
        i = j;
        continue;
      }
      if (ch == "'" || ch == '"') {
        quote = ch;
        i++;
        continue;
      }
      i++;
    }
    return out.join();
  }

  /// `path:line` for every line of code matching [pattern].
  List<String> offenders(RegExp pattern) => <String>[
    for (final ({String path, String source}) f in sources)
      ...() {
        final List<String> lines = stripComments(f.source).split('\n');
        return <String>[
          for (int i = 0; i < lines.length; i++)
            if (pattern.hasMatch(lines[i])) '${f.path}:${i + 1}',
        ];
      }(),
  ];

  group('fonts are centralised', () {
    test('no file names a font family directly', () {
      // The families registered in pubspec.yaml. Product code must reach them
      // through AppFonts (a role) or AppFontFamilies (a specific family).
      final List<String> found = offenders(
        RegExp(
          "['\"](Manrope|Poppins|Inter|Imperial_Script|MervaleScript"
          "|monospace)['\"]",
        ),
      );
      expect(
        found,
        isEmpty,
        reason:
            'Font families belong to AppFonts / AppFontFamilies in '
            'lib/core/theme/app_theme_config.dart. Use AppFonts.body, '
            '.display, .script or .mono instead of a bare string at:\n'
            '${found.join('\n')}',
      );
    });

    test('the active skin picks a family that pubspec actually bundles', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final String family in <String>[
        AppFonts.body,
        AppFonts.display,
        AppFonts.numeric,
        AppFonts.scriptAlt,
      ]) {
        expect(
          pubspec,
          contains('- family: $family'),
          reason:
              '$family is not registered in pubspec.yaml, so Flutter '
              'would silently fall back to the platform font.',
        );
      }
    });

    test('ThemeData and AppTextStyles both follow the switch', () {
      expect(lightTheme.textTheme.titleLarge?.fontFamily, AppFonts.body);
      expect(darkTheme.textTheme.titleLarge?.fontFamily, AppFonts.body);
      expect(AppTextStyles.title.fontFamily, AppFonts.body);
      expect(AppTextStyles.body.fontFamily, AppFonts.body);
    });
  });

  group('colours are centralised', () {
    test("no file reaches into Flutter's Colors palette", () {
      // Colors.transparent is exempt: it is the absence of a colour, so it
      // means the same thing under every skin and no token can improve on it.
      final List<String> found = offenders(
        RegExp(r'(?<![A-Za-z0-9_.])Colors\.(?!transparent)'),
      );
      expect(
        found,
        isEmpty,
        reason:
            "Flutter's Colors.* swatches tie the app's look to Material "
            'defaults, and its shades are not const. Use a role from '
            'AppPalette, a token from AppColors, or — to keep an exact '
            'Material shade — MaterialHues, at:\n${found.join('\n')}',
      );
    });

    test('AppColors semantic tokens resolve to AppPalette roles', () {
      expect(AppColors.themeColor, AppPalette.brand);
      expect(AppColors.primaryColor, AppPalette.textPrimary);
      expect(AppColors.secondaryColor, AppPalette.brandSecondary);
      expect(AppColors.cardColor, AppPalette.surfaceCard);
      expect(AppColors.pageBackgroundColor, AppPalette.surfacePage);
      expect(AppColors.errorColor, AppPalette.statusError);
      expect(AppColors.warningColor, AppPalette.statusWarning);
      expect(AppColors.successColor, AppPalette.statusSuccess);
      expect(AppColors.accentColor, AppPalette.actionHighlight);
      expect(AppColors.dividerColor, AppPalette.divider);
      expect(AppColors.fieldBackgroundColor, AppPalette.surfaceField);
    });

    test('generated themes are driven by the palette', () {
      expect(lightTheme.primaryColor, AppPalette.brand);
      expect(darkTheme.primaryColor, AppPalette.brand);
      expect(lightTheme.textTheme.bodyMedium?.color, AppPalette.textPrimary);
    });

    test(
      'MaterialHues values match the Material swatches they stand in for',
      () {
        // These constants exist only to hold an exact Material value in a const
        // context. If Flutter ever changes a swatch, this catches the drift.
        //
        // Compared by ARGB rather than by identity: a bare swatch such as
        // `Colors.grey` is a MaterialColor, so `equals` would fail on the type
        // even when the rendered value is the same.
        void sameValue(Color token, Color swatch) =>
            expect(token.toARGB32(), swatch.toARGB32());

        sameValue(MaterialHues.grey50, Colors.grey.shade50);
        sameValue(MaterialHues.grey100, Colors.grey.shade100);
        sameValue(MaterialHues.grey200, Colors.grey.shade200);
        sameValue(MaterialHues.grey300, Colors.grey.shade300);
        sameValue(MaterialHues.grey400, Colors.grey.shade400);
        sameValue(MaterialHues.grey500, Colors.grey);
        sameValue(MaterialHues.grey600, Colors.grey.shade600);
        sameValue(MaterialHues.grey700, Colors.grey.shade700);
        sameValue(MaterialHues.grey800, Colors.grey.shade800);
        sameValue(MaterialHues.black87, Colors.black87);
        sameValue(MaterialHues.black54, Colors.black54);
        sameValue(MaterialHues.black26, Colors.black26);
        sameValue(MaterialHues.black12, Colors.black12);
        sameValue(MaterialHues.white70, Colors.white70);
        sameValue(MaterialHues.white38, Colors.white38);
        sameValue(MaterialHues.white24, Colors.white24);
        sameValue(MaterialHues.red, Colors.red);
        sameValue(MaterialHues.red50, Colors.red.shade50);
        sameValue(MaterialHues.red100, Colors.red.shade100);
        sameValue(MaterialHues.red200, Colors.red.shade200);
        sameValue(MaterialHues.red600, Colors.red.shade600);
        sameValue(MaterialHues.red700, Colors.red.shade700);
        sameValue(MaterialHues.redAccent, Colors.redAccent);
        sameValue(MaterialHues.redAccent100, Colors.redAccent.shade100);
        sameValue(MaterialHues.green, Colors.green);
        sameValue(MaterialHues.greenAccent100, Colors.greenAccent.shade100);
        sameValue(MaterialHues.lightGreen, Colors.lightGreen);
        sameValue(MaterialHues.orange, Colors.orange);
        sameValue(MaterialHues.orange50, Colors.orange.shade50);
        sameValue(MaterialHues.orange100, Colors.orange.shade100);
        sameValue(MaterialHues.orange800, Colors.orange.shade800);
        sameValue(MaterialHues.deepOrange, Colors.deepOrange);
        sameValue(MaterialHues.blue, Colors.blue);
        sameValue(MaterialHues.blue50, Colors.blue.shade50);
        sameValue(MaterialHues.blue400, Colors.blue.shade400);
        sameValue(MaterialHues.lightBlue, Colors.lightBlue);
        sameValue(MaterialHues.blueGrey, Colors.blueGrey);
        sameValue(MaterialHues.blueGrey700, Colors.blueGrey.shade700);
        sameValue(MaterialHues.indigo, Colors.indigo);
        sameValue(MaterialHues.purple, Colors.purple);
        sameValue(MaterialHues.deepPurple, Colors.deepPurple);
        sameValue(MaterialHues.pink, Colors.pink);
        sameValue(MaterialHues.teal, Colors.teal);
        sameValue(MaterialHues.cyan, Colors.cyan);
        sameValue(MaterialHues.amber, Colors.amber);
        sameValue(MaterialHues.yellow, Colors.yellow);
        sameValue(MaterialHues.brown, Colors.brown);
      },
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // The flat skeuomorphic re-skin — see docs/redesign-flat-skeu-plan.md
  // ═════════════════════════════════════════════════════════════════════════

  /// Every `.dart` file under `lib/`, the theme *definitions* included. Used
  /// by the colour-literal scan, which allows literals only in
  /// `app_theme_config.dart` itself.
  final List<({String path, String source})> allSources =
      <({String path, String source})>[
        for (final FileSystemEntity e in Directory(
          'lib',
        ).listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart'))
            if (e.path != 'lib/core/theme/app_theme_config.dart')
              (path: e.path, source: e.readAsStringSync()),
      ];

  group('the app is flat: no gradients', () {
    test('nothing under lib/ draws a gradient', () {
      // Rule 3 of the design language. This started as an allowlist of 119
      // files that shrank module by module; it reached zero, so the rule is
      // absolute now and the AppColors.build*Gradient() helpers are gone.
      // Depth comes from the bevel, the well, the rim and the ambient
      // shadow — see AppSurfaces.
      final List<String> found = offenders(
        RegExp(
          r'(?<![A-Za-z0-9_])(LinearGradient|RadialGradient|SweepGradient'
          r'|ShaderMask)(?![A-Za-z0-9_])',
        ),
      );
      expect(
        found,
        isEmpty,
        reason:
            'Swap the decoration for an AppSurfaces builder — card(), '
            'well(), key(), impact(), fab(), sheet(). A wash over a photo '
            'is AppPalette.mediaScrim, flat.\n${found.join('\n')}',
      );
    });
  });

  group("Material's own widgets follow the palette", () {
    test('the scheme is read from AppPalette, not derived from a seed', () {
      // ColorScheme.fromSeed(pink) made every Material surface a pink-tinted
      // neutral: the date picker's ground, a dropdown's menu, an
      // AlertDialog. None of it was reachable from app_theme_config.dart.
      for (final ColorScheme scheme in <ColorScheme>[
        lightTheme.colorScheme,
        darkTheme.colorScheme,
      ]) {
        expect(scheme.primary, AppPalette.brand);
        expect(scheme.onPrimary, AppPalette.onBrand);
        expect(scheme.surface, AppPalette.surfaceCard);
        expect(scheme.onSurface, AppPalette.textPrimary);
        expect(scheme.error, AppPalette.statusError);
        expect(scheme.outlineVariant, AppPalette.border);
      }
    });

    test('elevation never stains a surface with the brand colour', () {
      // Depth here is the bevel, the rim and the ambient shadow. Material 3
      // would otherwise blend surfaceTint into anything it raises.
      expect(lightTheme.colorScheme.surfaceTint, AppColors.transparentColor);
      expect(darkTheme.colorScheme.surfaceTint, AppColors.transparentColor);
      expect(lightTheme.cardTheme.surfaceTintColor, isTransparent);
      expect(lightTheme.dialogTheme.surfaceTintColor, isTransparent);
      expect(lightTheme.popupMenuTheme.surfaceTintColor, isTransparent);
      expect(lightTheme.bottomSheetTheme.surfaceTintColor, isTransparent);
      expect(lightTheme.datePickerTheme.surfaceTintColor, isTransparent);
      expect(lightTheme.appBarTheme.surfaceTintColor, isTransparent);
    });

    test('the surfaces Material picks for itself are ours', () {
      expect(lightTheme.scaffoldBackgroundColor, AppPalette.surfacePage);
      expect(lightTheme.dialogTheme.backgroundColor, AppPalette.surfaceCard);
      expect(
        lightTheme.bottomSheetTheme.modalBackgroundColor,
        AppPalette.surfaceSunken,
      );
      expect(lightTheme.popupMenuTheme.color, AppPalette.surfaceCard);
      expect(
        lightTheme.datePickerTheme.backgroundColor,
        AppPalette.surfaceCard,
      );
      expect(
        lightTheme.snackBarTheme.backgroundColor,
        AppPalette.surfaceInverse,
      );
    });
  });

  group('glyphs are centralised', () {
    test('no file paints an SVG without going through AppIcon', () {
      // 45 of the SVGs in `assets/icons` ship a baked-in gradient from the
      // previous look, so a bare `SvgPicture` renders last season's brand
      // whatever the palette says. `AppIcon` forces a
      // `ColorFilter.mode(token, BlendMode.srcIn)` over every glyph, and
      // `AppArtwork` is the deliberate opt-out for a pictogram whose own
      // colours are the content.
      final List<String> found = offenders(
        RegExp(r'(?<![A-Za-z0-9_])SvgPicture(?![A-Za-z0-9_])'),
      );
      expect(
        found,
        isEmpty,
        reason:
            'Icons are themed, not pictures: use AppIcon (a glyph the theme '
            'colours) or AppArtwork (a pictogram that keeps its own '
            'palette), both from lib/core/theme/app_icon.dart, at:\n'
            '${found.join('\n')}',
      );
    });
  });

  group('colour literals live in app_theme_config.dart', () {
    test('no file outside the token file declares a colour', () {
      // This started as an allowlist of 58 files and ratcheted to zero.
      // Every colour the app paints — including the feature-scoped ones in
      // app_colors.dart, the categorical chart palettes and the
      // author-chosen newsletter schemes — resolves to an AppPalette role,
      // which is what makes a second skin a single-file change.
      final List<String> found = <String>[
        for (final ({String path, String source}) f in allSources)
          ...() {
            final List<String> lines = stripComments(f.source).split('\n');
            return <String>[
              for (int i = 0; i < lines.length; i++)
                if (RegExp(
                  r'Color\(0x|Color\.fromRGBO|Color\.fromARGB',
                ).hasMatch(lines[i]))
                  '${f.path}:${i + 1}',
            ];
          }(),
      ];
      expect(
        found,
        isEmpty,
        reason:
            'Colours are defined once, in '
            'lib/core/theme/app_theme_config.dart. Add a role to AppPalette '
            '(or a feature token in AppColors that points at one) and '
            'reference it, at:\n${found.join('\n')}',
      );
    });
  });

  group('the brand skin is the flat skeuomorphic one', () {
    test('the page ground is the warm tray, not white', () {
      expect(AppPalette.surfacePage, BrandRamps.tray);
      expect(AppPalette.surfacePage, isNot(BrandRamps.white));
    });

    test('the brand role is pink; teal is domain colour, not chrome', () {
      expect(AppPalette.brand, BrandRamps.pink600);
      expect(AppPalette.brand, AppPalette.actionRecommended);
      expect(AppPalette.actionSecondary, BrandRamps.teal600);
    });

    test('the card face is cool and every input is a well', () {
      expect(AppPalette.surfaceCard, BrandRamps.card);
      expect(AppPalette.surfaceField, BrandRamps.well);
      expect(AppPalette.surfaceSunken, BrandRamps.sub);
    });

    test('pure white is retired: ink on a dark face is warm white', () {
      expect(AppPalette.textOnDark, BrandRamps.warmWhite);
      expect(AppPalette.onBrand, BrandRamps.warmWhite);
    });
  });

  group('MaterialApp is handed both themes and picks one', () {
    test('AppTheme is the entry point, and both themes are the built ones', () {
      expect(AppTheme.light, same(lightTheme));
      expect(AppTheme.dark, same(darkTheme));
    });

    test('the two themes differ only in brightness for now', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.primaryColor, AppTheme.light.primaryColor);
    });

    test('the default mode is light, never system', () {
      // Dark mode still renders the light palette, so following the OS would
      // hand a dark-mode phone a half-built theme.
      expect(ThemeCubit().state, ThemeMode.light);
    });

    test('the mode is switchable, so dark mode needs no rewiring', () {
      final ThemeCubit cubit = ThemeCubit();
      cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
      cubit.setMode(ThemeMode.system);
      expect(cubit.state, ThemeMode.system);
    });
  });
}
