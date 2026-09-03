import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/radio_card.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/sign_in_cubit.dart';

/// 1b. Step one of two: which of the account's groups is being opened.
///
/// An account with one organization never sees this: the cubit scopes itself
/// and the router goes straight through.
class ChooseOrganizationPage extends StatelessWidget {
  const ChooseOrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<SignInCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocBuilder<SignInCubit, SignInState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(c, state.organizations.length),
              Expanded(
                child: ListView.separated(
                  padding: AuthSizes.scopeListPad,
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.organizations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AuthSizes.scopeListGap),
                  itemBuilder: (context, index) {
                    final org = state.organizations[index];
                    return RadioCard(
                      title: org.name,
                      subtitle: AuthStrings.roleHere(org.roleLabel),
                      selected: state.organization?.id == org.id,
                      onTap: () => cubit.selectOrganization(org),
                    );
                  },
                ),
              ),
              Padding(
                padding: AuthSizes.scopeFooterPad,
                child: PrimaryKey(
                  label: AuthStrings.continueKey,
                  padding: AppSizes.keyPadLarge,
                  onTap: state.organization == null
                      ? null
                      : () => context.push(AppRoutes.chooseSchool),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(Colourway c, int count) => Padding(
    padding: AuthSizes.scopeHeaderPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuthSizes.scopeHeaderGap,
      children: <Widget>[
        SectionEyebrow(label: AuthStrings.stepOf(1, 2), color: c.pink),
        Text(
          AuthStrings.chooseOrganization,
          style: AppTextStyles.moduleTitle.copyWith(color: c.ink),
        ),
        Text(
          AuthStrings.belongsTo(count),
          style: AppTextStyles.body.copyWith(color: c.ink2),
        ),
      ],
    ),
  );
}
