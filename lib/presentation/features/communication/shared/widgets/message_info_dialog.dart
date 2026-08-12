import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/messaging_time_formatter.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// A single recipient's delivery/read state for [MessageInfoDialog] —
/// stack-agnostic so both the legacy (Room Chat / Staff Direct) and v2
/// (Admin Chat) message models can adapt their own receipt shapes into this
/// one before display.
class MessageInfoRecipient {
  const MessageInfoRecipient({
    required this.name,
    this.role,
    this.deliveredAt,
    this.readAt,
    this.avatarSource,
  });

  final String name;
  final String? role;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  /// Either a resolved photo URL or a raw media-asset code — mirrors
  /// [ConversationParticipant.avatarUrl]/[ParticipantEntity.avatarUrl].
  final String? avatarSource;

  bool get isRead => readAt != null;
}

/// Shared "Message Info" dialog used by Room Chat, Staff Direct, and Admin
/// Chat alike. A recipient who has read the message is shown only under
/// "Read By" — never duplicated under "Delivered To" — since a read implies
/// delivery.
class MessageInfoDialog extends StatelessWidget {
  const MessageInfoDialog({
    super.key,
    required this.messageText,
    required this.recipients,
  });

  final String messageText;
  final List<MessageInfoRecipient> recipients;

  static Future<void> show(
    BuildContext context, {
    required String messageText,
    required List<MessageInfoRecipient> recipients,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) =>
          MessageInfoDialog(messageText: messageText, recipients: recipients),
    );
  }

  static String _plainText(String html) {
    return MessageContentProcessor.stripHtmlTags(html).trim();
  }

  /// Normalizes a raw role string (e.g. "PARENT", "teacher") into a short
  /// display label, mapping PARENT → Guardian to match the rest of the app.
  static String? _formatRole(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final upper = raw.trim().toUpperCase();
    final normalized = upper == 'PARENT' ? 'GUARDIAN' : upper;
    if (normalized.isEmpty) return null;
    return normalized[0] + normalized.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final readBy = recipients.where((r) => r.isRead).toList();
    final deliveredOnly = recipients
        .where((r) => !r.isRead && r.deliveredAt != null)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Message Info',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.primaryColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageText.trim().isNotEmpty) ...[
                    _SectionLabel(label: 'Message'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _plainText(messageText),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _SectionLabel(
                    label: 'Read By (${readBy.length})',
                  ),
                  const SizedBox(height: 8),
                  if (readBy.isEmpty)
                    const _EmptyNote(text: 'No one has read this message yet.')
                  else
                    ...readBy.map(
                      (r) => _RecipientTile(
                        recipient: r,
                        timestamp: r.readAt,
                        icon: Icons.done_all_rounded,
                        iconColor: const Color(0xFF2ECC71),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionLabel(
                    label: 'Delivered To (${deliveredOnly.length})',
                  ),
                  const SizedBox(height: 8),
                  if (deliveredOnly.isEmpty)
                    const _EmptyNote(text: 'Not yet delivered.')
                  else
                    ...deliveredOnly.map(
                      (r) => _RecipientTile(
                        recipient: r,
                        timestamp: r.deliveredAt,
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.primaryColor.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor.withValues(alpha: 0.6),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.recipient,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });

  final MessageInfoRecipient recipient;
  final DateTime? timestamp;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final role = MessageInfoDialog._formatRole(recipient.role);
    final avatarSource = recipient.avatarSource?.trim() ?? '';
    final isUrl = avatarSource.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DocumentImageWidget(
            fileUuid: '',
            imageUrl: isUrl ? avatarSource : null,
            mediaAssetCode: !isUrl && avatarSource.isNotEmpty
                ? avatarSource
                : null,
            name: recipient.name,
            size: 32,
            fontSize: 12,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        recipient.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    if (role != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    MessagingTimeFormatter.infoTime(timestamp!),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: iconColor),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryColor.withValues(alpha: 0.4),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
