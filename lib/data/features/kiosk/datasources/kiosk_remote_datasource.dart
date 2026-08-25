import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/data/features/kiosk/models/kiosk_qr_model.dart';
import 'package:wowcare/data/features/kiosk/models/kiosk_pin_result_model.dart';

/// Remote data source for LEGACY kiosk QR and PIN features.
///
/// This datasource handles:
/// - QR code retrieval for the kiosk dashboard
/// - PIN verification for staff/guardian authentication
///
/// NOTE: For the NEW refactored attendance API integration, see KioskAttendanceRemoteDataSource.
abstract class KioskRemoteDataSource {
  /// Fetch the active QR code for a given school from the attendance API.
  /// Uses: GET /api/v1/schools/{schoolCode}/attendance-settings/qr-code/active
  Future<KioskQrModel> getActiveQrCode({required String schoolCode});

  /// Verify a 4-digit PIN and get guardian/staff details and student status.
  /// Uses: POST /api/v1/attendance/kiosk/verify-pin
  /// Body: {"pin": int, "isLogout": true (optional)}
  /// School code is passed via X-School-Code header.
  /// When isLogout=true, the API will process this as a logout confirmation for the kiosk user.
  Future<KioskPinResultModel> verifyPin({
    required String pin,
    required String schoolCode,
    bool isLogout = false,
  });
}

class KioskRemoteDataSourceImpl implements KioskRemoteDataSource {
  const KioskRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<KioskQrModel> getActiveQrCode({required String schoolCode}) async {
    final url = ApiConstants.qrCodeActiveEndpoint(schoolCode);

    try {
      final response = await _client.get<Map<String, dynamic>>(
        url,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to fetch QR code: ${response.statusCode}');
      }

      // Handle nested response with 'data' field
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      final qrData = data['data'] as Map<String, dynamic>?;
      if (qrData == null) {
        throw Exception('No QR data in response');
      }

      return KioskQrModel.fromJson(qrData);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<KioskPinResultModel> verifyPin({
    required String pin,
    required String schoolCode,
    bool isLogout = false,
  }) async {
    final url = ApiConstants.kioskVerifyPinEndpoint;

    try {
      final requestBody = {'pin': pin, if (isLogout) 'isLogout': true};

      final response = await _client.post<Map<String, dynamic>>(
        url,
        data: requestBody,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-School-Code': schoolCode,
          },
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to verify PIN: ${response.statusCode}');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      // Handle nested response with 'data' field
      final pinData = data['data'] as Map<String, dynamic>?;
      if (pinData == null) {
        throw Exception('No PIN verification data in response');
      }

      return KioskPinResultModel.fromJson(pinData);
    } catch (e) {
      rethrow;
    }
  }
}
