import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/widgets/sign_in_form.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/rounded_button_new.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/shared/common/view/web_view_screen.dart';

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
  final ValueNotifier<bool> _rememberMe = ValueNotifier(false);

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
    final prefill = await context.read<AuthCubit>().loadSavedCredentials();
    if (!mounted) return;
    emailController.text = prefill.username;
    _rememberMe.value = prefill.rememberMe;
    if (prefill.password != null) {
      passwordController.text = prefill.password!;
    }
  }

  Future<void> _saveCredentials() {
    return context.read<AuthCubit>().saveCredentials(
      username: emailController.text,
      password: passwordController.text,
      rememberMe: _rememberMe.value,
    );
  }

  Future<void> _navigateToSchoolSelection(BuildContext context) async {
    // Get orgCode from storage (saved when schoolCode was null)
    final orgCode = await context.read<AuthCubit>().getSavedOrganizationCode();

    if (orgCode != null && orgCode.isNotEmpty) {
      context.go(
        '/school-selection',
        extra: <String, dynamic>{
          'selectedOrg': orgCode,
          'orgFromLoginContext': true,
        },
      );
    } else {
      // Fallback: go to org selection if orgCode not found
      context.go('/org-selection');
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      // Emails are case-insensitive; normalise so an upper-case entry doesn't
      // get rejected as invalid credentials.
      await _saveCredentials();

      final authCubit = context.read<AuthCubit>();
      await authCubit.login(
        username: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
      );
    }
  }

  Future<void> _preloadGuardianChildrenIfNeeded(BuildContext context) async {
    try {
      // Ensure RoleCubit resolved from /users/details first.
      await context.read<RoleCubit>().refreshAccessFromServer(force: true);
      if (!context.mounted) return;
      if (!context.read<RoleCubit>().isParent) return;

      // Guardian only: prefetch children before opening dashboard so AppBar doesn't
      // have to trigger loading later.
      context.read<ParentChildCubit>().invalidate();
      await context.read<ParentChildCubit>().ensureLoaded(force: true);
    } catch (_) {
      // Non-blocking: dashboard can still open; AppBar dropdown will show empty.
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) async {
    if (state is AuthLoaded) {
      // Save credentials after successful login
      _saveCredentials();

      // KIOSK: detect from login response roles — no API call, no RoleCubit needed.
      AppLogger.d(
        '[SignIn] AuthLoaded - checking roles: ${state.loginResponse.roles.map((r) => r.role).toList()}',
      );
      if (loginResponseIsKioskUser(state.loginResponse.roles)) {
        AppLogger.d('[SignIn] Kiosk user detected - redirecting to /kiosk');
        if (context.mounted) {
          context.go('/kiosk');
        }
        return;
      }
      AppLogger.d('[SignIn] Not a kiosk user - continuing normal flow');

      await _preloadGuardianChildrenIfNeeded(context);

      // The await above can outlive this screen (e.g. a duplicate auth event
      // already navigated away). Bail out before touching context/GoRouter.
      if (!context.mounted) return;

      // Check redirectUrl when schoolCode is null
      if (state.redirectUrl != null && state.redirectUrl!.isNotEmpty) {
        final url = state.redirectUrl!.toLowerCase();
        if (url.contains('select-school')) {
          // Navigate to school selection - need orgCode from storage
          _navigateToSchoolSelection(context);
          return;
        } else if (url.contains('select-organization')) {
          context.go('/org-selection');
          return;
        } else if (url.contains('select-app')) {
          context.go(DashboardScreen.routeName);
          return;
        } else if (url.contains('dashboard')) {
          // Backend may return a dashboard redirect even when LastLoginSchoolCode is null.
          // In that case, do NOT force role selection — go straight to Dashboard.
          context.go(DashboardScreen.routeName);
          return;
        }
      }

      // After login-context, always go straight to Dashboard.
      // Role selection screen is no longer part of the flow.
      context.go(DashboardScreen.routeName);
    } else if (state is AuthError) {
      // Show backend error message using the shared top snackbar.
      // (AuthCubit.login already wipes the stale saved password on failure.)
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
    _rememberMe.dispose();
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
            child: ColoredBox(
              color: AppColors.pageBackgroundColor,
              child: Stack(
                children: [
                  const _Brandmark(),
                  _buildBottomMenu(context, state),
                ],
              ),
            ),
          ),
        );
      },
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
            // The form is a panel raised off the page ground: card face, lit
            // top edge, its shadow thrown up onto the ground behind it.
            decoration: AppSurfaces.card(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Login with email',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SignInForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    formKey: formKey,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _rememberMe,
                      builder: (context, remember, _) => GestureDetector(
                        onTap: () => _rememberMe.value = !remember,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 2),
                            CustomCheckbox(
                              value: remember,
                              onChanged: (bool? clicked) {
                                _rememberMe.value = clicked ?? false;
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
                              decoration: AppSurfaces.fab(),
                              child: const RefreshProgressIndicator(
                                color: AppColors.cardColor,
                                elevation: 0,
                                backgroundColor: AppColors.transparentColor,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : ListenableBuilder(
                            key: const ValueKey('button'),
                            listenable: Listenable.merge([
                              emailController,
                              passwordController,
                            ]),
                            builder: (context, _) => RoundedButtonNew(
                              label: 'Sign-In',
                              isLoading: isLoading,
                              enabled:
                                  emailController.text.trim().isNotEmpty &&
                                  passwordController.text.trim().isNotEmpty,
                              onPressed: () => _handleSignIn(context),
                              lableColor: AppPalette.onBrand,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      context.push(AppRoutes.forgotPassword);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.themeColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _LegalConsentText(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The logo and the wordmark, on the page ground.
///
/// A private widget class (not a `_buildXxx()` method) so it can be `const`
/// — it never rebuilds when [AuthState] changes, unlike a method called from
/// inside the `BlocConsumer` builder would.
class _Brandmark extends StatelessWidget {
  const _Brandmark();

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: screen.width,
        height: screen.height * 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // The same mark the launcher icon and the splash are generated
            // from. Its canvas is 1000x1240, so it is sized by height only.
            Image.asset(
              MediaRes.appLogo,
              height: screen.height * 0.16,
              fit: BoxFit.contain,
            ),
            SizedBox(height: screen.height * 0.012),
            Text(
              'WowCare',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: screen.height * 0.032,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// "By continuing, you agree to our Terms & Conditions and Privacy Policy",
/// with both documents opening in the in-app browser.
///
/// Stateful purely to own the two [TapGestureRecognizer]s — those hold native
/// gesture-arena resources and must be disposed, which a `StatelessWidget`
/// building them inline could never do.
class _LegalConsentText extends StatefulWidget {
  const _LegalConsentText();

  @override
  State<_LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<_LegalConsentText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  static const String _termsUrl = 'https://childcarewow.com/terms/';
  static const String _privacyUrl = 'https://childcarewow.com/privacy/';

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => openWebViewScreen(
        context,
        url: _termsUrl,
        title: 'Terms & Conditions',
      );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => openWebViewScreen(
        context,
        url: _privacyUrl,
        title: 'Privacy Policy',
      );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 12,
      color: AppPalette.textSecondary,
      height: 1.4,
    );
    const linkStyle = TextStyle(
      fontSize: 12,
      height: 1.4,
      color: AppColors.themeColor,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms & Conditions',
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
