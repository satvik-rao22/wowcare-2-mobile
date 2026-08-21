import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../../app/theme/colors.dart';

/// One person's reaction, resolved for display — stack-agnostic so both the
/// legacy (Room Chat / Staff Direct) and v2 (Admin Chat) message models can
/// adapt their own [ReactionEntry] shape into this one before display.
class ReactionPerson {
  const ReactionPerson({
    required this.emoji,
    required this.name,
    this.role,
    this.avatarSource,
  });

  final String emoji;
  final String name;
  final String? role;

  /// Either a resolved photo URL or a raw media-asset code — mirrors
  /// [MessageInfoRecipient.avatarSource].
  final String? avatarSource;
}

/// Shows who reacted to a message, grouped by emoji. Mirrors
/// [MessageInfoDialog]'s visual language (same header chrome, avatar rows,
/// Manrope typography) so both "info" surfaces feel like one family.
class ReactionInfoDialog extends StatelessWidget {
  const ReactionInfoDialog({super.key, required this.reactions});

  final List<ReactionPerson> reactions;

  static Future<void> show(
    BuildContext context, {
    required List<ReactionPerson> reactions,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.black45,
      builder: (_) => ReactionInfoDialog(reactions: reactions),
    );
  }

  static String? _formatRole(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final upper = raw.trim().toUpperCase();
    final normalized = upper == 'PARENT' ? 'GUARDIAN' : upper;
    if (normalized.isEmpty) return null;
    return normalized[0] + normalized.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final byEmoji = <String, List<ReactionPerson>>{};
    for (final r in reactions) {
      byEmoji.putIfAbsent(r.emoji, () => []).add(r);
    }

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
                  child: const Text('❤️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reactions',
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
                  for (final entry in byEmoji.entries) ...[
                    Row(
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '(${entry.value.length})',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((p) => _ReactionPersonTile(person: p)),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionPersonTile extends StatelessWidget {
  const _ReactionPersonTile({required this.person});
  final ReactionPerson person;

  @override
  Widget build(BuildContext context) {
    final role = ReactionInfoDialog._formatRole(person.role);
    final avatarSource = person.avatarSource?.trim() ?? '';
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
            name: person.name,
            size: 32,
            fontSize: 12,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    person.name,
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
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
