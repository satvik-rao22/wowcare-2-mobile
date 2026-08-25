import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/billing_statement_model.dart';

abstract class BillingStatementsRemoteDataSource {
  Future<List<BillingStatementModel>> getStatements({
    required String subscriberCode,
  });

  Future<Uint8List> downloadStatement({required String statementCode});

  Future<BillingStatementModel> generateStatement({
    required String organizationCode,
    required String schoolCode,
    required String ownerType,
    required String subscriberCode,
    required String statementType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool includeDescription,
  });
}

class BillingStatementsRemoteDataSourceImpl
    implements BillingStatementsRemoteDataSource {
  BillingStatementsRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<List<BillingStatementModel>> getStatements({
    required String subscriberCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.billingStatements),
      queryParameters: {'subscriberCode': subscriberCode},
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .map((e) => BillingStatementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Uint8List> downloadStatement({required String statementCode}) async {
    final response = await _client.get<List<int>>(
      ApiPaths.url(ApiPaths.billingStatementDownload(statementCode)),
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Statement PDF download returned no data');
    }
    return Uint8List.fromList(response.data!);
  }

  @override
  Future<BillingStatementModel> generateStatement({
    required String organizationCode,
    required String schoolCode,
    required String ownerType,
    required String subscriberCode,
    required String statementType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool includeDescription,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.billingStatements),
      data: {
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'ownerType': ownerType,
        'subscriberCode': subscriberCode,
        'statementType': statementType,
        'periodStart': periodStart.toUtc().toIso8601String(),
        'periodEnd': periodEnd.toUtc().toIso8601String(),
        'includeDescription': includeDescription,
      },
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response from generate statement API');
    }
    return BillingStatementModel.fromJson(data);
  }
}
