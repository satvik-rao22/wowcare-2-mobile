import 'conversation_model.dart';

class CreateConversationResponse {
  final bool success;
  final String message;
  final ConversationModel? data;
  final String timestamp;
  final String? correlationId;

  CreateConversationResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.correlationId,
  });

  factory CreateConversationResponse.fromJson(Map<String, dynamic> json) {
    return CreateConversationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? ConversationModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as String? ?? '',
      correlationId: json['correlationId'] as String?,
    );
  }
}
