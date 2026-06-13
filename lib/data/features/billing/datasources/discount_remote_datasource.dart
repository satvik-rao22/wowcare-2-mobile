import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/billing/models/discount_models.dart';

abstract class DiscountRemoteDataSource {
  Future<DiscountPageModel> getDiscounts({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 10,
  });

  Future<DiscountModel> createDiscount(DiscountRequestModel request);

  Future<DiscountModel> updateDiscount({
    required String code,
    required DiscountRequestModel request,
  });

  Future<void> deleteDiscount(String code);
  Future<void> deactivateDiscount(String code);
  Future<void> reactivateDiscount(String code);
}

class DiscountRemoteDataSourceImpl implements DiscountRemoteDataSource {
  DiscountRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<DiscountPageModel> getDiscounts({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.discounts),
      queryParameters: <String, dynamic>{
        'criteria.school': school,
        'pageable.page': page,
        'pageable.size': size,
        if (name != null && name.isNotEmpty) 'criteria.name': name,
        if (status != null) 'criteria.status': status,
      },
    );
    return DiscountPageModel.fromJson(response.data ?? {});
  }

  @override
  Future<DiscountModel> createDiscount(DiscountRequestModel request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.discounts),
      data: request.toJson(),
    );
    final data =
        (response.data?['data'] as Map<String, dynamic>?) ?? response.data ?? {};
    return DiscountModel.fromJson(data);
  }

  @override
  Future<DiscountModel> updateDiscount({
    required String code,
    required DiscountRequestModel request,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.discountByCode(code)),
      data: request.toJson(),
    );
    final data =
        (response.data?['data'] as Map<String, dynamic>?) ?? response.data ?? {};
    return DiscountModel.fromJson(data);
  }

  @override
  Future<void> deleteDiscount(String code) async {
    await _client.delete<void>(ApiPaths.url(ApiPaths.discountByCode(code)));
  }

  @override
  Future<void> deactivateDiscount(String code) async {
    await _client.post<void>(
        ApiPaths.url(ApiPaths.discountDeactivate(code)));
  }

  @override
  Future<void> reactivateDiscount(String code) async {
    await _client.post<void>(
        ApiPaths.url(ApiPaths.discountReactivate(code)));
  }
}
