import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// A single selectable row inside an [AssessmentOptionSheet].
class AssessmentOption<T> {
  const AssessmentOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.selected = false,
    this.disabled = false,
    this.destructive = false,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final bool destructive;
}

/// Generic bottom-sheet option list used across the module for the period,
/// classroom and school pickers, and for the framework entity menus. Returns
/// the chosen option's [AssessmentOption.value], or null when dismissed.
class AssessmentOptionSheet<T> extends StatelessWidget {
  const AssessmentOptionSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
  });

  final String title;
  final String? subtitle;
  final List<AssessmentOption<T>> options;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<AssessmentOption<T>> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => AssessmentOptionSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2DFEC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AssessmentUi.ink,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8398),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...options.map((o) => _OptionRow<T>(option: o)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({required this.option});

  final AssessmentOption<T> option;

  @override
  Widget build(BuildContext context) {
    final o = option;
    final bg = o.selected
        ? const Color(0xFFEEF1FF)
        : (o.destructive ? const Color(0xFFFEF2F2) : const Color(0xFFF7F6FB));
    final titleColor =
        o.destructive ? const Color(0xFFB91C1C) : AssessmentUi.ink;
    return Opacity(
      opacity: o.disabled ? 0.4 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: o.disabled ? null : () => Navigator.pop(context, o.value),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (o.icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: o.destructive
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFEEF1FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        o.icon,
                        size: 18,
                        color: o.destructive
                            ? const Color(0xFFB91C1C)
                            : AppColors.themeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        if (o.subtitle != null && o.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            o.subtitle!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AssessmentUi.inkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (o.selected)
                    const Icon(Icons.check_circle_rounded,
                        size: 22, color: AppColors.themeColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
