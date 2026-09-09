import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
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
///
/// [recipientsFuture] is fetched fresh on every open (the dedicated
/// per-message receipts endpoint — see `ApiPaths.messagingMessageReceipts`)
/// rather than reusing whatever the message's own embedded, lighter
/// `receipts` field already had cached, so the dialog shows a brief loading
/// state while that request is in flight.
class MessageInfoDialog extends StatelessWidget {
  const MessageInfoDialog({
    super.key,
    required this.messageText,
    required this.recipientsFuture,
  });

  final String messageText;
  final Future<List<MessageInfoRecipient>> recipientsFuture;

  static Future<void> show(
    BuildContext context, {
    required String messageText,
    required Future<List<MessageInfoRecipient>> recipientsFuture,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.45),
      builder: (_) => MessageInfoDialog(
        messageText: messageText,
        recipientsFuture: recipientsFuture,
      ),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
            ),
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
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    AppStrings.messageInfo,
                    style: AppTextStyles.heading18.copyWith(
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
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageText.trim().isNotEmpty) ...[
                    _MessageSectionLabel(label: AppStrings.messageSectionLabel),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.messagingMessageBoxBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.messagingInputBorder,
                        ),
                      ),
                      child: Text(
                        _plainText(messageText),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  FutureBuilder<List<MessageInfoRecipient>>(
                    future: recipientsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        );
                      }
                      final recipients = snapshot.data ?? const [];
                      final readBy = recipients.where((r) => r.isRead).toList();
                      final deliveredOnly = recipients
                          .where((r) => !r.isRead && r.deliveredAt != null)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MessageSectionLabel(
                            label: AppStrings.readByCount(readBy.length),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          if (readBy.isEmpty)
                            const _EmptyNote(text: AppStrings.noOneHasRead)
                          else
                            ...readBy.map(
                              (r) => _RecipientTile(
                                recipient: r,
                                timestamp: r.readAt,
                                icon: Icons.done_all_rounded,
                                iconColor: AppColors.messagingReadCheckColor,
                              ),
                            ),
                          const SizedBox(height: AppSizes.md),
                          _MessageSectionLabel(
                            label: AppStrings.deliveredToCount(
                              deliveredOnly.length,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          if (deliveredOnly.isEmpty)
                            const _EmptyNote(text: AppStrings.notYetDelivered)
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
                      );
                    },
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

/// Section heading inside the message-info dialog.
///
/// Renamed from `_SectionLabel` to clear a name collision with the reports
/// module's label (§6.5). The two are NOT interchangeable: this one is
/// 12/w700 in `AppColors.primaryColor` at 60% alpha, the reports one is
/// 13/w600 in the opaque indigo #4F46E5. Styling is unchanged by the rename.
class _MessageSectionLabel extends StatelessWidget {
  const _MessageSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.size14.copyWith(
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
      padding: const EdgeInsets.only(bottom: AppSizes.xsPlus),
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
          const SizedBox(width: AppSizes.xsPlus),
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
                        style: AppTextStyles.size14.copyWith(
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
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role,
                          style: AppTextStyles.size14.copyWith(
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
                    style: AppTextStyles.size14.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.xs),
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
      style: AppTextStyles.size14.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryColor.withValues(alpha: 0.4),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
