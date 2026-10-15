import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wowcare/core/utils/qr_scanner.dart';

import 'fake_permission_platforms.dart';

/// Stands in for the native camera: tests push scans through [scan].
class _FakeCamera extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  int startCount = 0;

  void scan(String text) =>
      _barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: text)]));

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCount++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1080, 1920),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('tokenFrom', () {
    test('plain token → the token, trimmed', () {
      expect(QrScannerView.tokenFrom('  abc123 \n'), 'abc123');
    });

    test('JSON with qrToken → that field', () {
      expect(
        QrScannerView.tokenFrom('{"qrToken":" tok-1 ","school":"S1"}'),
        'tok-1',
      );
    });

    test('JSON with only the older qrPayload → that field', () {
      expect(QrScannerView.tokenFrom('{"qrPayload":"tok-2"}'), 'tok-2');
    });

    test('JSON without a token, broken JSON, or blank → null', () {
      expect(QrScannerView.tokenFrom('{"school":"S1"}'), isNull);
      expect(QrScannerView.tokenFrom('{"qrToken":""}'), isNull);
      expect(QrScannerView.tokenFrom('{not json'), isNull);
      expect(QrScannerView.tokenFrom('   '), isNull);
    });
  });

  group('QrScannerView', () {
    late _FakeCamera camera;
    late FakePermissionHandler permissions;
    late List<String> tokens;
    late GlobalKey<QrScannerViewState> key;

    setUp(() {
      MobileScannerController.resetPlatformSessionOwner();
      camera = _FakeCamera();
      MobileScannerPlatform.instance = camera;
      permissions = FakePermissionHandler()
        ..statuses[Permission.camera] = PermissionStatus.granted;
      PermissionHandlerPlatform.instance = permissions;
      tokens = [];
      key = GlobalKey<QrScannerViewState>();
    });

    Future<void> openScanner(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrScannerView(key: key, onScanned: tokens.add),
          ),
        ),
      );
      // Post-frame permission check, then the camera start.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('reads a code once, until rescan', (tester) async {
      await openScanner(tester);
      expect(camera.startCount, 1);

      camera
        ..scan('tok-1')
        ..scan('tok-1'); // still in front of the camera
      await tester.pump();
      expect(tokens, ['tok-1']);

      key.currentState!.rescan();
      await tester.pump();
      camera.scan('tok-2');
      await tester.pump();
      expect(tokens, ['tok-1', 'tok-2']);
    });

    testWidgets('unreadable code → "Invalid QR code", then scans again', (
      tester,
    ) async {
      await openScanner(tester);

      camera.scan('{"school":"S1"}');
      await tester.pump();
      expect(find.text('Invalid QR code'), findsOneWidget);
      expect(tokens, isEmpty);

      await tester.pump(const Duration(seconds: 2));
      camera.scan('tok-1');
      await tester.pump();
      expect(tokens, ['tok-1']);
      // Let the top banner's auto-dismiss timer run out.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('no camera permission → message, camera never starts', (
      tester,
    ) async {
      permissions
        ..statuses[Permission.camera] = PermissionStatus.permanentlyDenied;
      await openScanner(tester);
      // Dismiss the Settings-steps sheet PermissionManager shows.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Camera access is needed to scan the QR code.'),
        findsOneWidget,
      );
      expect(camera.startCount, 0);
    });
  });
}
