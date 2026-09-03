import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/reset_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/password_rules_card.dart';

/// 1f. Two entries and three rules, behind the link from the email.
///
/// Saving lands back on 1a rather than straight into the app: the reset link
/// proves the address, not the session.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<ResetPasswordCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.isSaved) {
              showAppToast(context, AuthStrings.passwordChanged);
              context.go(AppRoutes.signIn);
            } else if (state.isFailed) {
              showAppToast(
                context,
                AuthStrings.passwordChangeFailed,
                tone: ToastTone.error,
              );
            }
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppHeaderBar(
                title: AuthStrings.newPassword,
                leading: BackKey(),
                isDetail: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AuthSizes.formPad,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    spacing: AuthSizes.formGap,
                    children: <Widget>[
                      AppTextField(
                        hintText: AuthStrings.newPasswordHint,
                        leadingIcon: AppIcons.lock,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        padding: AppSizes.fieldPadLarge,
                        onChanged: cubit.passwordChanged,
                      ),
                      AppTextField(
                        hintText: AuthStrings.confirmPasswordHint,
                        leadingIcon: AppIcons.lock,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        padding: AppSizes.fieldPadLarge,
                        onChanged: cubit.confirmationChanged,
                        onSubmitted: (_) => cubit.save(),
                      ),
                      PasswordRulesCard(
                        rules: state.rules,
                        strength: state.strength,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AuthSizes.resetFooterPad,
                child: PrimaryKey(
                  label: AuthStrings.saveAndSignIn,
                  isLoading: state.isSaving,
                  padding: AppSizes.keyPadLarge,
                  onTap: state.isValid ? cubit.save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
