import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/data/features/billing/models/invoice_catalog_models.dart';

/// Remote datasource for the Create Invoice catalog lookups: fee structures
/// (tuition), other fees, and subsidies. Uses plain `school`/`status`/`page`/
/// `size` query params (matching the live UAT requests).
abstract class InvoiceCatalogRemoteDataSource {
  Future<List<FeeStructureModel>> getFeeStructures({
    required String school,
    String? status,
    int page,
    int size,
  });

  Future<List<OtherFeeModel>> getOtherFees({
    required String school,
    String? status,
    int page,
    int size,
  });

  Future<List<SubsidyModel>> getSubsidies({
    required String school,
    String? status,
    int page,
    int size,
  });
}

class InvoiceCatalogRemoteDataSourceImpl
    implements InvoiceCatalogRemoteDataSource {
  InvoiceCatalogRemoteDataSourceImpl(this._client);

  final Dio _client;

  Map<String, dynamic> _query({
    required String school,
    String? status,
    required int page,
    required int size,
  }) =>
      <String, dynamic>{
        'school': school,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'size': size,
      };

  @override
  Future<List<FeeStructureModel>> getFeeStructures({
    required String school,
    String? status,
    int page = 0,
    int size = 200,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.feeStructures),
      queryParameters: _query(
          school: school, status: status, page: page, size: size),
    );
    return parseCatalogContent(response.data ?? {}, FeeStructureModel.fromJson);
  }

  @override
  Future<List<OtherFeeModel>> getOtherFees({
    required String school,
    String? status,
    int page = 0,
    int size = 200,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.otherFees),
      queryParameters: _query(
          school: school, status: status, page: page, size: size),
    );
    return parseCatalogContent(response.data ?? {}, OtherFeeModel.fromJson);
  }

  @override
  Future<List<SubsidyModel>> getSubsidies({
    required String school,
    String? status,
    int page = 0,
    int size = 200,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.subsidies),
      queryParameters: _query(
          school: school, status: status, page: page, size: size),
    );
    return parseCatalogContent(response.data ?? {}, SubsidyModel.fromJson);
  }
}
