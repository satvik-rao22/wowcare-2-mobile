/// Request model for `POST /messaging/messages` (v2 stack).
///
/// Hand-written `toJson` (following [CreateConversationRequest]'s shape) because
/// the payload is conditional — `attachmentIds`/`isPrivate`/`privateParentUserCode`/
/// `replyToMessageCode`/`role` are omitted when empty/false/null, which generated
/// `json_serializable` cannot express. [content] is the already-HTML-wrapped body
/// and [role] the already-resolved active backend role (both datasource concerns),
/// so this model only reproduces the exact wire map — it performs no async work.
class SendMessageRequest {
  const SendMessageRequest({
    required this.conversationCode,
    required this.content,
    this.attachmentIds = const [],
    this.isPrivate = false,
    this.privateParentUserCode,
    this.replyToMessageCode,
    this.role = '',
  });

  final String conversationCode;
  final String content;
  final List<int> attachmentIds;
  final bool isPrivate;
  final String? privateParentUserCode;
  final String? replyToMessageCode;
  final String role;

  Map<String, dynamic> toJson() => {
    'conversationCode': conversationCode,
    'type': 'TEXT',
    'content': content,
    if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
    if (isPrivate) 'isPrivate': true,
    if (privateParentUserCode != null)
      'privateParentUserCode': privateParentUserCode,
    if (replyToMessageCode != null) 'replyToMessageCode': replyToMessageCode,
    if (role.isNotEmpty) 'role': role,
  };
}
