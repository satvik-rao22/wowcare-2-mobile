import 'package:equatable/equatable.dart';
import 'conversation_model.dart';

class GetConversationsResponse extends Equatable {
  final bool success;
  final String message;
  final ConversationsData? data;
  final String timestamp;
  final String? correlationId;

  const GetConversationsResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.correlationId,
  });

  factory GetConversationsResponse.fromJson(Map<String, dynamic> json) {
    return GetConversationsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? ConversationsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String? ?? '',
      correlationId: json['correlationId'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, message, data, timestamp, correlationId];
}

class ConversationsData extends Equatable {
  final List<ConversationModel> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final bool empty;

  const ConversationsData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory ConversationsData.fromJson(Map<String, dynamic> json) {
    return ConversationsData(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        content,
        totalElements,
        totalPages,
        size,
        number,
        first,
        last,
        empty,
      ];
}
