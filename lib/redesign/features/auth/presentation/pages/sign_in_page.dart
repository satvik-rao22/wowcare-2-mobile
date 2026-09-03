import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/sign_in_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/auth_hero.dart';

/// 1a. Sign in, in four states: resting, signing in, rejected, offline.
///
/// There is no sign-up key and never will be: accounts are created on the web
/// by the school administrator, which is what the note under the key says.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    final state = context.read<SignInCubit>().state;
    _email = TextEditingController(text: state.email);
    _password = TextEditingController(text: state.password);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocBuilder<SignInCubit, SignInState>(
          builder: (context, state) => Column(
            children: <Widget>[
              if (state.isOffline)
                const Padding(
                  padding: AuthSizes.bannerMargin,
                  child: OfflineBanner(),
                ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: AuthSizes.heroTopPad),
                  child: AuthHero(
                    title: AuthStrings.welcomeBack,
                    subtitle: AuthStrings.signInSubtitle,
                  ),
                ),
              ),
              _form(state),
              _footer(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(SignInState state) {
    final cubit = context.read<SignInCubit>();

    return Padding(
      padding: AuthSizes.formPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AuthSizes.formGap,
        children: <Widget>[
          if (state.isRejected) const InlineAlert(message: AuthStrings.rejected),
          AppTextField(
            controller: _email,
            hintText: AuthStrings.emailHint,
            leadingIcon: AppIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            padding: AppSizes.fieldPadLarge,
            hasError: state.isRejected,
            onChanged: cubit.emailChanged,
          ),
          AppTextField(
            controller: _password,
            hintText: AuthStrings.passwordHint,
            leadingIcon: AppIcons.lock,
            obscureText: true,
            textInputAction: TextInputAction.done,
            padding: AppSizes.fieldPadLarge,
            hasError: state.isRejected,
            onChanged: cubit.passwordChanged,
            onSubmitted: (_) => cubit.submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextLink(
              label: AuthStrings.forgotPassword,
              style: AppTextStyles.alertText,
              onTap: () => context.push(AppRoutes.forgotPassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(SignInState state) {
    final c = context.colours;
    final cubit = context.read<SignInCubit>();

    return Padding(
      padding: AuthSizes.footerPad,
      child: Column(
        spacing: AuthSizes.footerGap,
        children: <Widget>[
          PrimaryKey(
            label: state.isSubmitting
                ? AuthStrings.signingIn
                : AuthStrings.signInKey,
            isLoading: state.isSubmitting,
            onTap: state.canSubmit ? cubit.submit : null,
            padding: AppSizes.keyPadLarge,
          ),
          Text(
            '${AuthStrings.accountsNote}\n${AuthStrings.needAccess}',
            textAlign: TextAlign.center,
            style: AppTextStyles.subLine.copyWith(color: c.ink3),
          ),
        ],
      ),
    );
  }
}
