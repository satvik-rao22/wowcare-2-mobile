/// A specimen sheet: the app's own widgets, rendered on the app's own theme,
/// captured as a golden.
///
/// The point is not regression cover. Text rasterises differently on macOS
/// and on the Linux runner CI uses, so a pixel comparison would fail there
/// for a reason that has nothing to do with the design — the image is only
/// *written*, under `--update-goldens`, and never compared. A plain
/// `flutter test` run still builds the whole sheet, which is what catches a
/// widget that no longer composes.
///
/// The point is that somebody re-skinning the app can **look at** the result
/// without a backend to sign in to. Every widget here is the real one a
/// screen builds, not a mock of it, so what the sheet shows is what the
/// screens show.
///
/// Regenerate after a palette change:
///
/// ```
/// flutter test test/core/theme/material_specimen_test.dart --update-goldens
/// ```
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/shared/common/widgets/common_single_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

/// A labelled row in the sheet.
Widget _row(String label, Widget child) => Padding(
  padding: const EdgeInsets.only(bottom: 18),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: AppPalette.textMuted,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  ),
);

/// A bare decoration, so the recipes can be seen next to the widgets that
/// use them.
Widget _swatch(String label, Decoration decoration, {Color? ink}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Container(
      width: 88,
      height: 48,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ink ?? AppPalette.textPrimary,
        ),
      ),
    ),
  ],
);

/// Loads the real body font, so the sheet is legible rather than a wall of
/// the test harness's placeholder glyphs.
Future<void> _loadBodyFont() async {
  final FontLoader loader = FontLoader(AppFonts.body);
  for (final String weight in <String>[
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
  ]) {
    final File f = File(
      'assets/fonts/${AppFonts.body.toLowerCase()}/'
      '${AppFonts.body}-$weight.ttf',
    );
    if (f.existsSync()) {
      loader.addFont(
        Future<ByteData>.value(
          ByteData.view(Uint8List.fromList(f.readAsBytesSync()).buffer),
        ),
      );
    }
  }
  await loader.load();
}

void main() {
  setUpAll(_loadBodyFont);

  testWidgets('the flat skeuomorphic material, as the app builds it', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1010);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _row(
                  'surfaces',
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _swatch('card', AppSurfaces.card()),
                      _swatch('sub', AppSurfaces.sub()),
                      _swatch('well', AppSurfaces.well()),
                      _swatch(
                        'impact',
                        AppSurfaces.impact(),
                        ink: AppPalette.textOnDark,
                      ),
                      _swatch('tray', AppSurfaces.tray(radius: AppRadius.lg)),
                    ],
                  ),
                ),
                _row(
                  'keys',
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      for (final KeyVariant v in KeyVariant.values)
                        _swatch(
                          v.name,
                          AppSurfaces.key(v),
                          ink: AppSurfaces.keyInk(v),
                        ),
                      _swatch('fab', AppSurfaces.fab()),
                      _swatch('fab off', AppSurfaces.fab(enabled: false)),
                      _swatch('icon key', AppSurfaces.iconKey()),
                    ],
                  ),
                ),
                _row(
                  'pills, by tone',
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      for (final AppTone t in AppTone.values)
                        _swatch(t.name, AppSurfaces.pill(t), ink: t.ink),
                    ],
                  ),
                ),
                _row(
                  'buttons the screens build',
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: CustomCancelButton(
                          cancelButtonLabel: 'Cancel',
                          onPressedCancel: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomConfirmButton(
                          label: 'Save',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                _row(
                  'a text field',
                  const CustomTextField(
                    label: 'Student name',
                    hintText: 'Enter a name',
                  ),
                ),
                _row(
                  'a search bar',
                  CustomSearchBar(
                    controller: TextEditingController(),
                    hintText: 'Search students',
                  ),
                ),
                _row(
                  'a dropdown',
                  CommonSingleSelectDropdown(
                    label: 'Classroom',
                    value: 'Indigo Preschool',
                    items: const <String>['Indigo Preschool'],
                    onSelected: (_) {},
                  ),
                ),
                _row(
                  'a toggle',
                  CustomToggle(
                    label: 'Send a reminder',
                    isToggled: true,
                    onToggle: (_) {},
                  ),
                ),
                _row(
                  'message bubbles',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final (String who, Color face, Color ink)
                          in <(String, Color, Color)>[
                            (
                              'mine',
                              AppColors.messagingBubbleMine,
                              AppPalette.textOnDark,
                            ),
                            (
                              'a guardian, read by staff',
                              AppColors.messagingBubbleGuardian,
                              AppPalette.textOnDark,
                            ),
                            (
                              'anyone else',
                              AppColors.messagingBubbleReceived,
                              AppPalette.textPrimary,
                            ),
                          ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: face,
                              borderRadius: AppRadius.allR18,
                            ),
                            child: Text(
                              who,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 13,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Written, never compared — see the library doc.
    if (autoUpdateGoldenFiles) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/material_specimen.png'),
      );
    }
  });
}
