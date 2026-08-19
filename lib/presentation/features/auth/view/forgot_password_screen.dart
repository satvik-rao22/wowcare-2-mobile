import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/auth/usecases/forgot_password_usecase.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();

    // Basic email validation
    if (email.isEmpty || !email.contains('@')) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid email address',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final useCase = serviceLocator<ForgotPasswordUseCase>();

    final result = await useCase(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        final msg = failure.message ?? failure.toString();
        CoreUtils.showTopSnackBar(
          context: context,
          message: msg,
          isError: true,
        );
      },
      (message) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: message,
          isSuccess: true,
          duration: const Duration(seconds: 3),
        );

        // Wait a bit then navigate back
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail =
        _emailController.text.isNotEmpty && _emailController.text.contains('@');

    return SkeuScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SkeuIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Center(
                      child: SkeuBrandLockup(
                        markSize: 78,
                        fontSize: 25,
                        careColor: SkeuColors.ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SkeuPageHeader(
                      title: 'Forgot Password',
                      subtitle:
                          "Enter the email that's associated with your account.",
                    ),
                    const SizedBox(height: 22),
                    SkeuTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Email Address',
                      icon: Icons.mail_outline_rounded,
                      showDivider: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    // A quiet teal-washed panel, not a well: this is something
                    // to read, not something to press or type into.
                    SkeuPanel(
                      radius: 18,
                      gradient: SkeuSurfaces.tealSoft,
                      shadows: const [],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.support_rounded,
                              size: 18,
                              color: SkeuColors.teal700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'We send a reset link that expires in 30 minutes. '
                              'Still stuck? Your center admin can reset it for you.',
                              style: SkeuText.caption(
                                color: SkeuColors.teal900,
                              ).copyWith(height: 1.6),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: SkeuButton(
                label: hasEmail ? 'Submit' : 'Continue',
                radius: 18,
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
