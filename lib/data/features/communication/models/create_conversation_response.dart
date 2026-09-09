import 'package:json_annotation/json_annotation.dart';
import 'conversation_model.dart';

part 'create_conversation_response.g.dart';

/// Response envelope for `POST /conversations`. Inbound only — never
/// serialised out, so `createToJson: false`. `@JsonKey` defaults reproduce
/// the previous hand-written parser exactly.
@JsonSerializable(createToJson: false)
class CreateConversationResponse {
  @JsonKey(defaultValue: false)
  final bool success;

  @JsonKey(defaultValue: '')
  final String message;

  final ConversationModel? data;

  @JsonKey(defaultValue: '')
  final String timestamp;

  final String? correlationId;

  CreateConversationResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.correlationId,
  });

  factory CreateConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateConversationResponseFromJson(json);
}
