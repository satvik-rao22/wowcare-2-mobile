import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../../../shared/common/widgets/custom_button_layout.dart';

/// Normalized participant data — works for both ConversationParticipant
/// (used in ParentMessagingThread) and ParticipantEntity (ConversationThreadScreen).
class ParticipantDisplayData {
  const ParticipantDisplayData({
    required this.userCode,
    required this.displayName,
    required this.role, // ADMIN | STAFF | GUARDIAN
  });

  final String userCode;
  final String displayName;
  final String role;
}

/// Shows a modal dialog with grouped conversation participants.
///
/// Usage:
/// ```dart
/// ParticipantInfoDialog.show(
///   context,
///   participants: [...],
///   studentName: 'Jon Bennet',
/// );
/// ```
class ParticipantInfoDialog extends StatelessWidget {
  const ParticipantInfoDialog({
    super.key,
    required this.participants,
    this.studentName,
    this.studentAvatarUuid,
  });

  final List<ParticipantDisplayData> participants;
  final String? studentName;
  final String? studentAvatarUuid;

  static Future<void> show(
    BuildContext context, {
    required List<ParticipantDisplayData> participants,
    String? studentName,
    String? studentAvatarUuid,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => ParticipantInfoDialog(
        participants: participants,
        studentName: studentName,
        studentAvatarUuid: studentAvatarUuid,
      ),
    );
  }

  // ── Grouping ───────────────────────────────────────────────────────────────

  List<ParticipantDisplayData> _group(String role) {
    final result =
        participants.where((p) => p.role.toUpperCase() == role).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return result;
  }

  // ── Colors per role ────────────────────────────────────────────────────────

  static Color _avatarColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFFF59E0B);
      case 'STAFF':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  static Color _badgeBg(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFFFEF3C7);
      case 'STAFF':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFEDE9FE);
    }
  }

  static Color _badgeFg(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFF92400E);
      case 'STAFF':
        return const Color(0xFF065F46);
      default:
        return const Color(0xFF5B21B6);
    }
  }

  static String _badgeLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'STAFF':
        return 'Staff';
      default:
        return 'Parent';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final admins = _group('ADMIN');
    final staff = _group('STAFF');
    final guardians = _group('GUARDIAN');
    final total = participants.length;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF4F6FB),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────
            _DialogHeader(total: total),

            // ── Scrollable body ──────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // Student card
                  if (studentName != null && studentName!.isNotEmpty) ...[
                    _StudentCard(
                      name: studentName!,
                      avatarUuid: studentAvatarUuid,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Admins
                  if (admins.isNotEmpty) ...[
                    _SectionHeader(label: 'ADMINS', count: admins.length),
                    const Divider(height: 8, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 4),
                    ...admins.map((p) => _ParticipantTile(data: p)),
                    const SizedBox(height: 12),
                  ],

                  // Staff
                  if (staff.isNotEmpty) ...[
                    _SectionHeader(label: 'STAFFS', count: staff.length),
                    const Divider(height: 8, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 4),
                    ...staff.map((p) => _ParticipantTile(data: p)),
                    const SizedBox(height: 12),
                  ],

                  // Guardians/Parents
                  if (guardians.isNotEmpty) ...[
                    _SectionHeader(label: 'PARENTS', count: guardians.length),
                    const Divider(height: 8, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 4),
                    ...guardians.map((p) => _ParticipantTile(data: p)),
                  ],
                ],
              ),
            ),

            // ── Close button ─────────────────────────────────────────
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            //   child: SizedBox(
            //     width: double.infinity,
            //     height: 48,
            //     child: OutlinedButton(
            //       onPressed: () => Navigator.of(context).pop(),
            //       style: OutlinedButton.styleFrom(
            //         foregroundColor: AppColors.primaryColor,
            //         side: BorderSide(color: AppColors.themeColor, width: 1.5),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: const Text(
            //         'Close',
            //         style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            //       ),
            //     ),
            //   ),
            // ),
            CustomButtonLayout(
              showCancelButton: false,
              confirmButtonLabel: 'Close',
              onPressedConfirm: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Group Chat Participants ($total)',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.name, this.avatarUuid});

  final String name;
  final String? avatarUuid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DocumentImageWidget(
            fileUuid: avatarUuid ?? '',
            name: name,
            size: 52,
            fontSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.data});

  final ParticipantDisplayData data;

  @override
  Widget build(BuildContext context) {
    final role = data.role.toUpperCase();
    final avatarColor = ParticipantInfoDialog._avatarColor(role);
    final badgeBg = ParticipantInfoDialog._badgeBg(role);
    final badgeFg = ParticipantInfoDialog._badgeFg(role);
    final badgeLabel = ParticipantInfoDialog._badgeLabel(role);

    final initials = data.displayName.trim().isEmpty
        ? '?'
        : data.displayName
              .trim()
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                // Text(
                //   role,
                //   style: const TextStyle(
                //     fontSize: 11,
                //     color: Color(0xFF94A3B8),
                //   ),
                // ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
