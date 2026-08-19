import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/core/auth/secure_credential_store.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/widget/sign_in_form.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';

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
    // Keep the Sign-In button's enabled state in sync with the fields so it
    // stays disabled until both email and password have been entered.
    emailController.addListener(_onCredentialsChanged);
    passwordController.addListener(_onCredentialsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
    });
  }

  /// Both fields must be non-empty before the user can submit.
  bool get _canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.trim().isNotEmpty;

  void _onCredentialsChanged() {
    if (mounted) setState(() {});
  }

  bool _offeredBiometricPrefill = false;

  /// Whether the secure store is holding a password. Drives the visibility of
  /// the biometric unlock key: with nothing saved there is nothing to unlock.
  bool _hasSavedPassword = false;

  Future<void> _loadSavedCredentials() async {
    final localDataSource = serviceLocator<AuthLocalDataSource>();
    final credentials = await localDataSource.getSavedCredentials();
    final storage = serviceLocator<StorageService>();
    final rememberMeValue =
        await storage.getBool(StorageKeys.rememberMe) ?? false;
    AppLogger.d(
      '[RememberMe] load: rememberMe=$rememberMeValue '
      'savedUser="${credentials['username'] ?? ''}"',
    );

    if (mounted) {
      setState(() {
        emailController.text = credentials['username'] ?? '';
        rememberMe = rememberMeValue;
      });
    }

    // "Remember me" password pre-fill: the password lives only in the secure
    // store. If the device has a biometric / passcode we prompt for it first;
    // if it has neither, the password is filled in without a prompt so
    // "Remember me" still works on unsecured devices.
    if (rememberMeValue) {
      await _offerBiometricPrefill();
    } else {
      // No auto-prompt, but the unlock key still needs to know whether the
      // Keychain has anything in it.
      await _refreshHasSavedPassword();
    }
  }

  Future<void> _refreshHasSavedPassword() async {
    try {
      final has = await serviceLocator<SecureCredentialStore>()
          .hasSavedPassword();
      if (mounted && _hasSavedPassword != has) {
        setState(() => _hasSavedPassword = has);
      }
    } catch (_) {
      // Secure store unavailable — the unlock key simply stays hidden.
    }
  }

  /// The explicit "Unlock with Face ID" key. Unlike [_offerBiometricPrefill]
  /// this is not one-shot: the user asked for it, so it always prompts.
  Future<void> _unlockWithBiometrics() async {
    _offeredBiometricPrefill = false;
    await _offerBiometricPrefill();
  }

  Future<void> _offerBiometricPrefill() async {
    if (_offeredBiometricPrefill) return;
    _offeredBiometricPrefill = true;
    try {
      final secureStore = serviceLocator<SecureCredentialStore>();
      final has = await secureStore.hasSavedPassword();
      AppLogger.d('[RememberMe] prefill: hasSavedPassword=$has');
      if (mounted && _hasSavedPassword != has) {
        setState(() => _hasSavedPassword = has);
      }
      if (!has) {
        AppLogger.d(
          '[RememberMe] prefill ABORTED — no password in Keychain. It was '
          'either never saved, or wiped (see freshInstallCheck above).',
        );
        return;
      }
      final creds = await secureStore.revealWithBiometrics(
        reason: 'Unlock your saved password to sign in',
      );
      AppLogger.d(
        '[RememberMe] prefill: revealed=${creds != null} '
        'pwLen=${creds?['password']?.length ?? 0}',
      );
      if (creds == null || !mounted) return;
      setState(() {
        final user = creds['username'] ?? '';
        if (user.isNotEmpty) emailController.text = user;
        passwordController.text = creds['password'] ?? '';
      });
    } catch (e) {
      AppLogger.d('[SignIn] biometric prefill error: $e');
      // Biometric cancelled/unavailable — user just types the password.
    }
  }

  Future<void> _saveCredentials() async {
    final localDataSource = serviceLocator<AuthLocalDataSource>();
    final secureStore = serviceLocator<SecureCredentialStore>();
    final username = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    AppLogger.d(
      '[SignIn] _saveCredentials rememberMe=$rememberMe user="$username" '
      'pwLen=${password.length}',
    );
    // Username + rememberMe flag stay in normal storage (non-sensitive).
    await localDataSource.saveCredentials(username, password, rememberMe);

    // Password goes ONLY into the biometric-gated secure store, and only while
    // "Remember me" is on. Unchecking it wipes the saved password immediately.
    if (rememberMe) {
      await secureStore.save(username: username, password: password);
    } else {
      await secureStore.clear();
    }
  }

  Future<void> _navigateToSchoolSelection(BuildContext context) async {
    // Get orgCode from storage (saved when schoolCode was null)
    final storage = serviceLocator<StorageService>();
    final orgCode = await storage.getString(StorageKeys.organizationCode);

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
      // A failed login likely means the saved password is now wrong — wipe it
      // from the secure store so we never pre-fill stale/incorrect credentials.
      serviceLocator<SecureCredentialStore>().clear();
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
    emailController.removeListener(_onCredentialsChanged);
    passwordController.removeListener(_onCredentialsChanged);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: _handleAuthState,
      builder: (context, state) {
        return SkeuScaffold(
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                _buildBrandRail(),
                Expanded(child: _buildSheet(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The navy-to-teal rail the brand lockup sits on, with two soft blooms
  /// bleeding light in from the corners. This is the app's one dark surface, so
  /// everything below it reads as lit from above.
  Widget _buildBrandRail() {
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: SkeuSurfaces.rail),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: SkeuBloom(
                color: SkeuColors.teal500.withValues(alpha: .45),
                size: 200,
              ),
            ),
            Positioned(
              bottom: -70,
              left: -50,
              child: SkeuBloom(
                color: SkeuColors.pink500.withValues(alpha: .28),
                size: 180,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 46),
                child: Center(
                  child: SkeuBrandLockup(
                    markSize: 96,
                    fontSize: 28,
                    tagline: 'Make Every Day Wow!',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The credentials sheet: a raised panel that rides 28px up over the rail and
  /// holds the two wells, the remember-me checkbox and the two keys.
  Widget _buildSheet(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;

    return AnimatedBuilder(
      animation: _bottomMenuHeightAnimationController,
      builder: (context, child) {
        // The sheet slides up from below the fold on first frame — the only
        // entrance animation on the screen.
        return FractionalTranslation(
          translation: Offset(0, 1 - _bottomMenuHeightUpAnimation.value),
          child: child,
        );
      },
      child: Transform.translate(
        offset: const Offset(0, -28),
        child: SkeuPanel(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          gradient: SkeuSurfaces.card,
          insets: SkeuElevation.bevelTop,
          shadows: const [
            BoxShadow(
              color: Color(0x4D0A1C5D),
              offset: Offset(0, -10),
              blurRadius: 26,
              spreadRadius: -14,
            ),
          ],
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SkeuBrandRail(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Login with email',
                  style: SkeuText.field(weight: SkeuText.weightHeading),
                ),
                const SizedBox(height: 18),
                SignInForm(
                  emailController: emailController,
                  passwordController: passwordController,
                  formKey: formKey,
                  onSubmit: _canSubmit ? () => _handleSignIn(context) : null,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SkeuCheckbox(
                      value: rememberMe,
                      onChanged: (checked) =>
                          setState(() => rememberMe = checked),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => rememberMe = !rememberMe),
                      child: Text(
                        'Remember me',
                        style: SkeuText.body(weight: SkeuText.weightHeading),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SkeuButton(
                  label: 'Sign-In',
                  isLoading: isLoading,
                  enabled: _canSubmit,
                  onPressed: () => _handleSignIn(context),
                ),
                if (_hasSavedPassword) ...[
                  const SizedBox(height: 10),
                  SkeuButton(
                    label: 'Unlock with Face ID',
                    variant: SkeuButtonVariant.neutral,
                    icon: Icons.fingerprint_rounded,
                    height: 52,
                    fontSize: 15,
                    onPressed: _unlockWithBiometrics,
                  ),
                ],
                const SizedBox(height: 6),
                SkeuTextButton(
                  label: 'Forgot Password?',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
