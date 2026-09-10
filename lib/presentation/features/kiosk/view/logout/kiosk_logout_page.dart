import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/view_model/kiosk_logout_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_pin_pad_widget.dart';
import '../../../../../core/utils/api_error_handler.dart';

class KioskLogoutPage extends StatefulWidget {
  const KioskLogoutPage({super.key});

  static const String routeName = '/logout';
  static const String fullPath = '/kiosk/logout';

  @override
  State<KioskLogoutPage> createState() => _KioskLogoutPageState();
}

class _KioskLogoutPageState extends State<KioskLogoutPage> {
  final int maxPinLength = 4;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => KioskLogoutCubit(
        authCubit: ctx.read<AuthCubit>(),
        verifyKioskPinUseCase: serviceLocator<VerifyKioskPinUseCase>(),
        storageService: serviceLocator<StorageService>(),
        kioskAccessControl: serviceLocator<KioskAccessControl>(),
      ),
      child: BlocListener<KioskLogoutCubit, KioskLogoutState>(
        listener: (ctx, state) {
          if (state is KioskLogoutSuccess) {
            AppLogger.d(
              '[Kiosk Logout] Logout successful, navigating to sign-in',
            );
            if (ctx.mounted) {
              CoreUtils.showTopSnackBar(
                context: ctx,
                message: 'Logout successful!',
                isSuccess: true,
              );
            }
            // Navigate using the root context to ensure stable navigation
            try {
              ctx.go('/sign-in');
            } catch (e) {
              AppLogger.e('[Kiosk Logout] Navigation error: $e');
            }
          } else if (state is KioskLogoutError) {
            AppLogger.d(
              '[Kiosk Logout] Error state received: ${state.message}',
            );
            if (ctx.mounted) {
              CoreUtils.showTopSnackBar(
                context: ctx,
                message: state.message,
                isError: true,
              );
            }
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              AppLogger.d(
                '[Kiosk Logout] Back button pressed, returning to /kiosk',
              );
              context.go('/kiosk');
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.whiteColor,
            appBar: AppBar(
              backgroundColor: AppColors.whiteColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryColor,
                ),
                onPressed: () {
                  AppLogger.d(
                    '[Kiosk Logout] Back button pressed, returning to /kiosk',
                  );
                  context.go('/kiosk');
                },
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.themeColor,
                ),
              ),
            ),
            body: BlocBuilder<KioskLogoutCubit, KioskLogoutState>(
              builder: (ctx, state) {
                final isLoading = state is KioskLogoutLoading;

                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator
                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.themeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Processing logout...',
                                  style: TextStyle(
                                    color: AppColors.themeColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Instruction Text
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Text(
                            isLoading
                                ? 'Please wait'
                                : 'Enter the pin to logout',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // PIN entry — shared with the dashboard's sign-in/out
                        // flow instead of a second hand-rolled copy (own PIN
                        // dots, keypad and Cancel/Next buttons). `title: null`
                        // because the instruction text above already covers
                        // it; `isLogout: true` skips the widget's internal
                        // KioskDashboardCubit listener (not provided on this
                        // page) in favour of resetting once submit completes.
                        KioskPinPadWidget(
                          maxPinLength: maxPinLength,
                          isLogout: true,
                          title: null,
                          onPinSubmit: (pin, {isLogout = false}) =>
                              _submitPin(ctx, pin),
                          onCancel: () {
                            AppLogger.d('[Kiosk Logout] Cancel pressed');
                            context.go('/kiosk');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPin(BuildContext ctx, String pin) async {
    // Prevent multiple concurrent submissions
    if (_isSubmitting) {
      AppLogger.w(
        '[Kiosk Logout] Submission already in progress, ignoring duplicate call',
      );
      return;
    }

    _isSubmitting = true;
    AppLogger.d('[Kiosk Logout] PIN submitted - proceeding with logout: $pin');

    try {
      final cubit = ctx.read<KioskLogoutCubit>();
      AppLogger.d('[Kiosk Logout] Cubit instance obtained, calling logout()');

      // Execute logout with timeout to prevent hanging
      final success = await cubit
          .logout(pin: pin)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              AppLogger.e('[Kiosk Logout] Logout timed out after 30 seconds');
              throw Exception('Logout request timed out. Please try again.');
            },
          );

      AppLogger.d('[Kiosk Logout] Logout call completed, success=$success');

      // If logout returned false, the KioskLogoutError state (handled by the
      // BlocListener above) already surfaced the API's error message, so no
      // separate snackbar is needed here.
    } catch (e) {
      AppLogger.e('[Kiosk Logout] Error calling logout: $e');
      if (mounted && ctx.mounted) {
        CoreUtils.showTopSnackBar(
          context: ctx,
          message: ApiErrorHandler.extractErrorMessage(e),
          isWarning: true,
        );
      }
    } finally {
      _isSubmitting = false;
    }
  }
}
