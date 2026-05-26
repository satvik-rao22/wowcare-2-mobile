import 'dart:developer';
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

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key, required this.args});

  final QrScannerArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QrValidationCubit>(
      create: (_) => serviceLocator<QrValidationCubit>(),
      child: _QrScanView(args: args),
    );
  }
}

class _QrScanView extends StatefulWidget {
  const _QrScanView({required this.args});
  final QrScannerArgs args;

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

  void _navigateAfterSuccess() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final route = widget.args.isGuardianFlow
        ? _resolveGuardianRoute()
        : _resolveStaffRoute();

    Navigator.push(context, MaterialPageRoute(builder: (_) => route));
  }

  Widget _resolveGuardianRoute() {
    final statuses = widget.args.studentSignInStatuses ?? [];
    final allSignedIn = statuses.isNotEmpty && statuses.every((s) => s);
    if (allSignedIn) return const StudentSelectionSignOutForm();
    return const StudentSelectionSignInForm();
  }

  Widget _resolveStaffRoute() {
    final isSignedIn = widget.args.staffSignedIn ?? false;
    if (isSignedIn) return const StaffSignOutForm();
    return const StaffSignInForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrValidationCubit, QrValidationState>(
      listenWhen: (prev, curr) => curr is! QrValidationLoading,
      listener: (context, state) {
        if (state is QrValidationSuccess) {
          if (state.result.valid) {
            _navigateAfterSuccess();
          } else {
            final reason = state.result.reason ?? 'QR code is not valid';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(reason)));
            _resetScan();
          }
        } else if (state is QrValidationFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          _resetScan();
        }
      },
      child: Scaffold(
        body: BlocBuilder<QrValidationCubit, QrValidationState>(
          builder: (context, state) {
            final isValidating = state is QrValidationLoading;
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
                              _result != null
                                  ? 'Validating...'
                                  : 'Scan a QR code',
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
                if (isValidating) _buildLoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQrView() {
    final scanArea =
        (MediaQuery.of(context).size.width < 400 ||
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
      if (_result != null || scanData.code == null) return;

      setState(() => _result = scanData);
      await controller.pauseCamera();
      log('QR scanned: ${scanData.code}');

      final parts = scanData.code!.split('|');
      if (parts.length >= 3 && parts[0] == 'SCHOOL_QR') {
        final schoolId = parts[1];
        final qrToken = parts[2];
        log('schoolId=$schoolId  qrToken=$qrToken');

        if (!mounted) return;
        context.read<QrValidationCubit>().validate(
          schoolCode: schoolId,
          qrToken: qrToken,
          useCase: widget.args.useCase,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid QR code format')));
        _resetScan();
      }
    });
  }

  void _onPermissionSet(QRViewController ctrl, bool granted) {
    if (!granted && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
