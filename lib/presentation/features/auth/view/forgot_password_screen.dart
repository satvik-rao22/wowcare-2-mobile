import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/auth/view_model/forgot_password_cubit.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        color: AppColors.cardColor,
        child: SafeArea(
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state is ForgotPasswordFailure) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: state.message,
                  isError: true,
                );
              } else if (state is ForgotPasswordSuccess) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: state.message,
                  isSuccess: true,
                  duration: const Duration(seconds: 3),
                );
                // Wait a bit then navigate back.
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) context.pop();
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is ForgotPasswordLoading;
              return Column(
                children: [
                  // Back button at top
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.authPrimaryTextColor,
                          size: screenHeight * 0.03,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              MediaRes.logo_wow,
                              height: screenHeight * 0.12,
                              width: screenHeight * 0.12,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'WowCare',
                              style: TextStyle(
                                fontSize: screenHeight * 0.03,
                                fontWeight: FontWeight.w500,
                                color: AppColors.themeColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.05),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Forgot Password',
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: screenHeight * 0.022,
                                  height: 2 / 6,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.authPrimaryTextColor,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Enter the email that's associated with your account.",
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: screenHeight * 0.016,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.authPrimaryTextColor,
                                  height: 22 / 12,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: AppColors.authDividerColor,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                                hintStyle: TextStyle(
                                  color: AppColors.authPrimaryTextColor,
                                  fontFamily: AppFonts.body,
                                  fontSize: screenHeight * 0.022,
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.04,
                                    right: screenWidth * 0.02,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        color: AppColors.authPrimaryTextColor,
                                        size: screenHeight * 0.025,
                                      ),
                                      Container(
                                        height: screenHeight * 0.06,
                                        width: 2,
                                        color: AppColors.cardColor,
                                        margin: EdgeInsets.only(
                                          left: screenWidth * 0.04,
                                          right: screenWidth * 0.015,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                filled: true,
                                fillColor: AppSurfaces.fieldFill,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                focusedBorder: AppSurfaces.fieldBorder(
                                  radius: 12,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.018,
                                  horizontal: screenWidth * 0.04,
                                ),
                              ),
                              // Solid color (a gradient `foreground` shader breaks
                              // tap-to-position-cursor on editable fields).
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: screenHeight * 0.022,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () => context.read<ForgotPasswordCubit>().submit(
                                _emailController.text,
                              ),
                        child: SkeuKeyBox(
                          variant: KeyVariant.primary,
                          radius: 12,
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.cardColor,
                                      ),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _emailController,
                                    builder: (context, value, _) => Text(
                                      value.text.contains('@') &&
                                              value.text.isNotEmpty
                                          ? 'Submit'
                                          : 'Continue',
                                      style: TextStyle(
                                        color: AppColors.cardColor,
                                        fontSize: screenHeight * 0.022,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppFonts.body,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
