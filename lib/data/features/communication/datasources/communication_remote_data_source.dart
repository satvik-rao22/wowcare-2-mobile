import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/data/features/communication/models/message_model.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<MessageModel>> getMessages(String threadId);
  Future<MessageModel> sendMessage(String threadId, MessageModel message);
  Future<void> markAsRead(String threadId, String messageId);
  Future<String> uploadAttachment(ChatAttachmentModel attachment);
}

class CommunicationRemoteDataSourceImpl implements CommunicationRemoteDataSource {
  final ApiClient apiClient;

  CommunicationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MessageModel>> getMessages(String threadId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _getMockMessages(threadId);
  }

  @override
  Future<MessageModel> sendMessage(String threadId, MessageModel message) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return message; // In mock, we just return what was sent
  }

  @override
  Future<void> markAsRead(String threadId, String messageId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<String> uploadAttachment(ChatAttachmentModel attachment) async {
    await Future.delayed(const Duration(seconds: 1));
    return "https://example.com/mock-upload/${attachment.name}";
  }

  List<MessageModel> _getMockMessages(String threadId) {
    if (threadId == 'staff-group') {
      return [
        MessageModel(
          id: 's1',
          text: "Hello! I want to take day off tomorrow ?",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 14, 45),
          reactions: {
            'natasha': '😂',
            'eddie': '😂',
            'john': '😂',
            'manager': '👍',
          },
        ),
        MessageModel(
          id: 's2',
          text: "Okay Natasha!",
          isSentByMe: true,
          time: DateTime(2025, 1, 13, 16, 45),
          attachments: [
            ChatAttachmentModel(
              name: 'Vacation Request.pdf',
              type: 'document',
              sizeBytes: 1240000,
              mimeType: 'application/pdf',
              remoteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            ),
          ],
        ),
        MessageModel(
          id: 's3',
          text: "Great to know that! Thanks!",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 16, 50),
          reactions: {'manager': '🙏', 'hr': '🙏', 'john': '🙏'},
        ),
        MessageModel(
          id: 's4',
          text: "Also, is it possible to make it half day instead? I have doctor appointment in morning",
          isSentByMe: false,
          time: DateTime(2025, 1, 14, 9, 12),
          deliveredAt: DateTime(2025, 1, 14, 9, 12),
          reactions: {
            'natasha': '👍',
            'eddie': '👍',
            'john': '❤️',
            'manager': '🙏',
            'hr': '🙏',
          },
          attachments: [
            ChatAttachmentModel(
              name: 'Doctor Appointment Letter.jpg',
              type: 'image',
              sizeBytes: 3200000,
              mimeType: 'image/jpeg',
              remoteUrl: "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
            ),
            ChatAttachmentModel(
              name: 'Medical Certificate.pdf',
              type: 'document',
              sizeBytes: 1450000,
              mimeType: 'application/pdf',
              remoteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            ),
          ],
        ),
        MessageModel(
          id: 's5',
          text: "Sure, half day is fine. Just mark it in the attendance sheet when you come back",
          isSentByMe: true,
          time: DateTime(2025, 1, 14, 9, 18),
          readAt: DateTime(2025, 1, 14, 9, 18),
          reactions: {
            'natasha': '😂',
            'eddie': '😂',
            'john': '😂',
            'manager': '👍',
            'natashi': '👍',
            'eddiey': '👍',
            'johny': '❤️',
            'managery': '🙏',
            'hr': '🙏',
          },
          attachments: [
            ChatAttachmentModel(
              name: 'Team Meeting Notes.pdf',
              type: 'document',
              sizeBytes: 980000,
              mimeType: 'application/pdf',
              remoteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            ),
          ],
        ),
        MessageModel(
          id: 's6',
          text: "Thank you so much! ❤️ Will do",
          isSentByMe: false,
          time: DateTime(2025, 1, 14, 9, 20),
          attachments: [
            ChatAttachmentModel(
              name: 'Thank You Card.jpg',
              type: 'image',
              sizeBytes: 2100000,
              mimeType: 'image/jpeg',
              remoteUrl: "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
            ),
          ],
        ),
        MessageModel(
          id: 's7',
          text: "By the way, did you see the new leave policy update? They added 2 extra optional holidays this year",
          isSentByMe: true,
          time: DateTime(2025, 1, 14, 11, 5),
          readAt: DateTime(2025, 1, 14, 11, 5),
          attachments: [
            ChatAttachmentModel(
              name: 'New Leave Policy 2025.pdf',
              type: 'document',
              sizeBytes: 2800000,
              mimeType: 'application/pdf',
              remoteUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            ),
          ],
        ),
        MessageModel(
          id: 's8',
          text: "No I didn't! Where can I find it? HR portal?",
          isSentByMe: false,
          time: DateTime(2025, 1, 14, 11, 8),
          attachments: [
            ChatAttachmentModel(
              name: 'HR Portal Screenshot.jpg',
              type: 'image',
              sizeBytes: 1800000,
              mimeType: 'image/jpeg',
              remoteUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80',
            ),
            ChatAttachmentModel(
              name: 'Policies Folder.jpg',
              type: 'image',
              sizeBytes: 1450000,
              mimeType: 'image/jpeg',
              remoteUrl: "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
            ),
          ],
        ),
        MessageModel(
          id: 's9',
          text: "Yes, under Policies → Leave & Attendance → 2025 updates. It's the pinned document",
          isSentByMe: true,
          time: DateTime(2026, 1, 21, 11, 11),
          deliveredTo: [
            RecipientStatusModel(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 12)),
            RecipientStatusModel(name: "Eddie Barns", timestamp: DateTime(2026, 1, 21, 11, 13)),
            RecipientStatusModel(name: "John Doe", timestamp: DateTime(2026, 1, 21, 11, 15)),
          ],
          readBy: [
            RecipientStatusModel(name: "Natasha White", timestamp: DateTime(2026, 1, 21, 11, 14)),
            RecipientStatusModel(name: "Eddie Barns", timestamp: DateTime(2026, 1, 21, 11, 16)),
          ],
          attachments: [
            ChatAttachmentModel(
              name: 'Policy Update Screenshot 1.jpg',
              type: 'image',
              sizeBytes: 2400000,
              mimeType: 'image/jpeg',
              remoteUrl: "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
            ),
          ],
        ),
      ];
    } else if (threadId == 'parent-group') {
      return [
        MessageModel(
          id: 'pg1',
          senderName: "Eddie Barnes",
          text: "Good morning everyone! Ajay attended school today.",
          isSentByMe: true,
          time: DateTime(2025, 1, 13, 8, 30),
        ),
        MessageModel(
          id: 'pg2',
          senderName: "Radha Sundaram",
          text: "Thank you for the update!",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 8, 45),
        ),
        MessageModel(
          id: 'pg3',
          senderName: "Nitin Sundaram",
          text: "Yes, thanks Eddie. How was his math class?",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 9, 00),
        ),
      ];
    } else if (threadId == 'parent-radha') {
      return [
        MessageModel(
          id: 'pr1',
          senderName: "Radha Sundaram",
          text: "How is Ajay Doing Today?",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 14, 45),
        ),
        MessageModel(
          id: 'pr2',
          senderName: "Eddie Barnes",
          text: "He is doing Great! Here's a photo from today's activity.",
          isSentByMe: true,
          time: DateTime(2025, 1, 13, 16, 45),
          attachments: [
            ChatAttachmentModel(
              name: 'Ajay Photo.jpg',
              type: 'image',
              sizeBytes: 3200000,
              mimeType: 'image/jpeg',
              remoteUrl: 'https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=800',
            ),
          ],
        ),
        MessageModel(
          id: 'pr3',
          senderName: "Radha Sundaram",
          text: "Thanks! He looks happy 😊",
          isSentByMe: false,
          time: DateTime(2025, 1, 13, 16, 50),
        ),
      ];
    } else if (threadId == 'parent-nitin') {
      return [
        MessageModel(
          id: 'pn1',
          senderName: "Nitin Sundaram",
          text: "Ajay forgot his water bottle again today?",
          isSentByMe: false,
          time: DateTime(2025, 1, 14, 10, 15),
        ),
        MessageModel(
          id: 'pn2',
          senderName: "Eddie Barnes",
          text: "Yes, but we gave him one from school stock. No worries.",
          isSentByMe: true,
          time: DateTime(2025, 1, 14, 10, 20),
        ),
        MessageModel(
          id: 'pn3',
          senderName: "Nitin Sundaram",
          text: "Thank you so much!",
          isSentByMe: false,
          time: DateTime(2025, 1, 14, 10, 25),
        ),
      ];
    }
    return [];
  }
}
