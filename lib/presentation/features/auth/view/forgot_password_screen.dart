import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
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
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        color: AppColors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Back button at top
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF333333),
                      size: screenHeight * 0.03,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return AppColors.buildPrimaryGradient()
                                .createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'WowCare',
                            style: TextStyle(
                              fontSize: screenHeight * 0.03,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Forgot Password',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: screenHeight * 0.022,
                              height: 2 / 6,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Enter the email that's associated with your account.",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: screenHeight * 0.016,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF333333),
                              height: 22 / 12,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: const Color(0xFFFFF3E9),
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
                              color: const Color(0xFF333333),
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
                                    Icons.email_outlined,
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
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.themeColor,
                              ),
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
                                _emailController.text.contains('@') &&
                                        _emailController.text.isNotEmpty
                                    ? 'Submit'
                                    : 'Continue',
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
      ),
    );
  }
}
