import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/text_field.dart';

class SignInForm extends StatefulWidget {
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
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          CustomTextField(
            prefixIcon: const Icon(
              IconlyBroken.message,
              color: AppColors.primaryColor,
            ),
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'Email Address',
            useGradientBorder: true,
            usePrimaryGradientText: true,
            textFontSize: 16,
            textFontWeight: FontWeight.w400,
            suffixIcon: const Icon(
              IconlyBroken.message,
              color: AppColors.primaryColor,
            ),
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
          CustomTextField(
            prefixIcon: const Icon(
              IconlyBroken.show,
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
              color: Colors.black,
              onPressed: () => setState(() {
                isObscure = !isObscure;
              }),
              icon: Icon(
                isObscure ? IconlyBroken.hide : IconlyBroken.show,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
