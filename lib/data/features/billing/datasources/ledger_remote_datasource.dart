import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import '../models/ledger_models.dart';

abstract class LedgerRemoteDataSource {
  Future<LedgerPageModel> getLedgers({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 10,
  });

  Future<LedgerModel> createLedger(LedgerRequestModel request);

  Future<LedgerModel> getLedgerByCode(String ledgerCode);

  Future<void> deleteLedger(String ledgerCode);

  Future<LedgerModel> updateLedger({
    required String ledgerCode,
    required LedgerRequestModel request,
  });

  Future<void> deactivateLedger(String ledgerCode);
  Future<void> reactivateLedger(String ledgerCode);
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  LedgerRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<LedgerPageModel> getLedgers({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'organizationCode': organizationCode,
      'school': school,
      'page': page,
      'size': size,
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    };

    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.ledgers),
      queryParameters: queryParams,
    );

    return LedgerPageModel.fromJson(response.data ?? {});
  }

  @override
  Future<LedgerModel> createLedger(LedgerRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.ledgers),
      data: request.toJson(),
    );

    final data = (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
    return LedgerModel.fromJson(data);
  }

  @override
  Future<LedgerModel> getLedgerByCode(String ledgerCode) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.ledgerByCode(ledgerCode)),
    );

    final data = (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
    return LedgerModel.fromJson(data);
  }

  @override
  Future<void> deleteLedger(String ledgerCode) async {
    await _client.delete<void>(
      ApiPaths.url(ApiPaths.ledgerByCode(ledgerCode)),
    );
  }

  @override
  Future<LedgerModel> updateLedger({
    required String ledgerCode,
    required LedgerRequestModel request,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.ledgerByCode(ledgerCode)),
      data: request.toJson(),
    );

    final data = (response.data?['data'] as Map<String, dynamic>?) ??
        response.data ??
        {};
    return LedgerModel.fromJson(data);
  }

  @override
  Future<void> deactivateLedger(String ledgerCode) async {
    await _client.post<void>(
      ApiPaths.url(ApiPaths.ledgerDeactivate(ledgerCode)),
    );
  }

  @override
  Future<void> reactivateLedger(String ledgerCode) async {
    await _client.post<void>(
      ApiPaths.url(ApiPaths.ledgerReactivate(ledgerCode)),
    );
  }
}
