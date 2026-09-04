import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/app/app_bloc_providers.dart';
import 'package:wowcare/app/app_providers.dart';
import 'package:wowcare/app/app_sizer_init.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_navigator.dart';
import 'package:wowcare/shared/common/app/cubit/theme_cubit.dart';
import 'package:wowcare/src/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: rootAppProviders(),
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, currentTheme) {
          final systemTextScaleFactor = MediaQuery.of(
            context,
          ).textScaler.scale(1);

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
            // SizerInit initialises Device (sizer package globals) during the
            // BUILD phase so .h / .w / .sp extensions work on the first screen
            // build. Replacing the outer Sizer(LayoutBuilder) wrapper here
            // prevents MaterialApp.router from being inflated inside a nested
            // LayoutBuilder buildScope, which caused a GlobalKey conflict:
            // go_router's navigator elements were created twice (once in each
            // nested buildScope), triggering the "GlobalKey used multiple times"
            // assertion at go_router/src/builder.dart:457.
            child: SizerInit(
              child: MultiBlocProvider(
                providers: appBlocProviders(),
                child: NotificationNavigator(
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'WowCare',
                    theme: currentTheme,
                    routerConfig: appRouter,
                    // A single OrientationBuilder here keeps Device updated on
                    // rotation. child (Router) has a stable GlobalObjectKey so
                    // Flutter always updates the existing element — no navigator
                    // key conflict — unlike the old Sizer that nested Router
                    // inside two stacked LayoutBuilder buildScopes.
                    builder: (context, child) => OrientationBuilder(
                      builder: (context, orientation) {
                        final mq = MediaQuery.of(context);
                        Device.setScreenSize(
                          context,
                          BoxConstraints(
                            maxWidth: mq.size.width,
                            maxHeight: mq.size.height,
                          ),
                          orientation,
                          599,
                        );
                        return ResponsiveScope(
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
