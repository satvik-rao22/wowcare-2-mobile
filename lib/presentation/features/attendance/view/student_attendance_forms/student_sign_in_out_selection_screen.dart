import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_sign_in_out_selection_cubit.dart';
import 'package:wowcare/core/auth/kiosk_access_control.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/core/utils/core_utils.dart';

class StudentSignInOutSelectionScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider<StudentSignInOutSelectionCubit>(
      create: (_) => serviceLocator<StudentSignInOutSelectionCubit>(),
      child: _StudentSignInOutSelectionView(
        signedInCodes: signedInCodes,
        signedOutCodes: signedOutCodes,
        guardianCode: guardianCode,
        pin: pin,
        isQrScan: isQrScan,
        qrToken: qrToken,
      ),
    );
  }
}

class _StudentSignInOutSelectionView extends StatelessWidget {
  const _StudentSignInOutSelectionView({
    required this.signedInCodes,
    required this.signedOutCodes,
    required this.guardianCode,
    required this.pin,
    required this.isQrScan,
    required this.qrToken,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;
  final String? guardianCode;
  final String? pin;
  final bool isQrScan;
  final String qrToken;

  bool _isKioskMode() =>
      serviceLocator<KioskAccessControl>().isKioskModeActiveDirect();

  Future<bool> _resolveIsKiosk() async {
    try {
      return await serviceLocator<KioskAccessControl>().isKioskModeActive();
    } catch (e) {
      AppLogger.d('[Attendance] Not in kiosk mode, using normal flow');
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    CoreUtils.showTopSnackBarFromSnackBar(
      context: context,
      snackBar: SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKiosk = _isKioskMode();
    final cubit = context.read<StudentSignInOutSelectionCubit>();

    return BlocBuilder<
      StudentSignInOutSelectionCubit,
      StudentSignInOutSelectionState
    >(
      builder: (context, state) {
        final isValidating = state.isValidating;
        return StaffFormLayout(
          title: 'Sign In / Sign Out',
          isKiosk: isKiosk,
          bottomBar: null,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomConfirmButton(
                  label: isValidating ? 'Validating...' : 'Sign In',
                  onPressed: isValidating
                      ? null
                      : () async {
                          final resolvedIsKiosk = await _resolveIsKiosk();
                          if (!context.mounted) return;

                          await cubit.validateAndRun(
                            isQrScan: isQrScan,
                            qrToken: qrToken,
                            useCase: QrAttendanceUseCase.guardianSignIn,
                            onSuccess: () {
                              if (resolvedIsKiosk) {
                                AppLogger.d(
                                  '[KIOSK] Routing to kiosk student sign-in action: '
                                  'guardianCode=$guardianCode',
                                );
                                context.go(
                                  '/kiosk/student-sign-in-and-sign-out',
                                  extra: <String, dynamic>{
                                    'isKiosk': true,
                                    'guardianCode': guardianCode,
                                    'pin': pin,
                                    'action': 'sign-in',
                                    'signedInCodes': const [],
                                    'signedOutCodes': signedOutCodes,
                                  },
                                );
                              } else {
                                AppLogger.d(
                                  '[Attendance] Routing to dashboard student-selection-sign-in-form',
                                );
                                context.go(
                                  '/dashboard/student-selection-sign-in-form',
                                  extra: <String, dynamic>{
                                    'allowedStudentCodes': signedOutCodes,
                                    'isQrScan': isQrScan,
                                    'qrToken': qrToken,
                                  },
                                );
                              }
                            },
                            onInvalid: (message) {
                              if (context.mounted)
                                _showSnackBar(context, message);
                            },
                            onError: () {
                              if (context.mounted) {
                                _showSnackBar(
                                  context,
                                  'Failed to validate QR code',
                                );
                              }
                            },
                          );
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                CustomConfirmButton(
                  label: isValidating ? 'Validating...' : 'Sign Out',
                  onPressed: isValidating
                      ? null
                      : () async {
                          final resolvedIsKiosk = await _resolveIsKiosk();
                          if (!context.mounted) return;

                          await cubit.validateAndRun(
                            isQrScan: isQrScan,
                            qrToken: qrToken,
                            useCase: QrAttendanceUseCase.guardianSignOut,
                            onSuccess: () {
                              if (resolvedIsKiosk) {
                                AppLogger.d(
                                  '[KIOSK] Routing to kiosk student sign-out action: '
                                  'guardianCode=$guardianCode',
                                );
                                context.go(
                                  '/kiosk/student-sign-in-and-sign-out',
                                  extra: <String, dynamic>{
                                    'isKiosk': true,
                                    'guardianCode': guardianCode,
                                    'pin': pin,
                                    'action': 'sign-out',
                                    'signedInCodes': signedInCodes,
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
                                    'allowedStudentCodes': signedInCodes,
                                    'isQrScan': isQrScan,
                                    'qrToken': qrToken,
                                  },
                                );
                              }
                            },
                            onInvalid: (message) {
                              if (context.mounted)
                                _showSnackBar(context, message);
                            },
                            onError: () {
                              if (context.mounted) {
                                _showSnackBar(
                                  context,
                                  'Failed to validate QR code',
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
      },
    );
  }
}
