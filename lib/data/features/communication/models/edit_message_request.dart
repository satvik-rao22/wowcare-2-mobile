/// Request model for `PUT /messaging/messages/{code}` (edit message body).
///
/// [content] is passed already in the exact form the endpoint expects (raw on
/// the legacy stack, HTML-wrapped on the v2 stack — the wrapping is a
/// datasource concern), so `toJson` is a straight one-key map.
class EditMessageRequest {
  const EditMessageRequest({required this.content});

  final String content;

  Map<String, dynamic> toJson() => {'content': content};
}
