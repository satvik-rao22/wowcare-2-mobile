import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/permission_manager.dart';

/// The one QR scanner in the app: a full-screen camera with the scan frame,
/// a back button and Flash / Flip / Rescan controls.
///
/// Drop it into a screen and handle the token:
///
/// ```dart
/// final _scanner = GlobalKey<QrScannerViewState>();
///
/// QrScannerView(
///   key: _scanner,
///   onScanned: (token) => cubit.validate(qrToken: token),
/// );
///
/// // After a failed check, scan again:
/// _scanner.currentState?.rescan();
/// ```
///
/// It handles everything about scanning, so callers don't:
/// - camera permission (via PermissionManager, with Settings steps when
///   it's blocked),
/// - pausing the camera while the app is in the background,
/// - reading QR codes only, anywhere in the camera frame,
/// - reading each code once: after [onScanned] fires, the camera stays
///   paused until [QrScannerViewState.rescan],
/// - turning the scanned text into a token ([tokenFrom]); unreadable codes
///   show "Invalid QR code" and scanning carries on.
///
/// The mobile_scanner plugin stays inside this file, so upgrading or swapping
/// it changes nothing at the call sites.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onScanned,
    this.title = 'Scan QR Code',
    this.hint = 'Point camera at a QR code',
  });

  /// Called once per scan with the token from the QR code.
  final ValueChanged<String> onScanned;

  final String title;
  final String hint;

  /// The token inside a scanned QR code, or null if there isn't one.
  ///
  /// Our QR codes hold either the plain token or JSON with a `qrToken`
  /// (or older `qrPayload`) field.
  static String? tokenFrom(String scannedText) {
    final text = scannedText.trim();
    if (text.isEmpty) return null;
    if (!text.startsWith('{')) return text;
    try {
      final json = jsonDecode(text);
      if (json is! Map) return null;
      final token = (json['qrToken'] ?? json['qrPayload'])?.toString().trim();
      return (token == null || token.isEmpty) ? null : token;
    } on FormatException {
      return null;
    }
  }

  @override
  State<QrScannerView> createState() => QrScannerViewState();
}

class QrScannerViewState extends State<QrScannerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );

  late final AnimationController _scanLine;

  bool _hasPermission = false;

  /// True from a successful read until [rescan]: the camera stays paused so
  /// the same code isn't read again while the caller handles it.
  bool _scanned = false;

  /// Starts scanning again after [QrScannerView.onScanned] fired.
  void rescan() {
    if (!mounted) return;
    _scanned = false;
    _startCamera();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Created here, not lazily: without camera access the frame is never
    // drawn, and dispose() would then be the first to touch it.
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // ensure() may show a sheet, so wait for the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForCamera());
  }

  Future<void> _askForCamera() async {
    final allowed = await PermissionManager.ensure(
      context,
      AppPermission.camera,
      reason: 'to scan the QR code',
    );
    if (!mounted) return;
    setState(() => _hasPermission = allowed);
    _startCamera();
  }

  void _startCamera() {
    if (!_hasPermission || _scanned || !mounted) return;
    unawaited(_controller.start());
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final text = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
    if (text == null) return;

    _scanned = true;
    unawaited(_controller.pause());

    final token = QrScannerView.tokenFrom(text);
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
      // A pause first, or the same code — still in front of the camera —
      // is read again straight away.
      Future.delayed(const Duration(seconds: 2), rescan);
      return;
    }
    widget.onScanned(token);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        unawaited(_controller.stop());
      case AppLifecycleState.resumed:
        // Camera access may have been turned on in Settings meanwhile.
        if (_hasPermission) {
          _startCamera();
        } else {
          unawaited(_recheckPermission());
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
    }
  }

  Future<void> _recheckPermission() async {
    final allowed = await PermissionManager.isGranted(AppPermission.camera);
    if (!allowed || !mounted) return;
    setState(() => _hasPermission = true);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasPermission)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _Message(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Camera access is needed to scan the QR code.'
                    : "The camera couldn't start. Please try again.",
              ),
            )
          else
            _Message(
              'Camera access is needed to scan the QR code.',
              action: TextButton(
                onPressed: _askForCamera,
                child: const Text('Allow camera'),
              ),
            ),

          if (_hasPermission) ...[
            Center(
              child: SizedBox.square(
                dimension: 240,
                child: AnimatedBuilder(
                  animation: _scanLine,
                  builder: (_, __) => CustomPaint(
                    painter: _FramePainter(
                      scanProgress: Curves.easeInOut.transform(_scanLine.value),
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 260), // below the frame
                child: Text(
                  widget.hint,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],

          // ── Top bar: back + title ──
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balances the back button
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ──
          if (_hasPermission)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (_, camera, __) {
                      final torchOn = camera.torchState == TorchState.on;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            label: 'Flash',
                            active: torchOn,
                            onTap: camera.torchState == TorchState.unavailable
                                ? null
                                : _controller.toggleTorch,
                          ),
                          _ControlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            label: 'Flip',
                            onTap: _controller.switchCamera,
                          ),
                          _ControlButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Rescan',
                            onTap: rescan,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Centred white text (and an optional button) over the black background.
class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// Four rounded corner brackets and a moving horizontal scan line.
class _FramePainter extends CustomPainter {
  const _FramePainter({required this.scanProgress, required this.color});

  final double scanProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final corner = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const length = 28.0;
    const r = 10.0;
    const quarter = 3.14159 / 2;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(const Offset(0, length), const Offset(0, r), corner);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, r * 2, r * 2),
      quarter * 2,
      quarter,
      false,
      corner,
    );
    canvas.drawLine(const Offset(r, 0), const Offset(length, 0), corner);

    // Top-right
    canvas.drawLine(Offset(w - length, 0), Offset(w - r, 0), corner);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2),
      quarter * 3,
      quarter,
      false,
      corner,
    );
    canvas.drawLine(Offset(w, r), Offset(w, length), corner);

    // Bottom-left
    canvas.drawLine(Offset(0, h - length), Offset(0, h - r), corner);
    canvas.drawArc(
      Rect.fromLTWH(0, h - r * 2, r * 2, r * 2),
      quarter,
      quarter,
      false,
      corner,
    );
    canvas.drawLine(Offset(r, h), Offset(length, h), corner);

    // Bottom-right
    canvas.drawLine(Offset(w - length, h), Offset(w - r, h), corner);
    canvas.drawArc(
      Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2),
      0,
      quarter,
      false,
      corner,
    );
    canvas.drawLine(Offset(w, h - r), Offset(w, h - length), corner);

    // Scan line
    final y = scanProgress * h;
    canvas.drawLine(
      Offset(8, y),
      Offset(w - 8, y),
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, y - 1, w, 2))
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.scanProgress != scanProgress;
}

/// Round icon button with a label, for the bottom control bar.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;

  /// Null shows the button dimmed and ignores taps.
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryColor : Colors.white;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
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
                    : Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: active
                      ? AppColors.primaryColor
                      : Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
