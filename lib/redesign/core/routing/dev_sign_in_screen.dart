import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';

/// A stand-in for M01 while it is being built: three keys that sign the
/// preview account in as each persona, so the shell can be exercised.
/// Deleted when the real Sign In lands.
class DevSignInScreen extends StatelessWidget {
  const DevSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final session = context.read<SessionCubit>();
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenGutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preview sign in',
                textAlign: TextAlign.center,
                style: AppTextStyles.moduleTitle.copyWith(color: c.ink),
              ),
              const SizedBox(height: AppSizes.space6),
              PrimaryKey(
                label: 'Admin · ${DemoData.admin.fullName}',
                onTap: () => session.signedIn(DemoData.admin),
              ),
              const SizedBox(height: AppSizes.space3),
              SecondaryKey(
                label: 'Staff · ${DemoData.staff.fullName}',
                onTap: () => session.signedIn(DemoData.staff),
              ),
              const SizedBox(height: AppSizes.space3),
              SecondaryKey(
                label: 'Guardian · ${DemoData.guardian.fullName}',
                onTap: () => session.signedIn(DemoData.guardian),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
