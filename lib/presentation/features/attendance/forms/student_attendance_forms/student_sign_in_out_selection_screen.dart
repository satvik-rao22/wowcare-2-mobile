import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';

class StudentSignInOutSelectionScreen extends StatefulWidget {
  static const String routeName = '/student-sign-in-out-selection';

  const StudentSignInOutSelectionScreen({
    required this.signedInCodes,
    required this.signedOutCodes,
    this.guardianCode,
    this.pin,
    this.isQrScan = false,
    this.qrToken = '',
    super.key,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;
  final String? guardianCode;
  final String? pin;
  final bool isQrScan;
  final String qrToken;

  @override
  State<StudentSignInOutSelectionScreen> createState() =>
      _StudentSignInOutSelectionScreenState();
}

class _StudentSignInOutSelectionScreenState
    extends State<StudentSignInOutSelectionScreen> {
  bool _isValidating = false;

  bool _isKioskMode() {
    return KioskAccessControl.isKioskModeActiveDirect();
  }

  /// When coming from a QR scan, re-validate with the correct useCase BEFORE
  /// navigating so the validate endpoint always receives the right useCase
  /// (GUARDIAN_SIGN_IN for sign-in, GUARDIAN_SIGN_OUT for sign-out).
  Future<void> _validateAndRun({
    required QrAttendanceUseCase useCase,
    required VoidCallback onSuccess,
  }) async {
    if (!widget.isQrScan || widget.qrToken.isEmpty) {
      onSuccess();
      return;
    }

    setState(() => _isValidating = true);
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode))?.trim() ?? '';

      AppLogger.d(
        '[QR ATTENDANCE] Re-validating with useCase=${useCase.apiValue} '
        'for mixed-state selection',
      );

      final validateUseCase = serviceLocator<ValidateQrCodeUseCase>();
      final result = await validateUseCase(
        schoolCode: schoolCode,
        qrToken: widget.qrToken,
        useCase: useCase,
      );
      if (!mounted) return;
      if (result.valid) {
        onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.reason ?? 'QR code is not valid')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to validate QR code')),
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKiosk = _isKioskMode();
    return StaffFormLayout(
      title: 'Sign In / Sign Out',
      isKiosk: isKiosk,
      bottomBar: const SizedBox.shrink(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomConfirmButton(
              label: _isValidating ? 'Validating...' : 'Sign In',
              onPressed: _isValidating
                  ? null
                  : () async {
                      bool isKiosk = false;
                      try {
                        isKiosk = await serviceLocator<KioskAccessControl>()
                            .isKioskModeActive();
                      } catch (e) {
                        try {
                          isKiosk = await KioskAccessControl(
                            serviceLocator(),
                          ).isKioskModeActive();
                        } catch (e2) {
                          AppLogger.d(
                            '[Attendance] Not in kiosk mode, using normal flow',
                          );
                        }
                      }

                      await _validateAndRun(
                        useCase: QrAttendanceUseCase.guardianSignIn,
                        onSuccess: () {
                          if (isKiosk) {
                            AppLogger.d(
                              '[KIOSK] Routing to kiosk student sign-in action: '
                              'guardianCode=${widget.guardianCode}',
                            );
                            context.go(
                              '/kiosk/student-sign-in-and-sign-out',
                              extra: <String, dynamic>{
                                'isKiosk': true,
                                'guardianCode': widget.guardianCode,
                                'pin': widget.pin,
                                'action': 'sign-in',
                                'signedInCodes': const [],
                                'signedOutCodes': widget.signedOutCodes,
                              },
                            );
                          } else {
                            AppLogger.d(
                              '[Attendance] Routing to dashboard student-selection-sign-in-form',
                            );
                            context.go(
                              '/dashboard/student-selection-sign-in-form',
                              extra: <String, dynamic>{
                                'allowedStudentCodes': widget.signedOutCodes,
                                'isQrScan': widget.isQrScan,
                                'qrToken': widget.qrToken,
                              },
                            );
                          }
                        },
                      );
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            CustomConfirmButton(
              label: _isValidating ? 'Validating...' : 'Sign Out',
              onPressed: _isValidating
                  ? null
                  : () async {
                      bool isKiosk = false;
                      try {
                        isKiosk = await serviceLocator<KioskAccessControl>()
                            .isKioskModeActive();
                      } catch (e) {
                        try {
                          isKiosk = await KioskAccessControl(
                            serviceLocator(),
                          ).isKioskModeActive();
                        } catch (e2) {
                          AppLogger.d(
                            '[Attendance] Not in kiosk mode, using normal flow',
                          );
                        }
                      }

                      await _validateAndRun(
                        useCase: QrAttendanceUseCase.guardianSignOut,
                        onSuccess: () {
                          if (isKiosk) {
                            AppLogger.d(
                              '[KIOSK] Routing to kiosk student sign-out action: '
                              'guardianCode=${widget.guardianCode}',
                            );
                            context.go(
                              '/kiosk/student-sign-in-and-sign-out',
                              extra: <String, dynamic>{
                                'isKiosk': true,
                                'guardianCode': widget.guardianCode,
                                'pin': widget.pin,
                                'action': 'sign-out',
                                'signedInCodes': widget.signedInCodes,
                                'signedOutCodes': const [],
                              },
                            );
                          } else {
                            AppLogger.d(
                              '[Attendance] Routing to dashboard student-selection-sign-out-form',
                            );
                            context.go(
                              '/dashboard/student-selection-sign-out-form',
                              extra: <String, dynamic>{
                                'allowedStudentCodes': widget.signedInCodes,
                                'isQrScan': widget.isQrScan,
                                'qrToken': widget.qrToken,
                              },
                            );
                          }
                        },
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
