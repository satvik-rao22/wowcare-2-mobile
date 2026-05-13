import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/widgets/reusable_log_out_model_sheet.dart';
import 'package:wowcare/shared/common/widgets/rounded_button.dart';
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
        context.read<ParentChildProvider>().invalidate();
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
    return FractionallySizedBox(
      heightFactor: 0.42, // take ~42% of screen height
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 160,
              child: Image.asset(
                MediaRes.logout_image,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.themeColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: RoundedButton(
                            lable: 'Cancel',
                            lableColor: Colors.white,
                            buttonColor: Colors.grey,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RoundedButton(
                            lable: 'Sign Out',
                            lableColor: AppColors.cardColor,
                            buttonColor: AppColors.themeColor,
                            onPressed: _handleSignOut,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
