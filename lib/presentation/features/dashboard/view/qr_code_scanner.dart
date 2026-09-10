import 'dart:async';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/dashboard/model/dashboard_route_args.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/qr_validation_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';

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

class _QrScanViewState extends State<_QrScanView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Barcode? _result;
  QRViewController? _controller;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _hasNavigated = false;
  AppLifecycleState? _lastLifecycleState;

  // Animated scan line
  late final AnimationController _scanAnim;
  late final Animation<double> _scanLine;

  // Stream subscription for QR scanning
  StreamSubscription<Barcode>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = AppLifecycleState.resumed;
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_scanAnim.repeat(reverse: true));
    _scanLine = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset scanner when returning from background or after navigating away
    if (state == AppLifecycleState.resumed &&
        (_lastLifecycleState == AppLifecycleState.paused ||
            _lastLifecycleState == AppLifecycleState.detached)) {
      _resetScan();
    }
    _lastLifecycleState = state;
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      unawaited(_controller?.pauseCamera() ?? Future.value());
      unawaited(
        Future.delayed(const Duration(milliseconds: 300), () {
          unawaited(_controller?.resumeCamera() ?? Future.value());
        }),
      );
    } else {
      unawaited(_controller?.resumeCamera() ?? Future.value());
    }
  }

  void _resetScan() {
    setState(() {
      _result = null;
      _hasNavigated = false;
    });
    context.read<QrValidationCubit>().reset();
    unawaited(_controller?.resumeCamera() ?? Future.value());
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
        _resetScan();
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.result.reason ?? 'QR code is not valid'),
              ),
            );
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
        backgroundColor: AppColors.blackColor,
        body: BlocBuilder<QrValidationCubit, QrValidationState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Full-screen camera ────────────────────────────────────
                QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  onPermissionSet: _onPermissionSet,
                  // Restrict to QR only — skipping EAN/PDF417/DataMatrix etc.
                  // cuts decoder time per frame by ~80%, making scanning near-instant.
                  formatsAllowed: const [BarcodeFormat.qrcode],
                  // No overlay — scanning works across the ENTIRE camera frame.
                ),

                // ── Scan frame + animated line ────────────────────────────
                _ScanFrameOverlay(scanLine: _scanLine),

                // ── Top bar: close + title ────────────────────────────────
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.whiteColor,
                              size: 22,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          const Expanded(
                            child: Text(
                              'Scan QR Code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Balance the back button
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Hint text below scan frame ────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 260), // clears the frame
                      Text(
                        _result != null
                            ? 'Validating...'
                            : 'Point camera at a QR code',
                        style: const TextStyle(
                          color: MaterialHues.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom controls ───────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _isFlashOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            label: 'Flash',
                            active: _isFlashOn,
                            onTap: () async {
                              setState(() => _isFlashOn = !_isFlashOn);
                              await _controller?.toggleFlash();
                            },
                          ),
                          _ControlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            label: 'Flip',
                            onTap: () async {
                              setState(() => _isFrontCamera = !_isFrontCamera);
                              await _controller?.flipCamera();
                            },
                          ),
                          _ControlButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Rescan',
                            onTap: _resetScan,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Loading overlay ───────────────────────────────────────
                if (state is QrValidationLoading)
                  Container(
                    color: AppColors.blackColor.withValues(alpha: 0.65),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.whiteColor),
                          SizedBox(height: 16),
                          Text(
                            'Validating QR code...',
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
      // Reset state when QRView is created/recreated
      _result = null;
      _hasNavigated = false;
    });

    // Reset cubit state
    context.read<QrValidationCubit>().reset();

    // Cancel previous subscription if exists
    _scanSubscription?.cancel();

    _scanSubscription = controller.scannedDataStream.listen((scanData) async {
      final raw = scanData.code?.trim();
      if (_result != null || raw == null || raw.isEmpty) return;

      setState(() => _result = scanData);
      unawaited(controller.pauseCamera());

      final token = _extractToken(raw);
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
        _resetScan();
        return;
      }

      if (!mounted) return;
      List<String> guardianChildCodes = [];
      try {
        final parentChildCubit = context.read<ParentChildCubit>();
        guardianChildCodes = parentChildCubit.children
            .map((c) => c.code)
            .toList();
      } catch (_) {}
      context.read<QrValidationCubit>().validate(
        qrToken: token,
        guardianChildCodes: guardianChildCodes,
      );
    });
  }

  String? _extractToken(String raw) {
    if (raw.startsWith('{')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return QrTokenExtractor.extractFromMap(map);
      } catch (_) {}
    }
    return raw.isNotEmpty ? raw : null;
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
    WidgetsBinding.instance.removeObserver(this);
    _scanAnim.dispose();
    _scanSubscription?.cancel();
    super.dispose();
  }
}

/// Draws four corner brackets and an animated horizontal scan line.
class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay({required this.scanLine});

  final Animation<double> scanLine;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: AnimatedBuilder(
          animation: scanLine,
          builder: (_, __) => CustomPaint(
            painter: _FramePainter(
              scanProgress: scanLine.value,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.scanProgress, required this.color});

  final double scanProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLen = 28.0;
    const r = 10.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, cornerLen), Offset(0, r), cornerPaint);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, r * 2, r * 2),
      3.14159,
      3.14159 / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(Offset(r, 0), Offset(cornerLen, 0), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w - r, 0), cornerPaint);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2),
      3.14159 * 1.5,
      3.14159 / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(Offset(w, r), Offset(w, cornerLen), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h - r), cornerPaint);
    canvas.drawArc(
      Rect.fromLTWH(0, h - r * 2, r * 2, r * 2),
      3.14159 / 2,
      3.14159 / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(Offset(r, h), Offset(cornerLen, h), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(w - cornerLen, h), Offset(w - r, h), cornerPaint);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2),
      0,
      3.14159 / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(Offset(w, h - r), Offset(w, h - cornerLen), cornerPaint);

    // Animated scan line
    final lineY = scanProgress * h;
    final linePaint = Paint()..color = color.withValues(alpha: 0.9);
    canvas.drawLine(
      Offset(8, lineY),
      Offset(w - 8, lineY),
      linePaint
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.scanProgress != scanProgress;
}

/// Circular icon + label button used in the bottom control bar.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.primaryColor.withValues(alpha: 0.25)
                  : AppColors.whiteColor.withValues(alpha: 0.15),
              border: Border.all(
                color: active
                    ? AppColors.primaryColor
                    : AppColors.whiteColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: active ? AppColors.primaryColor : AppColors.whiteColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.whiteColor.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
