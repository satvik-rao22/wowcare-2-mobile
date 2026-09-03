import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/sign_in_cubit.dart';

/// Holds the sign-in lane together.
///
/// 1a, 1b and 1c are one decision taken in three steps, so the cubit is
/// provided above all three rather than in each page: a back gesture from the
/// school picker returns to a still-answered organization picker.
///
/// This is also the one place the lane navigates. Credentials accepted opens
/// the organization step; the moment the scope is settled it hands the
/// re-scoped account to the [SessionCubit], and the router's own redirect
/// takes it from there. Keeping both here means no page has to know what the
/// step after it is.
class SignInScope extends StatelessWidget {
  const SignInScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<SignInCubit>(
    create: (_) => redesignLocator<SignInCubit>(),
    child: BlocListener<SignInCubit, SignInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case SignInStatus.signedIn:
            unawaited(context.push(AppRoutes.chooseOrganization));
          case SignInStatus.scoped:
            final user = state.user;
            if (user != null) context.read<SessionCubit>().signedIn(user);
          case SignInStatus.editing:
          case SignInStatus.submitting:
          case SignInStatus.rejected:
          case SignInStatus.offline:
            break;
        }
      },
      child: child,
    ),
  );
}
