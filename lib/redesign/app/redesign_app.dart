import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
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
class RedesignApp extends StatefulWidget {
  const RedesignApp({super.key});

  /// The widest the app will follow the system text scale.
  static const double _maxTextScale = 1.3;

  @override
  State<RedesignApp> createState() => _RedesignAppState();
}

class _RedesignAppState extends State<RedesignApp> {
  late final SessionCubit _session;
  late final BadgeCubit _badges;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    registerRedesignDependencies();
    _session = redesignLocator<SessionCubit>();
    // Fixture counts from the design frames until M09 and M12 own them.
    _badges = BadgeCubit(
      initial: const BadgeState(messages: 7, notifications: 7),
    );
    _router = buildAppRouter(_session);
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_badges.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: _session),
        BlocProvider<BadgeCubit>.value(value: _badges),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: AppTheme.light,

        // Light only. D1 is designed but not applied, so there is no dark
        // theme to fall back to and the system setting must not pick one.
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) {
          final scale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(1.0, RedesignApp._maxTextScale);
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
