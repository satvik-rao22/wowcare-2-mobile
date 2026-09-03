import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/sign_in_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/school_row.dart';

/// 1c. Step two of two: which school inside the group.
///
/// The school the account last worked in is drawn first and wears the student
/// tint. A school still waiting on approval is drawn dimmed rather than
/// hidden, so it is clear it exists and why it will not open.
class ChooseSchoolPage extends StatelessWidget {
  const ChooseSchoolPage({super.key});

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
              AppHeaderBar.dashboard(
                title: AuthStrings.chooseSchool,
                subline: state.organization?.name ?? '',
                leading: const BackKey(),
              ),
              Padding(
                padding: AuthSizes.searchPad,
                child: SearchField(
                  hintText: AuthStrings.searchSchools,
                  onChanged: cubit.searchSchools,
                ),
              ),
              Expanded(child: _list(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(SignInState state) {
    if (state.schools.isEmpty) {
      return const Padding(
        padding: AppSizes.bodyPad,
        child: Center(
          child: EmptyState(
            icon: AppIcons.school,
            title: AuthStrings.noSchoolsFound,
          ),
        ),
      );
    }

    return Builder(
      builder: (context) => ListView.separated(
        padding: AuthSizes.scopeListPad,
        physics: const BouncingScrollPhysics(),
        itemCount: state.schools.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AuthSizes.schoolListGap),
        itemBuilder: (context, index) {
          final school = state.schools[index];
          return SchoolRow(
            school: school,
            onTap: () => context.read<SignInCubit>().selectSchool(school),
          );
        },
      ),
    );
  }
}
