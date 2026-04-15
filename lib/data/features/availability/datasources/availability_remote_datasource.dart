import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';

import '../models/future_availability_models.dart';
import '../models/individual_movement_models.dart';

abstract class AvailabilityRemoteDataSource {
  Future<IndividualMovementBoardModel> getIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  });

  Future<String> transitionIndividualMovementStatus({
    required int id,
    required String status,
    String? comment,
    DateTime? newMovementDate,
  });

  Future<String> createIndividualMovement({
    required String schoolCode,
    required String organizationCode,
    required String studentCode,
    required String movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  });

  Future<String> updateIndividualMovement({
    required int id,
    required String movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  });

  Future<String> deleteIndividualMovement({
    required int id,
  });

  Future<IndividualMovementModel> getIndividualMovementById({
    required int id,
  });

  Future<FutureAvailabilityGridModel> getFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required String shift,
  });
}

class AvailabilityRemoteDataSourceImpl implements AvailabilityRemoteDataSource {
  AvailabilityRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<IndividualMovementBoardModel> getIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
    };

    final cleanedStudentCodes = _cleanList(studentCodes);
    final cleanedFromClassroomCodes = _cleanList(fromClassroomCodes);
    final cleanedToClassroomCodes = _cleanList(toClassroomCodes);
    final cleanedStatus = _cleanList(status)?.map((e) => e.toUpperCase()).toList();

    if (cleanedStudentCodes != null && cleanedStudentCodes.isNotEmpty) {
      queryParameters['studentCodes'] = cleanedStudentCodes;
    }
    if (cleanedFromClassroomCodes != null && cleanedFromClassroomCodes.isNotEmpty) {
      queryParameters['fromClassroomCodes'] = cleanedFromClassroomCodes;
    }
    if (cleanedToClassroomCodes != null && cleanedToClassroomCodes.isNotEmpty) {
      queryParameters['toClassroomCodes'] = cleanedToClassroomCodes;
    }
    if (dateFrom != null) {
      queryParameters['dateFrom'] = _formatDateOnly(dateFrom);
    }
    if (dateTo != null) {
      queryParameters['dateTo'] = _formatDateOnly(dateTo);
    }
    if (cleanedStatus != null && cleanedStatus.isNotEmpty) {
      queryParameters['status'] = cleanedStatus;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovements,
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected individual movements API response format');
    }

    return IndividualMovementBoardModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<String> transitionIndividualMovementStatus({
    required int id,
    required String status,
    String? comment,
    DateTime? newMovementDate,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovementStatusById(id),
      ApiConstants.classroomBaseUrl,
    );

    final requestBody = <String, dynamic>{
      'status': status.trim().toUpperCase(),
      if (comment != null) 'comment': comment,
      if (newMovementDate != null) 'newMovementDate': _formatDateOnly(newMovementDate),
    };

    final response = await _client.patch<dynamic>(
      endpoint,
      data: requestBody,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected movement status transition API response format');
    }

    final payload = response.data! as Map<String, dynamic>;
    return payload['message']?.toString().trim().isNotEmpty == true
        ? payload['message'].toString()
        : 'Movement status updated successfully';
  }

  @override
  Future<String> createIndividualMovement({
    required String schoolCode,
    required String organizationCode,
    required String studentCode,
    required String movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovements,
      ApiConstants.classroomBaseUrl,
    );

    final requestBody = <String, dynamic>{
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'studentCode': studentCode,
      'movementType': movementType.trim().toUpperCase(),
      'fromClassroomCode': fromClassroomCode,
      'toClassroomCode': toClassroomCode,
      'movementDate': _formatDateOnly(movementDate),
      'comment': comment ?? '',
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: requestBody,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected create individual movement API response format');
    }

    final payload = response.data! as Map<String, dynamic>;
    return payload['message']?.toString().trim().isNotEmpty == true
        ? payload['message'].toString()
        : 'Movement created successfully';
  }

  @override
  Future<String> updateIndividualMovement({
    required int id,
    required String movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovementById(id),
      ApiConstants.classroomBaseUrl,
    );

    final requestBody = <String, dynamic>{
      'movementType': movementType.trim().toUpperCase(),
      'fromClassroomCode': fromClassroomCode,
      'toClassroomCode': toClassroomCode,
      'movementDate': _formatDateOnly(movementDate),
      'comment': comment ?? '',
    };

    final response = await _client.put<dynamic>(
      endpoint,
      data: requestBody,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected update individual movement API response format');
    }

    final payload = response.data! as Map<String, dynamic>;
    return payload['message']?.toString().trim().isNotEmpty == true
        ? payload['message'].toString()
        : 'Movement updated successfully';
  }

  @override
  Future<IndividualMovementModel> getIndividualMovementById({
    required int id,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovementById(id),
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected movement by id API response format');
    }

    final payload = response.data! as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data field in movement by id response');
    }

    return IndividualMovementModel.fromJson(data);
  }

  @override
  Future<String> deleteIndividualMovement({
    required int id,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.individualMovementById(id),
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected delete individual movement API response format');
    }

    final payload = response.data! as Map<String, dynamic>;
    return payload['message']?.toString().trim().isNotEmpty == true
        ? payload['message'].toString()
        : 'Movement deleted successfully';
  }

  @override
  Future<FutureAvailabilityGridModel> getFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required String shift,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.futureAvailability,
      ApiConstants.classroomBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'startDate': _formatDateOnly(startDate),
      'endDate': _formatDateOnly(endDate),
      'shift': shift.trim().toUpperCase(),
    };

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected future availability API response format');
    }

    return FutureAvailabilityGridModel.fromJson(response.data! as Map<String, dynamic>);
  }
}

List<String>? _cleanList(List<String>? values) {
  if (values == null) return null;
  return values.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
