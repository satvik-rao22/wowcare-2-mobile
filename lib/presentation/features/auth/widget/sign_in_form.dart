import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The email + password pair on the sign-in sheet.
///
/// Both fields are recessed wells with a teal leading glyph — the skeuomorphic
/// cue for "you type into this". The email field shows a green tick once it
/// parses, and the password field carries the reveal eye. Validation, the form
/// key and both controllers stay owned by the sign-in screen.
class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// Fired by the password field's keyboard "done" action.
  final VoidCallback? onSubmit;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool isObscure = true;

  static final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');

  bool get _emailLooksValid =>
      _emailPattern.hasMatch(widget.emailController.text.trim());

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          SkeuTextField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hintText: 'Email Address',
            icon: Icons.mail_outline_rounded,
            autofillHints: const [AutofillHints.username],
            onChanged: (_) => setState(() {}),
            suffix: _emailLooksValid
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: SkeuColors.green500,
                  )
                : null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_emailPattern.hasMatch(value)) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SkeuTextField(
            controller: widget.passwordController,
            obscureText: isObscure,
            hintText: 'Password',
            icon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => widget.onSubmit?.call(),
            suffix: GestureDetector(
              onTap: () => setState(() => isObscure = !isObscure),
              child: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: SkeuColors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
