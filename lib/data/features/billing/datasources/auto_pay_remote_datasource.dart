import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/billing/models/auto_pay_models.dart';

abstract class AutoPayRemoteDataSource {
  Future<SchoolForteConfigModel?> getSchoolForteConfig({
    required String organizationCode,
    required String schoolCode,
  });
  Future<AutoPayStatusModel> getAutoPayStatus({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  });
  Future<AutoPayStatusModel> setAutoPayStatus({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
    required bool autopayEnabled,
  });
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  });
  Future<PaymentMethodModel> addPaymentMethod(
      AddPaymentMethodRequestModel request);
  Future<PaymentMethodModel> setPrimaryPaymentMethod({
    required String paymentMethodCode,
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  });
  Future<void> deletePaymentMethod({
    required String paymentMethodCode,
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  });
}

class AutoPayRemoteDataSourceImpl implements AutoPayRemoteDataSource {
  AutoPayRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<SchoolForteConfigModel?> getSchoolForteConfig({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.schoolForteConfigs),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'page': 0,
        'size': 1,
      },
    );
    final data = response.data?['data'];
    final content = data is Map<String, dynamic> ? data['content'] : null;
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map<String, dynamic>) {
        return SchoolForteConfigModel.fromJson(first);
      }
    }
    return null;
  }

  @override
  Future<AutoPayStatusModel> getAutoPayStatus({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.autopayStatus),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
      },
    );
    final data = response.data?['data'];
    return AutoPayStatusModel.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @override
  Future<AutoPayStatusModel> setAutoPayStatus({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
    required bool autopayEnabled,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.autopayStatus),
      data: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
        'autopayEnabled': autopayEnabled,
      },
    );
    final data = response.data?['data'];
    return AutoPayStatusModel.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.paymentGatewayMethods),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
      },
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodModel.fromJson)
          .toList();
    }
    return const <PaymentMethodModel>[];
  }

  @override
  Future<PaymentMethodModel> addPaymentMethod(
      AddPaymentMethodRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.paymentGatewayMethods),
      data: request.toJson(),
    );
    final data = response.data?['data'];
    return PaymentMethodModel.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @override
  Future<PaymentMethodModel> setPrimaryPaymentMethod({
    required String paymentMethodCode,
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.paymentGatewayMethodPrimary(paymentMethodCode)),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
      },
    );
    final data = response.data?['data'];
    return PaymentMethodModel.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @override
  Future<void> deletePaymentMethod({
    required String paymentMethodCode,
    required String organizationCode,
    required String schoolCode,
    required String guardianCode,
  }) async {
    await _client.delete<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.paymentGatewayMethodByCode(paymentMethodCode)),
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'guardianCode': guardianCode,
      },
    );
  }
}
