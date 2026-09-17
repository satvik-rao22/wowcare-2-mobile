import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import '../models/ledger_transaction_models.dart';

abstract class LedgerTransactionRemoteDataSource {
  Future<LedgerTransactionPageModel> getTransactions({
    required String ledgerCode,
    String? from,
    String? to,
    int page = 0,
    int size = 10,
  });

  Future<void> addTransaction(AddTransactionRequestModel request);
}

class LedgerTransactionRemoteDataSourceImpl
    implements LedgerTransactionRemoteDataSource {
  LedgerTransactionRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<LedgerTransactionPageModel> getTransactions({
    required String ledgerCode,
    String? from,
    String? to,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (from != null) 'dateFrom': from,
      if (to != null) 'dateTo': to,
    };

    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.ledgerEntries(ledgerCode)),
      queryParameters: params,
    );

    return LedgerTransactionPageModel.fromJson(response.data ?? {});
  }

  @override
  Future<void> addTransaction(AddTransactionRequestModel request) async {
    await _client.post<void>(
      ApiPaths.url(ApiPaths.ledgerEntries(request.ledgerCode)),
      data: request.toJson(),
    );
  }
}
