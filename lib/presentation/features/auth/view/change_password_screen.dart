import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/core/util/core_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = '/change-password';

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    return SkeuBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const SkeuPageHeader(title: 'Change Password'),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPasswordField(
                    label: 'Current Password',
                    controller: _currentPasswordController,
                    isVisible: _isCurrentPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    }),
                    hintText: 'Enter old password',
                  ),
                  const SizedBox(height: 18),
                  _buildPasswordField(
                    label: 'New Password',
                    controller: _newPasswordController,
                    isVisible: _isNewPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    }),
                    hintText: 'Enter new password',
                  ),
                  const SizedBox(height: 18),
                  _buildPasswordField(
                    label: 'Confirm New Password',
                    controller: _confirmPasswordController,
                    isVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () => setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }),
                    hintText: 'Repeat new password',
                  ),
                  const SizedBox(height: 18),
                  // The rule, and whether the new password satisfies it yet.
                  // Green once met, neutral until then — never pink, which is
                  // reserved for the recommended action.
                  SkeuPanel(
                    radius: 14,
                    gradient: _isPasswordValid
                        ? SkeuSurfaces.greenSoft
                        : SkeuSurfaces.sunken,
                    shadows: const [],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isPasswordValid
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 18,
                          color: _isPasswordValid
                              ? SkeuColors.green700
                              : SkeuColors.inkSoft,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password must contain at least 8 characters and '
                            'one special character.',
                            style: SkeuText.caption(
                              color: _isPasswordValid
                                  ? SkeuColors.green700
                                  : SkeuColors.inkSoft,
                            ).copyWith(height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SkeuButton(
            label: 'Save Password',
            radius: 18,
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    required String hintText,
  }) {
    return SkeuTextField(
      label: label,
      controller: controller,
      obscureText: !isVisible,
      hintText: hintText,
      icon: Icons.lock_outline_rounded,
      showDivider: true,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      onChanged: (_) => setState(() {}),
      suffix: GestureDetector(
        onTap: onVisibilityToggle,
        child: Icon(
          isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: SkeuColors.inkFaint,
        ),
      ),
    );
  }
}
