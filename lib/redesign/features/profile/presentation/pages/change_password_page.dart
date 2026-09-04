import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/profile/cubit/change_password_cubit.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// Change Password, opened from the actions card on 13a and 13c.
///
/// A full screen rather than 13d's sheet: the sheet on the Account page only
/// asks whether to send a reset link, and this is the form that actually
/// changes the password from inside the app.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.user?.id ?? '';

    return BlocProvider<ChangePasswordCubit>(
      create: (_) => redesignLocator<ChangePasswordCubit>(param1: userId),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatelessWidget {
  const _ChangePasswordView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listenWhen: (previous, current) =>
            previous.isSaved != current.isSaved ||
            previous.hasSaveFailed != current.hasSaveFailed,
        listener: (context, state) {
          if (state.isSaved) {
            showAppToast(context, ProfileStrings.passwordChanged);
            Navigator.of(context).pop();
          } else if (state.hasSaveFailed) {
            showAppToast(
              context,
              ProfileStrings.changePasswordFailed,
              tone: ToastTone.error,
            );
            context.read<ChangePasswordCubit>().clearFailure();
          }
        },
        builder: (context, state) => ScreenScaffold(
          header: const AppHeaderBar(
            title: ProfileStrings.changePassword,
            isDetail: true,
            leading: BackKey(),
          ),
          bodyPadding: EdgeInsets.zero,
          bottomBar: _Footer(state: state),
          body: _Form(state: state),
        ),
      );
}

/// The three wells, and the rule under the new one.
class _Form extends StatelessWidget {
  const _Form({required this.state});

  final ChangePasswordState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChangePasswordCubit>();
    final form = state.form;
    final errors = state.errors;

    return ListView(
      padding: ProfileSizes.formPad,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ProfileSizes.passwordFormGap,
          children: <Widget>[
            AppTextField(
              label: ProfileStrings.currentPassword,
              isRequired: true,
              obscureText: true,
              errorText: errors.current,
              onChanged: (v) => cubit.edit(form.copyWith(current: v)),
            ),
            AppTextField(
              label: ProfileStrings.newPassword,
              isRequired: true,
              obscureText: true,
              helpText: ProfileStrings.passwordRules,
              errorText: errors.next,
              onChanged: (v) => cubit.edit(form.copyWith(next: v)),
            ),
            AppTextField(
              label: ProfileStrings.confirmPassword,
              isRequired: true,
              obscureText: true,
              errorText: errors.confirm,
              onChanged: (v) => cubit.edit(form.copyWith(confirm: v)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cancel, and the one pink key.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final ChangePasswordState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChangePasswordCubit>();

    return DockedBar(
      child: Row(
        spacing: ProfileSizes.footerGap,
        children: <Widget>[
          Expanded(
            flex: ProfileSizes.cancelFlex,
            child: SecondaryKey(
              label: AppStrings.cancel,
              padding: ProfileSizes.footerKeyPad,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            flex: ProfileSizes.saveFlex,
            child: PrimaryKey(
              label: ProfileStrings.changePassword,
              enabled: state.canSubmit,
              isLoading: state.isSaving,
              padding: ProfileSizes.footerKeyPad,
              onTap: () => unawaited(cubit.submit()),
            ),
          ),
        ],
      ),
    );
  }
}
