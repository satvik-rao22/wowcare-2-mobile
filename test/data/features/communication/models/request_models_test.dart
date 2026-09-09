import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/edit_message_request.dart';
import 'package:wowcare/data/features/communication/models/message_reaction_request.dart';
import 'package:wowcare/data/features/communication/models/send_message_request.dart';

/// Characterisation test (Mandate 8) for the write request models. `oldSend`
/// is a verbatim copy of the inline body the v2 datasource built before this
/// slice; `SendMessageRequest.toJson()` must match it across every conditional
/// branch (empty attachments, isPrivate false/true, null/non-null ppc + reply,
/// empty/non-empty role).
Map<String, dynamic> oldSend({
  required String conversationCode,
  required String content,
  List<int> attachmentIds = const [],
  bool isPrivate = false,
  String? privateParentUserCode,
  String? replyToMessageCode,
  String role = '',
}) => <String, dynamic>{
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

void main() {
  group('SendMessageRequest.toJson — matches old inline body', () {
    test('minimal (all optionals omitted)', () {
      const conv = 'CONV_1';
      const content = '<p>hi</p>';
      expect(
        const SendMessageRequest(
          conversationCode: conv,
          content: content,
        ).toJson(),
        oldSend(conversationCode: conv, content: content),
      );
    });

    test('all fields set', () {
      const args = (
        conv: 'CONV_2',
        content: '<p>x</p>',
        atts: [1, 2, 3],
        ppc: 'GUA_1',
        reply: 'MSG_9',
        role: 'ORGANIZATION_ADMIN',
      );
      expect(
        const SendMessageRequest(
          conversationCode: 'CONV_2',
          content: '<p>x</p>',
          attachmentIds: [1, 2, 3],
          isPrivate: true,
          privateParentUserCode: 'GUA_1',
          replyToMessageCode: 'MSG_9',
          role: 'ORGANIZATION_ADMIN',
        ).toJson(),
        oldSend(
          conversationCode: args.conv,
          content: args.content,
          attachmentIds: args.atts,
          isPrivate: true,
          privateParentUserCode: args.ppc,
          replyToMessageCode: args.reply,
          role: args.role,
        ),
      );
    });

    test('isPrivate false omits key; empty role omits key', () {
      final json = const SendMessageRequest(
        conversationCode: 'C',
        content: 'c',
        isPrivate: false,
        role: '',
      ).toJson();
      expect(json.containsKey('isPrivate'), false);
      expect(json.containsKey('role'), false);
      expect(json.containsKey('attachmentIds'), false);
      expect(json.containsKey('privateParentUserCode'), false);
      expect(json.containsKey('replyToMessageCode'), false);
    });
  });

  test('EditMessageRequest.toJson', () {
    expect(const EditMessageRequest(content: '<p>e</p>').toJson(), {
      'content': '<p>e</p>',
    });
  });

  test('MessageReactionRequest.toJson', () {
    expect(const MessageReactionRequest(emoji: '👍').toJson(), {'emoji': '👍'});
  });
}
