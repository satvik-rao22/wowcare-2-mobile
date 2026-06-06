import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Isolated QR code section with RepaintBoundary optimization.
/// Prevents QR widget from rebuilding when parent state changes.
class KioskQrSectionWidget extends StatelessWidget {
  const KioskQrSectionWidget({
    required this.state,
    required this.schoolName,
    super.key,
  });

  final KioskDashboardState state;
  final String schoolName;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildQrSectionContent(context),
    );
  }

  Widget _buildQrSectionContent(BuildContext context) {
    if (state is KioskDashboardLoading) {
      return _buildLoadingState();
    }

    if (state is KioskDashboardError) {
      return _buildErrorState(state as KioskDashboardError);
    }

    if (state is KioskDashboardQrLoaded) {
      return _buildQrLoadedState(state as KioskDashboardQrLoaded);
    }

    if (state is KioskDashboardPinValidating) {
      final pinValidatingState = state as KioskDashboardPinValidating;
      if (pinValidatingState.qrCode != null &&
          pinValidatingState.schoolName != null) {
        return _buildQrWithSchoolName(
          pinValidatingState.schoolName!,
          pinValidatingState.qrCode!.qrPayload,
        );
      }
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('Loading QR Code...', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState(KioskDashboardError errorState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: _buildQrUnavailable('QR not generated', null),
        ),
        const SizedBox(height: 20),
        Text(
          errorState.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildQrLoadedState(KioskDashboardQrLoaded loadedState) {
    return _buildQrWithSchoolName(
      loadedState.schoolName,
      loadedState.qrCode.qrPayload,
    );
  }

  Widget _buildQrWithSchoolName(String schoolNameText, String qrPayload) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          schoolNameText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Scan the QR Code',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: _buildQrImage(qrPayload),
        ),
      ],
    );
  }

  Widget _buildQrImage(String qrPayload) {
    try {
      if (qrPayload.trim().isEmpty) {
        AppLogger.d('[Kiosk] QR payload is empty');
        return _buildQrUnavailable('QR Code data is empty', null);
      }

      AppLogger.d(
        '[Kiosk] Rendering QR code from payload: ${qrPayload.length} chars',
      );

      return RepaintBoundary(
        child: QrImageView(
          data: qrPayload,
          version: QrVersions.auto,
          size: 220,
          gapless: false,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          errorStateBuilder: (context, error) {
            AppLogger.d('[Kiosk] QR generation failed: $error');
            return _buildQrUnavailable('Failed to generate QR', null);
          },
        ),
      );
    } catch (e) {
      AppLogger.e('[Kiosk] Unexpected QR error: $e');
      return _buildQrUnavailable('Failed to load QR code', null);
    }
  }

  Widget _buildQrUnavailable(String reason, BuildContext? context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (context != null)
            IconButton(
              onPressed: () {
                // ignore: unawaited_futures
                BlocProvider.of<KioskDashboardCubit>(context).loadQrCode();
              },
              icon: const Icon(Icons.refresh, size: 32, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
