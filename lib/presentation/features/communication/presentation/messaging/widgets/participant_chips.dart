import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Reusable horizontal scrollable participant chips component.
///
/// Displays participants as chips with avatar, name, and role badge.
/// Used in conversation threads, parent messaging, and admin chat.
///
/// Features:
/// - Horizontal scrolling with separators
/// - Role-based color coding
/// - Dynamic filtering (e.g., admin-only for admin chats)
/// - Fallback names for missing display names
/// - Responsive height
class ParticipantChips extends StatelessWidget {
  const ParticipantChips({
    super.key,
    required this.participants,
    this.conversationType = ConversationType.roomChat,
    this.filterByRole,
  });

  final List<ParticipantEntity> participants;
  final ConversationType conversationType;

  /// If set, only show participants with this role (case-insensitive).
  /// Useful for admin-only filtering in Admin Chat.
  final String? filterByRole;

  @override
  Widget build(BuildContext context) {
    final visibleParticipants = _filterParticipants();

    if (visibleParticipants.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleParticipants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final p = visibleParticipants[index];
          final roleStr = _roleToDisplay(p.role);
          final name = p.userName.isNotEmpty ? p.userName : _roleFallbackName(roleStr);
          final color = _roleColor(roleStr);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  staffCode: (p.staffCode ?? '').trim().isNotEmpty
                      ? p.staffCode
                      : null,
                  name: name,
                  size: 16,
                  fontSize: 9,
                ),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleStr,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Filters participants based on role (admin-only) or conversation type.
  List<ParticipantEntity> _filterParticipants() {
    if (filterByRole != null) {
      return participants
          .where(
            (p) => p.role.toApiString().toUpperCase() == filterByRole!.toUpperCase(),
          )
          .toList();
    }

    // For admin chat, show only admins by default
    if (conversationType == ConversationType.adminChat) {
      return participants
          .where((p) => p.role.toApiString().toUpperCase() == 'ADMIN')
          .toList();
    }

    return participants;
  }

  /// Converts participant role enum to display string.
  /// Converts PARENT → GUARDIAN for UI consistency.
  String _roleToDisplay(ParticipantRole role) {
    final roleStr = role.toApiString().toUpperCase();
    return roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
  }

  /// Returns fallback name based on role when display name is missing.
  String _roleFallbackName(String roleStr) {
    const fallbacks = {
      'ADMIN': 'Admin',
      'GUARDIAN': 'Parent',
      'PARENT': 'Parent',
      'STAFF': 'Staff',
      'TEACHER': 'Teacher',
      'DIRECTOR': 'Director',
      'PRINCIPAL': 'Principal',
      'ASSISTANT_DIRECTOR': 'Assistant',
      'LEAD_TEACHER': 'Lead Teacher',
    };
    return fallbacks[roleStr] ?? roleStr;
  }

  /// Returns role-specific color for chip styling.
  Color _roleColor(String roleStr) {
    return switch (roleStr) {
      'ADMIN' => const Color(0xFF6C63FF),
      'GUARDIAN' => const Color(0xFF00B4DB),
      'PARENT' => const Color(0xFF00B4DB),
      'STAFF' => const Color(0xFFFF9F1C),
      'TEACHER' => const Color(0xFFFF9F1C),
      'DIRECTOR' => const Color(0xFFE63946),
      'PRINCIPAL' => const Color(0xFFE63946),
      'ASSISTANT_DIRECTOR' => const Color(0xFFF4A460),
      'LEAD_TEACHER' => const Color(0xFFFF9F1C),
      _ => AppColors.primaryColor,
    };
  }
}
