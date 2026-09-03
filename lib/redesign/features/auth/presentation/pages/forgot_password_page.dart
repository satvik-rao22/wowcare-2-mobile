import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/forgot_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/auth_glyph_tile.dart';

/// 1d. The address to send the link to.
///
/// The only check made here is that the address looks like one; whether it
/// belongs to an account is the server's answer, and a failure to send is the
/// one failure this screen draws.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<ForgotPasswordCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            switch (state.status) {
              case ForgotPasswordStatus.sent:
                unawaited(context.push(AppRoutes.checkEmail));
              case ForgotPasswordStatus.failed:
                showAppToast(
                  context,
                  AuthStrings.resetLinkFailed,
                  tone: ToastTone.error,
                );
              case ForgotPasswordStatus.editing:
              case ForgotPasswordStatus.invalid:
              case ForgotPasswordStatus.sending:
                break;
            }
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppHeaderBar(
                title: AuthStrings.resetPassword,
                leading: BackKey(),
                isDetail: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AuthSizes.resetBodyPad,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AuthSizes.resetBodyGap,
                    children: <Widget>[
                      AuthGlyphTile(
                        icon: AppIcons.lock,
                        size: AuthSizes.lockTile,
                        glyphSize: AuthSizes.lockGlyph,
                        fill: c.studentBg,
                        glyphColor: c.student,
                      ),
                      Text(
                        AuthStrings.resetIntro,
                        style: AppTextStyles.alertText.copyWith(color: c.ink2),
                      ),
                      AppTextField(
                        hintText: AuthStrings.emailHint,
                        leadingIcon: AppIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        padding: AppSizes.fieldPadLarge,
                        errorText: state.status == ForgotPasswordStatus.invalid
                            ? AuthStrings.enterValidEmail
                            : null,
                        onChanged: cubit.emailChanged,
                        onSubmitted: (_) => cubit.send(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AuthSizes.resetFooterPad,
                child: Column(
                  spacing: AuthSizes.resetFooterGap,
                  children: <Widget>[
                    PrimaryKey(
                      label: AuthStrings.sendResetLink,
                      isLoading: state.isSending,
                      padding: AppSizes.keyPadLarge,
                      onTap: cubit.send,
                    ),
                    SecondaryKey(
                      label: AuthStrings.backToSignIn,
                      padding: AppSizes.fieldPadLarge,
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
