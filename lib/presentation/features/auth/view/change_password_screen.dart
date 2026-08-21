import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = '/change-password';

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => const ChangePasswordScreen(),
    );
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordRequirements);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordRequirements() {
    final password = _newPasswordController.text;
    setState(() {
      _isPasswordValid =
          password.length >= 8 &&
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  Future<void> _handleSubmit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter your current password',
        isError: true,
      );
      return;
    }

    if (newPassword.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a new password',
        isError: true,
      );
      return;
    }

    if (!_isPasswordValid) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Password must contain at least 8 characters and one special character',
        isError: true,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'New password and confirm password do not match',
        isError: true,
      );
      return;
    }

    if (currentPassword == newPassword) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'New password must be different from current password',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement change password API call here
    // For now, simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // TODO: Replace with actual API response handling
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Password changed successfully',
      isSuccess: true,
      duration: const Duration(seconds: 3),
    );

    // Wait a bit then navigate back
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;
    final maxHeight = screenHeight * 0.9;

    final content = Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    color: AppColors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
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
                            fontFamily: 'Manrope',
                            fontSize: screenHeight * 0.022,
                            height: 2 / 6,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(height: screenHeight * 0.01),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFFFF3E9),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Current Password
                      Text(
                        'Current Password',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        isVisible: _isCurrentPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isCurrentPasswordVisible =
                                !_isCurrentPasswordVisible;
                          });
                        },
                        hintText: 'Enter old password',
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // New Password
                      Text(
                        'New Password',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        isVisible: _isNewPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                        hintText: 'Enter new password',
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Confirm New Password
                      Text(
                        'Confirm New Password',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        isVisible: _isConfirmPasswordVisible,
                        onVisibilityToggle: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        hintText: 'Repeat new password',
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Password Requirements
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isPasswordValid
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: AppColors.green,
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
                                color: const Color(0xFFEFFBEF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Password must contain at least 8 characters, one special character',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.015,
                                  color: AppColors.green,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: 12,
                            ),
                          ),
                        ],
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
                  onTap: _isLoading ? null : _handleSubmit,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: AppColors.buildPrimaryGradient(),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Password',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: screenHeight * 0.022,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Manrope',
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: content,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String hintText,
    required double screenHeight,
    required double screenWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFFBBBBBB),
            fontFamily: 'Manrope',
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
                  color: const Color(0xFF333333),
                  size: screenHeight * 0.025,
                ),
                Container(
                  height: screenHeight * 0.06,
                  width: 2,
                  color: AppColors.white,
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
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF888888),
              size: screenHeight * 0.025,
            ),
            onPressed: onVisibilityToggle,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
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
          fontFamily: 'Manrope',
          fontSize: screenHeight * 0.022,
          color: AppColors.primaryColor,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }
}
