import 'dart:async';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/qr_scanner.dart';
import 'package:wowcare/presentation/features/dashboard/model/dashboard_route_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/qr_validation_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';

/// Attendance QR scan: scans with [QrScannerView], validates the token,
/// then opens the matching sign-in / sign-out form.
class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QrValidationCubit>(
      create: (_) => serviceLocator<QrValidationCubit>(),
      child: const _QrScanView(),
    );
  }
}

class _QrScanView extends StatefulWidget {
  const _QrScanView();

  @override
  State<_QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<_QrScanView> {
  final _scanner = GlobalKey<QrScannerViewState>();
  bool _hasNavigated = false;

  void _onScanned(String token) {
    List<String> guardianChildCodes = [];
    try {
      guardianChildCodes = context
          .read<ParentChildCubit>()
          .children
          .map((c) => c.code)
          .toList();
    } catch (_) {}
    unawaited(
      context.read<QrValidationCubit>().validate(
        qrToken: token,
        guardianChildCodes: guardianChildCodes,
      ),
    );
  }

  /// After a failed check: show the camera again and wait for a new scan.
  void _scanAgain() {
    _hasNavigated = false;
    context.read<QrValidationCubit>().reset();
    _scanner.currentState?.rescan();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _scanAgain();
  }

  void _navigateAfterSuccess(
    QrNavigationRoute route,
    String qrToken, {
    List<String> signedInCodes = const [],
    List<String> signedOutCodes = const [],
  }) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (route == QrNavigationRoute.guardianSignIn ||
        route == QrNavigationRoute.guardianSignOut ||
        route == QrNavigationRoute.guardianSignInOut) {
      if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You must be inside geofence and signed in to manage student attendance.',
            ),
          ),
        );
        _scanAgain();
        return;
      }
    }

    if (route == QrNavigationRoute.guardianSignInOut) {
      // Mixed state — pop scanner then navigate to selection screen.
      context.pop();
      context.go(
        DashboardRoutes.childSignInOutSelection,
        extra: ChildSignInOutSelectionArgs(
          signedInCodes: signedInCodes,
          signedOutCodes: signedOutCodes,
          isQrScan: true,
          qrToken: qrToken,
        ),
      );
      return;
    }

    final Widget destination;
    switch (route) {
      case QrNavigationRoute.guardianSignIn:
        destination = StudentSelectionSignInForm(
          isQrScan: true,
          qrToken: qrToken,
        );
      case QrNavigationRoute.guardianSignOut:
        destination = StudentSelectionSignOutForm(
          isQrScan: true,
          qrToken: qrToken,
        );
      case QrNavigationRoute.staffSignIn:
        destination = StaffSignInForm(qrToken: qrToken);
      case QrNavigationRoute.staffSignOut:
        destination = StaffSignOutForm(qrToken: qrToken);
      case QrNavigationRoute.guardianSignInOut:
        return; // handled above
    }

    unawaited(
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrValidationCubit, QrValidationState>(
      listenWhen: (_, curr) => curr is! QrValidationLoading,
      listener: (context, state) {
        if (state is QrValidationSuccess) {
          if (state.result.valid) {
            _navigateAfterSuccess(
              state.route,
              state.qrToken,
              signedInCodes: state.signedInCodes,
              signedOutCodes: state.signedOutCodes,
            );
          } else {
            _showError(state.result.reason ?? 'QR code is not valid');
          }
        } else if (state is QrValidationFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            QrScannerView(key: _scanner, onScanned: _onScanned),
            BlocBuilder<QrValidationCubit, QrValidationState>(
              builder: (context, state) => state is QrValidationLoading
                  ? const _ValidatingOverlay()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidatingOverlay extends StatelessWidget {
  const _ValidatingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.65),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Validating QR code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
