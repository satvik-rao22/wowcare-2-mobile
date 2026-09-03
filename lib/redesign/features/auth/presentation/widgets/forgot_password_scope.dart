import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/features/auth/cubit/forgot_password_cubit.dart';

/// Holds 1d and 1e together, so the confirmation screen can print the address
/// 1d was given and run the resend clock the send started.
class ForgotPasswordScope extends StatelessWidget {
  const ForgotPasswordScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<ForgotPasswordCubit>(
    create: (_) => redesignLocator<ForgotPasswordCubit>(),
    child: child,
  );
}
