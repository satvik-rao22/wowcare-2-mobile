import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/widget/sign_in_form.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const routeName = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool isLoading = false;

  late final AnimationController _bottomMenuHeightAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _bottomMenuHeightUpAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _bottomMenuHeightAnimationController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    _bottomMenuHeightAnimationController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', emailController.text.trim());
      await prefs.setString('password', passwordController.text.trim());
      // await prefs.setString('accessToken', accessToken);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('accessToken');
    }
    await prefs.setBool('rememberMe', rememberMe);
  }

  Future<void> _handleSignIn() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      await _saveCredentials();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OrganizationSelectionScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _bottomMenuHeightAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
        ),
        child: Stack(
          children: [
            _buildLottieAnimation(),
            _buildBottomMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top +
              MediaQuery.of(context).size.height * 0.01,
        ),
        height: MediaQuery.of(context).size.height * 0.4,
        child: Lottie.asset(MediaRes.signInLottie),
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _bottomMenuHeightAnimationController,
        builder: (context, child) {
          final height = MediaQuery.of(context).size.height *
              0.5 *
              _bottomMenuHeightUpAnimation.value;
          return Container(
            width: MediaQuery.of(context).size.width,
            height: height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    '  Login with email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    formKey: formKey,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          rememberMe = !rememberMe;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 2),
                          CustomCheckbox(
                            value: rememberMe,
                            onChanged: (bool? clicked) {
                              setState(() {
                                rememberMe = clicked ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: AppColors.themeColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) =>
                        ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: isLoading
                        ? Center(
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.buildPrimaryGradient(),
                                shape: BoxShape.circle,
                              ),
                              child: const RefreshProgressIndicator(
                                color: Colors.white,
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : RoundedButtonNew(
                            label: 'Sign-In',
                            isLoading: isLoading,
                            onPressed: _handleSignIn,
                            gradient: AppColors.buildPrimaryGradient(),
                            lableColor: Colors.white,
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.themeColor),
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

class RoundedButtonNew extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color lableColor;

  const RoundedButtonNew({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.gradient,
    required this.lableColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: gradient,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: TextStyle(
                  color: lableColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
