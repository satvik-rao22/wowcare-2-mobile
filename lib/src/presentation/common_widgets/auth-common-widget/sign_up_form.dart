import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../core/common/widgets/text_field.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.fullNameController,
    required this.formKey,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController fullNameController;

  final GlobalKey<FormState> formKey;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool isObscure1 = true;
  bool isObscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Email Address',
              suffixIcon: const Icon(Icons.email, color: Colors.black),
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
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField(
              controller: widget.fullNameController,
              keyboardType: TextInputType.text,
              hintText: 'Full Name',
              suffixIcon: const Icon(Icons.text_fields, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField(
              controller: widget.passwordController,
              isPassword: isObscure1,
              hintText: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 4) {
                  return 'Password must be at least 4 characters long';
                }
                if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
                  return 'Password must contain at least one uppercase letter';
                }
                if (!RegExp(r'^(?=.*[0-9])').hasMatch(value)) {
                  return 'Password must contain at least one digit';
                }
                if (!RegExp(r'^(?=.*?[!@#\$&*~])').hasMatch(value)) {
                  return 'Password must contain at least one special character';
                }
                return null;
              },
              fillColor: Colors.grey[100],
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    isObscure1 = !isObscure1;
                  });
                },
                icon: Icon(isObscure1 ? IconlyBold.hide : IconlyBold.show),
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField(
              controller: widget.confirmPasswordController,
              isPassword: isObscure2,
              hintText: 'Confirm Password',
              validator: (value) {
                if (value != widget.passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              fillColor: Colors.grey[100],
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    isObscure2 = !isObscure2;
                  });
                },
                icon: Icon(isObscure2 ? IconlyBold.hide : IconlyBold.show),
                color: Colors.black,
              ),
            ),
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     // Validate the form
          //     if (widget.formKey.currentState?.validate() ?? false) {
          //       // If the form is valid, perform sign-in or proceed
          //       CoreUtils.showSnackBar(context, 'processing Data',
          //           backgroundColor: AppColors.accentColor);
          //     } else {
          //       // If the form is invalid, show error
          //       CoreUtils.showSnackBar(context, "Invalid Credentials",
          //           backgroundColor: AppColors.errorColor);
          //     }
          //   },
          //   child: const Text('Sign In'),
          // ),
        ],
      ),
    );
  }
}
