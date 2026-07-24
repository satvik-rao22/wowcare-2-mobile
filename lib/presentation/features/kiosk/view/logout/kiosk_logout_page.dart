import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_logout_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';

import '../../../../../core/util/api_error_handler.dart';

class KioskLogoutPage extends StatefulWidget {
  const KioskLogoutPage({super.key});

  static const String routeName = '/logout';
  static const String fullPath = '/kiosk/logout';

  @override
  State<KioskLogoutPage> createState() => _KioskLogoutPageState();
}

class _KioskLogoutPageState extends State<KioskLogoutPage> {
  String _currentPin = '';
  final int maxPinLength = 4;
  bool _isSubmitting = false;
  late BuildContext _blocContext; // Store BlocBuilder's context

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
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
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
                _blocContext = ctx; // ← Capture the BlocBuilder's context
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

                        // PIN Display Boxes
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              maxPinLength,
                              (index) => Container(
                                width: 55,
                                height: 55,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    index < _currentPin.length
                                        ? _currentPin[index]
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.themeColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

                        const SizedBox(height: 40),

                        // PIN Pad
                        _buildLogoutPinPad(ctx),

                        const SizedBox(height: 50),

                        // Action Buttons (styled to match KioskPinPadWidget)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient:
                                        AppColors.buildSecondaryGradient(),
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            AppLogger.d(
                                              '[Kiosk Logout] Cancel pressed',
                                            );
                                            _currentPin = '';
                                            setState(() {});
                                            context.go('/kiosk');
                                          },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (Rect bounds) =>
                                          AppColors.buildSecondaryGradient()
                                              .createShader(bounds),
                                      blendMode: BlendMode.srcIn,
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 16 * (-3 / 100),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Next Button (styled to match KioskPinPadWidget)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient:
                                        AppColors.buildSecondaryGradient(),
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ||
                                            _currentPin.length != maxPinLength
                                        ? null
                                        : () => _submitPin(ctx),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Next',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 16 * (-3 / 100),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
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

  void _addDigit(String digit) {
    if (_currentPin.length < maxPinLength) {
      setState(() {
        _currentPin += digit;
      });

      // TODO: Temporarily disabled auto-trigger for Next button.
      // User must explicitly tap the Next button.
      // Auto-submit when max PIN length is reached
      // if (_currentPin.length == maxPinLength) {
      //   Future.delayed(const Duration(milliseconds: 300), () {
      //     if (mounted) {
      //       _submitPin(_blocContext);  // ← Use captured BlocBuilder context
      //     }
      //   });
      // }
    }
  }

  void _removeDigit() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  Future<void> _submitPin(BuildContext ctx) async {
    // Prevent multiple concurrent submissions
    if (_isSubmitting) {
      AppLogger.w(
        '[Kiosk Logout] Submission already in progress, ignoring duplicate call',
      );
      return;
    }

    _isSubmitting = true;
    AppLogger.d(
      '[Kiosk Logout] PIN submitted - proceeding with logout: pinLength=${_currentPin.length}',
    );

    try {
      final cubit = ctx.read<KioskLogoutCubit>();
      AppLogger.d('[Kiosk Logout] Cubit instance obtained, calling logout()');

      // Execute logout with timeout to prevent hanging
      final success = await cubit
          .logout(pin: _currentPin)
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
      if (mounted) {
        _currentPin = '';
        setState(() {});
      }
    }
  }

  Widget _buildLogoutPinPad(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPadButton('1'),
              _buildPadButton('2'),
              _buildPadButton('3'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPadButton('4'),
              _buildPadButton('5'),
              _buildPadButton('6'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPadButton('7'),
              _buildPadButton('8'),
              _buildPadButton('9'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 90),
              _buildPadButton('0'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 70,
                height: 50,
                child: ElevatedButton(
                  onPressed: _removeDigit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.backspace_outlined, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(String number) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 70,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _addDigit(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
