import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/text_field.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            prefixIcon: const Icon(
              IconlyBroken.message,
              color: AppColors.primaryColor,
            ),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'Email Address',
            useGradientBorder: true,
            usePrimaryGradientText: true,
            textFontSize: 16,
            textFontWeight: FontWeight.w400,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _PasswordField(passwordController: passwordController),
        ],
      ),
    );
  }
}

/// Isolated so the "show/hide password" toggle rebuilds only this field —
/// not the whole form — and the outer [SignInForm] can stay a
/// [StatelessWidget] (Mandate 2: UI-local state that's never read outside
/// its owner belongs in a [ValueNotifier], not `setState`).
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.passwordController});

  final TextEditingController passwordController;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  final _isObscure = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _isObscure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isObscure,
      builder: (context, isObscure, _) => CustomTextField(
        prefixIcon: const Icon(
          IconlyBroken.lock,
          color: AppColors.primaryColor,
        ),
        controller: widget.passwordController,
        isPassword: isObscure,
        hintText: 'Password',
        useGradientBorder: true,
        usePrimaryGradientText: true,
        textFontSize: 16,
        textFontWeight: FontWeight.w400,
        suffixIcon: IconButton(
          color: AppColors.blackColor,
          onPressed: () => _isObscure.value = !isObscure,
          icon: Icon(
            isObscure ? IconlyBroken.hide : IconlyBroken.show,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
