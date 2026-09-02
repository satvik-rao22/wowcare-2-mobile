import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/preview/token_gallery_page.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';

/// The redesign's root.
///
/// Deliberately not wrapped in `Sizer`. The design is drawn in fixed logical
/// pixels on a 410pt frame and the token layer is sized to match, so nothing
/// here reads `.h` / `.w` / `.sp`. That also sidesteps the `GlobalKey used
/// multiple times` assertion the existing app hit when `MaterialApp.router`
/// was inflated inside `Sizer`'s nested `LayoutBuilder` buildScope.
///
/// Text scaling is clamped rather than ignored: the design's type ladder goes
/// down to 9.9pt on a nav label, and an unclamped 2x system scale breaks every
/// fixed-height row in the app. The clamp lets accessibility scaling work up to
/// the point where the layout can still carry it.
class RedesignApp extends StatelessWidget {
  const RedesignApp({super.key});

  /// The widest the app will follow the system text scale.
  static const double _maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,

      // Light only. D1 is designed but not applied, so there is no dark theme
      // to fall back to and the system setting must not be able to pick one.
      themeMode: ThemeMode.light,

      // TODO(redesign): replace with MaterialApp.router in phase 2.
      home: const TokenGalleryPage(),

      builder: (context, child) {
        final scale = MediaQuery.textScalerOf(
          context,
        ).scale(1).clamp(1.0, _maxTextScale);
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
