import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// The four top-level destinations of the Assessments module, surfaced as a
/// bottom navigation bar (mirrors the standalone redesign). Parents never reach
/// the module, so every persona that gets here sees all four tabs (Parameters
/// is read-only for staff).
enum AssessmentSection {
  students('Students', Icons.face_rounded),
  classrooms('Classrooms', Icons.meeting_room_rounded),
  school('School', Icons.school_rounded),
  framework('Parameters', Icons.account_tree_rounded);

  const AssessmentSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Top app bar shown on the list-level screens: brand mark, the section title,
/// the 1.0/2.0 colour-theme switcher, and a read-only chip showing the
/// signed-in role. The role chip is informational only — RBAC is driven
/// entirely by [RoleCubit], not by tapping here.
class AssessmentTopHeader extends StatelessWidget {
  const AssessmentTopHeader({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.themeV2,
    required this.onThemeSelect,
  });

  final String title;
  final String roleLabel;

  /// Whether the 2.0 colour theme is active.
  final bool themeV2;

  /// Called with `true` for 2.0 / `false` for 1.0 when a segment is tapped.
  final ValueChanged<bool> onThemeSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AssessmentUi.brandGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AssessmentUi.brand.withValues(alpha: 0.34),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSESSMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: AssessmentUi.inkMuted,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AssessmentUi.ink,
                  ),
                ),
              ],
            ),
          ),
          _ThemeTogglePill(themeV2: themeV2, onSelect: onThemeSelect),
          const SizedBox(width: 8),
          _RoleChip(label: roleLabel),
        ],
      ),
    );
  }
}

/// Two-segment pill switching the module between its 1.0 (indigo) and 2.0
/// (pink/cyan/orange) colour themes.
class _ThemeTogglePill extends StatelessWidget {
  const _ThemeTogglePill({required this.themeV2, required this.onSelect});

  final bool themeV2;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Colour theme',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2559).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSegment(
              label: '1.0',
              selected: !themeV2,
              onTap: () => onSelect(false),
            ),
            _ThemeSegment(
              label: '2.0',
              selected: themeV2,
              onTap: () => onSelect(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Theme $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AssessmentUi.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AssessmentUi.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Signed in as $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2559).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 7,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AssessmentUi.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF574F66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back bar shown on drill-down screens (student stepper, classroom profile,
/// framework sub-levels). Carries a back affordance, a title/subtitle, and an
/// optional trailing "+ Add" action (used by framework management).
class AssessmentBackBar extends StatelessWidget {
  const AssessmentBackBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 12, 10),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AssessmentUi.ink,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AssessmentUi.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            _AddPill(label: actionLabel!, onTap: onAction!),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: AssessmentUi.ink),
          ),
        ),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B2559).withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: AssessmentUi.accent),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AssessmentUi.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The module's bottom navigation bar — a pill-highlighted four-tab row.
class AssessmentBottomNav extends StatelessWidget {
  const AssessmentBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AssessmentSection current;
  final ValueChanged<AssessmentSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
          child: Row(
            children: AssessmentSection.values.map((section) {
              final active = section == current;
              return Expanded(
                child: _NavItem(
                  section: section,
                  active: active,
                  onTap: () => onSelect(section),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.active,
    required this.onTap,
  });

  final AssessmentSection section;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AssessmentUi.brand : const Color(0xFFA39DB1);
    return Semantics(
      button: true,
      selected: active,
      label: section.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: active
                      ? AssessmentUi.palette.brandSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(section.icon, size: 21, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                section.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
