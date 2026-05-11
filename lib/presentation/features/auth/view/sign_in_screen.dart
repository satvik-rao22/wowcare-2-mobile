import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/widget/sign_in_form.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:provider/provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
    });
  }

  Future<void> _loadSavedCredentials() async {
    final localDataSource = serviceLocator<AuthLocalDataSource>();
    final credentials = await localDataSource.getSavedCredentials();
    final storage = serviceLocator<StorageService>();
    final rememberMeValue =
        await storage.getBool(StorageKeys.rememberMe) ?? false;

    if (mounted) {
      setState(() {
        emailController.text = credentials['username'] ?? '';
        passwordController.text = credentials['password'] ?? '';
        rememberMe = rememberMeValue;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final localDataSource = serviceLocator<AuthLocalDataSource>();

    await localDataSource.saveCredentials(
      emailController.text.trim(),
      passwordController.text.trim(),
      rememberMe,
    );
  }

  Future<void> _navigateToSchoolSelection(BuildContext context) async {
    // Get orgCode from storage (saved when schoolCode was null)
    final storage = serviceLocator<StorageService>();
    final orgCode = await storage.getString(StorageKeys.organizationCode);

    if (orgCode != null && orgCode.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SchoolSelectionScreen(
            selectedOrg: orgCode,
            orgFromLoginContext: true,
          ),
        ),
      );
    } else {
      // Fallback: go to org selection if orgCode not found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrganizationSelectionScreen()),
      );
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      await _saveCredentials();

      final authCubit = context.read<AuthCubit>();
      await authCubit.login(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoaded) {
      // Save credentials after successful login
      _saveCredentials();
      context.read<RoleProvider>().refreshAccessFromServer(force: true);

      // Check redirectUrl when schoolCode is null
      if (state.redirectUrl != null && state.redirectUrl!.isNotEmpty) {
        final url = state.redirectUrl!.toLowerCase();
        if (url.contains('select-school')) {
          // Navigate to school selection - need orgCode from storage
          _navigateToSchoolSelection(context);
          return;
        } else if (url.contains('select-organization')) {
          // Navigate to org selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OrganizationSelectionScreen(),
            ),
          );
          return;
        } else if (url.contains('select-app')) {
          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          return;
        } else if (url.contains('dashboard')) {
          // Backend may return a dashboard redirect even when LastLoginSchoolCode is null.
          // In that case, do NOT force role selection — go straight to Dashboard.
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
          return;
        }
      }

      // After login-context, always go straight to Dashboard.
      // Role selection screen is no longer part of the flow.
      Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
    } else if (state is AuthError) {
      // Show backend error message using the shared top snackbar
      CoreUtils.showTopSnackBar(
        context: context,
        message: state.message,
        isError: true,
      );
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
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _handleAuthState,
      builder: (context, state) {
        return Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
              ),
              child: Stack(
                children: [
                  _buildLottieAnimation(),
                  _buildBottomMenu(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLottieAnimation() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(
          top:
              MediaQuery.of(context).padding.top +
              MediaQuery.of(context).size.height * 0.01,
        ),
        height: MediaQuery.of(context).size.height * 0.4,
        child: Lottie.asset(MediaRes.signInLottie),
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _bottomMenuHeightAnimationController,
        builder: (context, child) {
          final height =
              MediaQuery.of(context).size.height *
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    '  Login with email',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  SignInForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    formKey: formKey,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child: isLoading
                        ? Center(
                            key: const ValueKey('loading'),
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
                            key: const ValueKey('button'),
                            label: 'Sign-In',
                            isLoading: isLoading,
                            onPressed: () => _handleSignIn(context),
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
