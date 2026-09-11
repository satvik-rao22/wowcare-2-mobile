// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_document_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDocumentResponseModel _$StudentDocumentResponseModelFromJson(
        Map<String, dynamic> json) =>
    StudentDocumentResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String? ?? '',
    );
