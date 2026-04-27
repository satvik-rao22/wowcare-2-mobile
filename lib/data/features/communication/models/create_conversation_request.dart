class CreateConversationRequest {
  final String title;
  final String type;
  final String description;
  final String initialMessage;
  final String organizationCode;
  final String schoolCode;
  final String avatarUrl;
  final List<String> participantUserCodes;
  final List<Map<String, dynamic>> attachments;

  CreateConversationRequest({
    required this.title,
    this.type = 'DIRECT',
    this.description = '',
    this.initialMessage = '',
    required this.organizationCode,
    required this.schoolCode,
    this.avatarUrl = '',
    required this.participantUserCodes,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'type': type,
      'description': description,
      'initialMessage': initialMessage,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'avatarUrl': avatarUrl,
      'participantUserCodes': participantUserCodes,
    };

    if (attachments.isNotEmpty) {
      json['attachments'] = attachments;
    }

    return json;
  }
}
