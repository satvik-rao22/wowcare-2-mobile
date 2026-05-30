import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/qr_validation_cubit.dart';

/// Full-screen QR scanner.
///
/// Creates its own [QrValidationCubit] (factory from DI). The cubit resolves
/// school code, user role, and attendance status internally — no args needed.
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
  Barcode? _result;
  QRViewController? _controller;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _hasNavigated = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
      Future.delayed(const Duration(milliseconds: 300), () {
        _controller?.resumeCamera();
      });
    } else {
      _controller?.resumeCamera();
    }
  }

  void _resetScan() {
    setState(() {
      _result = null;
      _hasNavigated = false;
    });
    context.read<QrValidationCubit>().reset();
    _controller?.resumeCamera();
  }

  /// Routes to the correct attendance form based on the cubit-resolved route.
  void _navigateAfterSuccess(QrNavigationRoute route) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final Widget destination;
    switch (route) {
      case QrNavigationRoute.guardianSignIn:
        destination = const StudentSelectionSignInForm();
      case QrNavigationRoute.guardianSignOut:
        destination = const StudentSelectionSignOutForm();
      case QrNavigationRoute.staffSignIn:
        destination = const StaffSignInForm();
      case QrNavigationRoute.staffSignOut:
        destination = const StaffSignOutForm();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrValidationCubit, QrValidationState>(
      listenWhen: (_, curr) => curr is! QrValidationLoading,
      listener: (context, state) {
        if (state is QrValidationSuccess) {
          if (state.result.valid) {
            _navigateAfterSuccess(state.route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.result.reason ?? 'QR code is not valid')),
            );
            _resetScan();
          }
        } else if (state is QrValidationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          _resetScan();
        }
      },
      child: Scaffold(
        body: BlocBuilder<QrValidationCubit, QrValidationState>(
          builder: (context, state) {
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(flex: 4, child: _buildQrView()),
                    Expanded(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              _result != null ? 'Validating...' : 'Scan a QR code',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFlashToggle(),
                                _buildCameraFlipButton(),
                                _buildScanAgainButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (state is QrValidationLoading) _buildLoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQrView() {
    final scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return Stack(
      children: [
        QRView(
          key: _qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: AppColors.primaryColor,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
          onPermissionSet: _onPermissionSet,
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashToggle() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Text('Flash:'),
          GestureDetector(
            onTap: () async {
              setState(() => _isFlashOn = !_isFlashOn);
              await _controller?.toggleFlash();
            },
            child: Container(
              width: 58,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: _isFlashOn
                    ? null
                    : AppColors.buildPrimaryGradient().withOpacity(0.4),
                color: _isFlashOn
                    ? const Color.fromRGBO(56, 200, 32, 0.6)
                    : null,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _isFlashOn ? 26 : 2,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFlipButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: IconButton(
        icon: Icon(
          _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
          size: 30,
        ),
        onPressed: () async {
          setState(() => _isFrontCamera = !_isFrontCamera);
          await _controller?.flipCamera();
        },
      ),
    );
  }

  Widget _buildScanAgainButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: _resetScan,
        child: const Text('Scan Again'),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Validating QR code...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() => _controller = controller);

    controller.scannedDataStream.listen((scanData) async {
      final raw = scanData.code?.trim();
      // Duplicate scan guard — camera is paused immediately after first scan.
      if (_result != null || raw == null || raw.isEmpty) return;

      setState(() => _result = scanData);
      await controller.pauseCamera();

      final token = _extractToken(raw);
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code')),
        );
        _resetScan();
        return;
      }

      if (!mounted) return;
      // Pass the opaque token to the cubit. The cubit resolves school code,
      // user role, and sign-in status, then sends the correct useCase to the API.
      context.read<QrValidationCubit>().validate(qrToken: token);
    });
  }

  /// Extracts the opaque token from the scanned string.
  ///
  /// Priority: JSON `qrToken` → JSON `qrPayload` → raw string.
  String? _extractToken(String raw) {
    if (raw.startsWith('{')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return QrTokenExtractor.extractFromMap(map);
      } catch (_) {
        // Not valid JSON — fall through.
      }
    }
    return raw.isNotEmpty ? raw : null;
  }

  void _onPermissionSet(QRViewController ctrl, bool granted) {
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  @override
  void dispose() {
    // QRViewController self-disposes when QRView is unmounted.
    super.dispose();
  }
}
