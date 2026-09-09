/// Request model for adding a reaction (`POST .../messages/{code}/reactions`).
/// Removal is a path-only DELETE with no body, so it needs no request model.
class MessageReactionRequest {
  const MessageReactionRequest({required this.emoji});

  final String emoji;

  Map<String, dynamic> toJson() => {'emoji': emoji};
}
