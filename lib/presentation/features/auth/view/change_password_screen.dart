import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/validators/app_validators.dart';
import 'package:wowcare/presentation/features/auth/view_model/change_password_cubit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = '/change-password';

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (context) => BlocProvider(
        create: (_) => serviceLocator<ChangePasswordCubit>(),
        child: const ChangePasswordScreen(),
      ),
    );
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ValueNotifier<bool> _isCurrentPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isNewPasswordVisible = ValueNotifier(false);
  final ValueNotifier<bool> _isConfirmPasswordVisible = ValueNotifier(false);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isCurrentPasswordVisible.dispose();
    _isNewPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    context.read<ChangePasswordCubit>().submit(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;
    final maxHeight = screenHeight * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listener: (context, state) {
          if (state is ChangePasswordFailure) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message,
              isError: true,
            );
          } else if (state is ChangePasswordSuccess) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message,
              isSuccess: true,
              duration: const Duration(seconds: 3),
            );
            // Wait a bit then close the sheet.
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) Navigator.of(context).pop();
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is ChangePasswordLoading;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.04),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.authDragHandleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: screenHeight * 0.02),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Change Password',
                                style: TextStyle(
                                  fontFamily: Fonts.manrope,
                                  fontSize: screenHeight * 0.022,
                                  height: 2 / 6,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.authPrimaryTextColor,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: AppColors.authDividerColor,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Current Password
                            Text(
                              'Current Password',
                              style: TextStyle(
                                fontFamily: Fonts.manrope,
                                fontSize: screenHeight * 0.016,
                                fontWeight: FontWeight.w400,
                                color: AppColors.authFieldLabelColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _PasswordField(
                              controller: _currentPasswordController,
                              isVisible: _isCurrentPasswordVisible,
                              hintText: 'Enter old password',
                              screenHeight: screenHeight,
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // New Password
                            Text(
                              'New Password',
                              style: TextStyle(
                                fontFamily: Fonts.manrope,
                                fontSize: screenHeight * 0.016,
                                fontWeight: FontWeight.w400,
                                color: AppColors.authFieldLabelColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _PasswordField(
                              controller: _newPasswordController,
                              isVisible: _isNewPasswordVisible,
                              hintText: 'Enter new password',
                              screenHeight: screenHeight,
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Confirm New Password
                            Text(
                              'Confirm New Password',
                              style: TextStyle(
                                fontFamily: Fonts.manrope,
                                fontSize: screenHeight * 0.016,
                                fontWeight: FontWeight.w400,
                                color: AppColors.authFieldLabelColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _PasswordField(
                              controller: _confirmPasswordController,
                              isVisible: _isConfirmPasswordVisible,
                              hintText: 'Repeat new password',
                              screenHeight: screenHeight,
                              screenWidth: screenWidth,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Password Requirements — derived from
                            // [_newPasswordController] reactively, no
                            // setState needed.
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _newPasswordController,
                              builder: (context, value, _) {
                                final isValid = AppValidators.isStrongPassword(
                                  value.text,
                                );
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isValid
                                          ? Icons.check_circle
                                          : Icons.info_outline,
                                      color: AppColors.authSuccessColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.authSuccessBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Password must contain at least 8 characters, one special character',
                                          style: TextStyle(
                                            fontSize: screenHeight * 0.015,
                                            color: AppColors.authSuccessColor,
                                            fontFamily: Fonts.manrope,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isValid)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppColors.authSuccessColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: AppColors.cardColor,
                                          size: 12,
                                        ),
                                      ),
                                  ],
                                );
                              },
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
                        onTap: isLoading ? null : _handleSubmit,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: AppColors.buildPrimaryGradient(),
                          ),
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
                                : Text(
                                    'Save Password',
                                    style: TextStyle(
                                      color: AppColors.cardColor,
                                      fontSize: screenHeight * 0.022,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: Fonts.manrope,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isVisible,
    required this.hintText,
    required this.screenHeight,
    required this.screenWidth,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> isVisible;
  final String hintText;
  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.authSurfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.authInputBorderColor),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isVisible,
        builder: (context, visible, _) => TextField(
          controller: controller,
          obscureText: !visible,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.authHintTextColor,
              fontFamily: Fonts.manrope,
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
                    Icons.lock_outline,
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
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.authFieldLabelColor,
                size: screenHeight * 0.025,
              ),
              onPressed: () => isVisible.value = !isVisible.value,
            ),
            filled: true,
            fillColor: AppColors.authSurfaceLight,
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.themeColor),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.018,
              horizontal: screenWidth * 0.04,
            ),
          ),
          // Solid color (a gradient `foreground` shader breaks
          // tap-to-position-cursor on editable fields).
          style: TextStyle(
            fontFamily: Fonts.manrope,
            fontSize: screenHeight * 0.022,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
