import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/forgot_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/auth_glyph_tile.dart';

/// 1e. The link is out; here is where it went, and what to do if it did not
/// arrive. The resend key stays a dead well until the clock runs out.
///
/// The link at the foot is an addition: the fixtures have no inbox to tap a
/// real link in, so this is how 1f is reached during review.
class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<ForgotPasswordCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: AuthSizes.checkEmailPad,
                  child: Column(
                    spacing: AuthSizes.checkEmailGap,
                    children: <Widget>[
                      AuthGlyphTile(
                        icon: AppIcons.mail,
                        size: AuthSizes.mailTile,
                        glyphSize: AuthSizes.mailGlyph,
                        fill: c.successBg,
                        glyphColor: c.successFg,
                      ),
                      Text(
                        AuthStrings.checkEmail,
                        style: AppTextStyles.moduleTitle.copyWith(color: c.ink),
                      ),
                      Text.rich(
                        TextSpan(
                          text: '${AuthStrings.sentTo}\n',
                          children: <InlineSpan>[
                            TextSpan(
                              text: state.maskedEmail,
                              style: AppTextStyles.alertText.copyWith(
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.alertText.copyWith(color: c.ink2),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AuthSizes.footerPad,
                child: Column(
                  spacing: AuthSizes.resetFooterGap,
                  children: <Widget>[
                    _help(context),
                    if (state.secondsLeft > 0)
                      AppWell(
                        padding: AppSizes.fieldPadLarge,
                        alignment: Alignment.center,
                        child: Text(
                          AuthStrings.resendIn(state.resendClock),
                          style: AppTextStyles.keyLabel.copyWith(color: c.ink3),
                        ),
                      )
                    else
                      SecondaryKey(
                        label: AuthStrings.resend,
                        padding: AppSizes.fieldPadLarge,
                        onTap: cubit.resend,
                      ),
                    TextLink(
                      label: AuthStrings.haveLink,
                      style: AppTextStyles.alertText,
                      onTap: () => context.push(AppRoutes.resetPassword),
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

  Widget _help(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.space2,
        children: <Widget>[
          Text(
            AuthStrings.didntGetIt,
            style: AppTextStyles.alertText.copyWith(color: c.ink),
          ),
          Text(
            AuthStrings.checkSpam,
            style: AppTextStyles.alertText.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }
}
