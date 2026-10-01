import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/app/app_bloc_providers.dart';
import 'package:wowcare/app/app_providers.dart';
import 'package:wowcare/app/app_sizer_init.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/utils/app_themes.dart';
import 'package:wowcare/presentation/features/app_update/widgets/app_update_gate.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_navigator.dart';
import 'package:wowcare/shared/common/app/cubits/theme_cubit.dart';
import 'package:wowcare/src/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: rootAppProviders(),
      // The text-scale clamp is the only thing here that reads MediaQuery,
      // and it is kept in its own leaf widget on purpose. MediaQuery changes
      // on every frame of a keyboard animation (viewInsets), and a widget
      // that reads it rebuilds with it. When this read sat in MyApp's own
      // build, every keyboard frame rebuilt MaterialApp.router and the whole
      // app shell under it. Now the clamp rebuilds alone and hands the same
      // _AppShell instance back down, which Flutter skips.
      child: const _TextScaleClamp(child: _AppShell()),
    );
  }
}

/// Snaps the platform text scale to one of five steps, so a user's large-text
/// setting enlarges the app in known increments rather than continuously.
class _TextScaleClamp extends StatelessWidget {
  const _TextScaleClamp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final systemTextScaleFactor = MediaQuery.of(context).textScaler.scale(1);

    double customScaler;
    if (systemTextScaleFactor < 0.85) {
      customScaler = 0.8;
    } else if (systemTextScaleFactor < 1.0) {
      customScaler = 0.9;
    } else if (systemTextScaleFactor < 1.2) {
      customScaler = 1.0;
    } else if (systemTextScaleFactor < 1.5) {
      customScaler = 1.1;
    } else {
      customScaler = 1.2;
    }

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(customScaler)),
      child: child,
    );
  }
}

/// Everything below the text-scale clamp. Const, so the clamp's rebuilds
/// never reach it; only a theme-mode change rebuilds MaterialApp.router.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    // SizerInit initialises Device (sizer package globals) during the
    // BUILD phase so .h / .w / .sp extensions work on the first screen
    // build. Replacing the outer Sizer(LayoutBuilder) wrapper here
    // prevents MaterialApp.router from being inflated inside a nested
    // LayoutBuilder buildScope, which caused a GlobalKey conflict:
    // go_router's navigator elements were created twice (once in each
    // nested buildScope), triggering the "GlobalKey used multiple times"
    // assertion at go_router/src/builder.dart:457.
    return SizerInit(
      child: MultiBlocProvider(
        providers: appBlocProviders(),
        child: NotificationNavigator(
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'WowCare',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: appRouter,
              // A single OrientationBuilder here keeps Device updated on
              // rotation. child (Router) has a stable GlobalObjectKey so
              // Flutter always updates the existing element — no navigator
              // key conflict — unlike the old Sizer that nested Router
              // inside two stacked LayoutBuilder buildScopes.
              builder: (context, child) => OrientationBuilder(
                builder: (context, orientation) {
                  // sizeOf, not of: subscribe to the size only, so a
                  // keyboard frame (viewInsets) does not rebuild this.
                  final Size size = MediaQuery.sizeOf(context);
                  Device.setScreenSize(
                    context,
                    BoxConstraints(
                      maxWidth: size.width,
                      maxHeight: size.height,
                    ),
                    orientation,
                    599,
                  );
                  // ResponsiveScope publishes the screen size class
                  // to every routed screen (M7). Mounted here, inside
                  // MaterialApp's builder, so it wraps the routed
                  // subtree without putting a new buildScope around
                  // MaterialApp.router itself.
                  //
                  // AppUpdateGate lays the required-update overlay over
                  // every route, the kiosk and sign-in included.
                  return ResponsiveScope(
                    child: AppUpdateGate(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
