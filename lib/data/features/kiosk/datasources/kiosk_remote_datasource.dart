import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/data/features/kiosk/models/kiosk_qr_model.dart';

abstract class KioskRemoteDataSource {
  /// Fetch the active QR code for a given school from the attendance API.
  /// Uses: GET /api/v1/attendance/schools/{schoolCode}/attendance-settings/qr-code/active
  Future<KioskQrModel> getActiveQrCode({required String schoolCode});
}

class KioskRemoteDataSourceImpl implements KioskRemoteDataSource {
  const KioskRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<KioskQrModel> getActiveQrCode({required String schoolCode}) async {
    final url =
        '${ApiConstants.attendanceBaseUrl}/api/v1/attendance/schools/$schoolCode/attendance-settings/qr-code/active';

    try {
      final response = await _client.get<Map<String, dynamic>>(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
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
}
