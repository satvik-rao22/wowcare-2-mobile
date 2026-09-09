import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'conversation_model.dart';

part 'get_conversations_response.g.dart';

/// Response envelope for `GET /conversations` (and search). Inbound only —
/// never serialised out, so `createToJson: false`. `@JsonKey` defaults
/// reproduce the previous hand-written parser exactly.
@JsonSerializable(createToJson: false)
class GetConversationsResponse extends Equatable {
  @JsonKey(defaultValue: false)
  final bool success;

  @JsonKey(defaultValue: '')
  final String message;

  final ConversationsData? data;

  @JsonKey(defaultValue: '')
  final String timestamp;

  final String? correlationId;

  const GetConversationsResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.correlationId,
  });

  factory GetConversationsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetConversationsResponseFromJson(json);

  @override
  List<Object?> get props => [success, message, data, timestamp, correlationId];
}

@JsonSerializable(createToJson: false)
class ConversationsData extends Equatable {
  @JsonKey(defaultValue: [])
  final List<ConversationModel> content;

  @JsonKey(defaultValue: 0)
  final int totalElements;

  @JsonKey(defaultValue: 0)
  final int totalPages;

  @JsonKey(defaultValue: 0)
  final int size;

  @JsonKey(defaultValue: 0)
  final int number;

  @JsonKey(defaultValue: true)
  final bool first;

  @JsonKey(defaultValue: true)
  final bool last;

  @JsonKey(defaultValue: true)
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

  factory ConversationsData.fromJson(Map<String, dynamic> json) =>
      _$ConversationsDataFromJson(json);

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
