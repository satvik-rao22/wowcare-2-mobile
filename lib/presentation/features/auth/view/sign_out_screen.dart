import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/reusable_log_out_model_sheet.dart';
import 'package:wowcare/core/util/core_utils.dart';

class SignOutScreen extends StatefulWidget {
  const SignOutScreen({super.key});

  static const routeName = '/sign-out';

  // Static method to show as bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LogOutModelBottomSheet(),
    );
  }

  @override
  State<SignOutScreen> createState() => _SignOutScreenState();
}

class _SignOutScreenState extends State<SignOutScreen> {
  bool isLoading = false;

  Future<void> _handleSignOut() async {
    setState(() {
      isLoading = true;
    });

    try {
      await context.read<AuthCubit>().logoutSession();

      if (mounted) {
        context.read<ParentChildCubit>().invalidate();
      }

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet first
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'You are logged out successfully',
          isSuccess: true,
        );

        context.go(SignInScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Logout failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SkeuBottomSheet(
      maxHeightFactor: .5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // A recessed disc holding the illustration: the sheet asks a
          // question, so nothing in it is raised except the two keys.
          Center(
            child: SkeuWell(
              width: 148,
              height: 148,
              radius: SkeuRadius.pill,
              gradient: SkeuSurfaces.pinkSoft,
              insets: SkeuElevation.wellLg,
              padding: const EdgeInsets.all(18),
              // SizedBox.expand so the illustration is bounded by the disc —
              // a well hands its child loose constraints, and an Image would
              // otherwise lay itself out at its full pixel size.
              child: SizedBox.expand(
                child: Image.asset(MediaRes.logout_image, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: SkeuText.title(),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SkeuButton(
                  label: 'Cancel',
                  variant: SkeuButtonVariant.neutral,
                  height: 50,
                  radius: SkeuRadius.md,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SkeuButton(
                  label: 'Sign Out',
                  height: 50,
                  radius: SkeuRadius.md,
                  isLoading: isLoading,
                  onPressed: _handleSignOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
