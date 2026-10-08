import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';

import 'reg_api_paths.dart';

/// The seven endpoints over the host's Dio, so auth and the tenant headers
/// apply automatically.
///
/// Returns raw response bodies; shaping lives in `RegMappers`.
class RegRemoteDataSource {
  RegRemoteDataSource(this._client);

  final Dio _client;

  String _url(String path) =>
      ApiPaths.urlWithBase(path, ApiConstants.attendanceBaseUrl);

  Map<String, dynamic> _asMap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return <String, dynamic>{'data': data};
    return const <String, dynamic>{};
  }

  /// `{}` checks the caller; `{staffCodes:[…]}` checks a roster.
  Future<Map<String, dynamic>> checkGate(Map<String, dynamic> body) async {
    return _asMap(
      await _client.post<dynamic>(
        _url(RegApiPaths.openSessionsCheck),
        data: body,
      ),
    );
  }

  Future<Map<String, dynamic>> raise(Map<String, dynamic> body) async {
    return _asMap(
      await _client.post<dynamic>(_url(RegApiPaths.raise), data: body),
    );
  }

  Future<Map<String, dynamic>> raiseBatch(Map<String, dynamic> body) async {
    return _asMap(
      await _client.post<dynamic>(_url(RegApiPaths.raiseBatch), data: body),
    );
  }

  Future<Map<String, dynamic>> list(Map<String, dynamic> query) async {
    return _asMap(
      await _client.get<dynamic>(
        _url(RegApiPaths.list),
        queryParameters: query,
      ),
    );
  }

  Future<Map<String, dynamic>> approve(
    String code,
    Map<String, dynamic> body,
  ) async {
    return _asMap(
      await _client.post<dynamic>(_url(RegApiPaths.approve(code)), data: body),
    );
  }

  Future<Map<String, dynamic>> approveSelected(
    Map<String, dynamic> body,
  ) async {
    return _asMap(
      await _client.post<dynamic>(
        _url(RegApiPaths.approveSelected),
        data: body,
      ),
    );
  }

  Future<Map<String, dynamic>> edit(
    String code,
    Map<String, dynamic> body,
  ) async {
    return _asMap(
      await _client.patch<dynamic>(_url(RegApiPaths.edit(code)), data: body),
    );
  }
}
