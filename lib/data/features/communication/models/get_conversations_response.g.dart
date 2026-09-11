// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_conversations_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetConversationsResponse _$GetConversationsResponseFromJson(
        Map<String, dynamic> json) =>
    GetConversationsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] == null
          ? null
          : ConversationsData.fromJson(json['data'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as String? ?? '',
      correlationId: json['correlationId'] as String?,
    );

ConversationsData _$ConversationsDataFromJson(Map<String, dynamic> json) =>
    ConversationsData(
      content: (json['content'] as List<dynamic>?)
              ?.map(
                  (e) => ConversationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
    );
