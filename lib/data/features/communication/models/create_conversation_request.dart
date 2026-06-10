class CreateConversationRequest {
  final String title;
  final String type;
  final String description;
  final String initialMessage;
  final String organizationCode;
  final String schoolCode;
  final String avatarUrl;
  final List<String> participantUserCodes;
  final List<Map<String, dynamic>>? participants;
  final List<Map<String, dynamic>> attachments;

  CreateConversationRequest({
    required this.title,
    this.type = 'DIRECT',
    this.description = '',
    this.initialMessage = '',
    required this.organizationCode,
    required this.schoolCode,
    this.avatarUrl = '',
    this.participantUserCodes = const [],
    this.participants,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    // organizationCode and schoolCode are sent via AuthInterceptor headers
    // (X-Organization-Code, X-School-Code) — do not duplicate in the body.
    final json = <String, dynamic>{
      'title': title,
      'type': type,
      'description': description,
      'initialMessage': initialMessage,
      'avatarUrl': avatarUrl,
    };

    if (participants != null) {
      json['participants'] = participants;
    } else {
      json['participants'] = participantUserCodes
          .map((code) => {
                'userCode': code,
                'role': code.startsWith('STF_') ? 'STAFF' : 'PARENT',
              })
          .toList();
    }

    if (attachments.isNotEmpty) {
      json['attachments'] = attachments;
    }

    return json;
  }
}
