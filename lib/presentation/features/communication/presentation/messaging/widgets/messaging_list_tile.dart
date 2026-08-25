import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/conversation_display.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/messaging_time_formatter.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class MessagingListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  /// The logged-in user's code — used to resolve the OTHER participant's name
  /// for 1:1 (STAFF_DIRECT) chats instead of the frozen stored title. See
  /// [ConversationDisplay].
  final String? currentUserCode;

  const MessagingListTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.currentUserCode,
  });

  /// The backend's conversation-list summary only carries a plain-text
  /// `lastMessagePreview` — empty for an attachment-only last message,
  /// with no field at all for attachment name/type or reactions (those
  /// only exist on the full `Message` entity inside a thread, not on this
  /// list-level summary). `lastMessageAt` is what actually distinguishes
  /// "no messages yet" from "the last message just had no text", so use
  /// that instead of treating both cases as the empty-preview case.
  ///
  /// Prefixed with the sender's name (`SenderName: message`) to match the
  /// web app's chat list — this was previously dropped entirely on mobile.
  /// The backend doesn't actually send a dedicated sender-name field, so
  /// `Conversation.lastMessageSenderDisplayName` derives it from
  /// `lastMessageBy` + `participants` instead. Only the "no messages yet"
  /// placeholder stays sender-less.
  String _lastMessagePreviewText(Conversation conversation) {
    final body = conversation.lastMessagePreview.isNotEmpty
        ? MessageContentProcessor.previewText(conversation.lastMessagePreview)
        : (conversation.lastMessageAt != null ? '📎 Attachment' : null);
    if (body == null) return 'Start a new conversation';
    final senderName = conversation.lastMessageSenderDisplayName?.trim();
    if (senderName == null || senderName.isEmpty) return body;
    return '$senderName: $body';
  }

  String _formatMessageTime(DateTime? dateTime) =>
      MessagingTimeFormatter.conversationTime(dateTime);

  @override
  Widget build(BuildContext context) {
    // For 1:1 chats show the OTHER participant relative to the viewer, not the
    // frozen stored title (which is the creator's counterpart name).
    final displayName = ConversationDisplay.name(conversation, currentUserCode);
    final displayAvatar = ConversationDisplay.avatar(
      conversation,
      currentUserCode,
    );
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1A6C5CE7), // Subtle theme splash
      highlightColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          // No staffCode/studentCode is available on this legacy
          // Conversation model (only the participant's userCode is, which
          // isn't what the attendance "today sign-in status" API expects)
          // — so there's no reliable signal to drive a real presence dot
          // here. Showing one based on `conversation.status` (the
          // conversation's own archived/active flag, unrelated to whether
          // the person is actually signed in) was actively misleading, so
          // it's removed rather than left showing the wrong thing.
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DocumentImageWidget(
              disableAttendanceStatusLookup: true,
              fileUuid: '',
              // `avatarUrl` is either a resolved URL or a raw media-asset
              // code depending on which screen started the conversation.
              imageUrl: displayAvatar.startsWith('http') ? displayAvatar : null,
              mediaAssetCode: displayAvatar.startsWith('http')
                  ? null
                  : displayAvatar,
              name: displayName,
              size: 52,
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: displayName,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontColor: AppColors.primaryColor,
                  ),
                ),
                Text(
                  _formatMessageTime(conversation.lastMessageAt),
                  style: AppTextStyles.caption.copyWith(
                    color: Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
          ),
          subtitle: Row(
            children: [
              // Lock icon when the conversation is in private mode — the preview
              // still shows the real last message (for those allowed to see it).
              if (conversation.privateModeActive)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock, size: 13, color: Color(0xFF636E72)),
                ),
              Flexible(
                fit: FlexFit.tight,
                child: Text(
                  _lastMessagePreviewText(conversation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Color(0xFF636E72),
                    height: 1.4,
                  ),
                ),
              ),
              if (conversation.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00B894,
                          ).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
