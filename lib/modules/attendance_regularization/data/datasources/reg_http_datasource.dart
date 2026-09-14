import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';

import 'reg_api_paths.dart';
import 'reg_remote_datasource.dart';

/// Real HTTP implementation, built on the host app's Dio.
///
/// Constructed with `sl<ApiClient>().client`, so the auth,
/// `X-Organization-Code` / `X-School-Code` and logging interceptors all apply
/// automatically — the same arrangement `StaffOvertimeRemoteDataSource` uses.
///
/// Deliberately dumb: it builds a URL, posts a body it was handed, and returns
/// the response map. Timezone conversion lives in the repository, payload
/// shaping in `RegMappers`, so this class has nothing to get wrong.
class RegHttpDataSource implements RegRemoteDataSource {
  RegHttpDataSource(this._client);

  final Dio _client;

  String _url(String path) =>
      ApiPaths.urlWithBase(path, ApiConstants.attendanceBaseUrl);

  /// Normalises any successful response to a map, so callers never have to
  /// null-check the transport layer.
  Map<String, dynamic> _asMap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    // A bare list (no envelope) still has to reach the mappers, which know how
    // to read both shapes.
    if (data is List) return <String, dynamic>{'data': data};
    return const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getOpenSessions({
    required String staffCode,
  }) async {
    final response = await _client.get<dynamic>(
      _url(RegApiPaths.openSessions),
      queryParameters: <String, dynamic>{'staffCode': staffCode},
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> getOpenSessionsBatch({
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post<dynamic>(
      _url(RegApiPaths.openSessionsBatch),
      data: body,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> raise({
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post<dynamic>(
      _url(RegApiPaths.raise),
      data: body,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> raiseBatch({
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post<dynamic>(
      _url(RegApiPaths.raiseBatch),
      data: body,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> edit({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch<dynamic>(
      _url(RegApiPaths.edit(code)),
      data: body,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> list({
    required Map<String, dynamic> query,
  }) async {
    final response = await _client.get<dynamic>(
      _url(RegApiPaths.list),
      queryParameters: query,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> approve({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post<dynamic>(
      _url(RegApiPaths.approve(code)),
      data: body,
    );
    return _asMap(response);
  }

  @override
  Future<Map<String, dynamic>> approveSelected({
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post<dynamic>(
      _url(RegApiPaths.approveSelected),
      data: body,
    );
    return _asMap(response);
  }
}
