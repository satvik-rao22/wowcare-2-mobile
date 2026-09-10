import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// A label/value row used on [StaffDatesTab] for a single important-date
/// field (Hire Date, CDA, First Aid/CPR, BRC).
class DateRow extends StatelessWidget {
  const DateRow({
    super.key,
    required this.label,
    required this.text,
    this.showInfo = false,
  });
  final String label;
  final String text;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontSize: 16,
                  letterSpacing: 14 * (-3 / 100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Child Development Associate',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: true,
                waitDuration: Duration(milliseconds: 50),
                showDuration: Duration(seconds: 2),
                verticalOffset: 6,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: AppColors.cardColor,
                  fontSize: 12,
                  fontFamily: AppFonts.body,
                  fontWeight: FontWeight.w600,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (() {
            final t = text.trim();
            final tl = t.toLowerCase();
            if (t.isEmpty) return '-';
            if (tl.contains('no cda')) return '-';
            if (tl.contains('first aid') || tl.contains('cpr')) return '-';
            if (tl.contains('background record')) return '-';
            return text;
          })(),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A physical-checkup status card (Due/Scheduled/Overdue/Completed) shown on
/// [StaffDatesTab].
class PhysicalCard extends StatelessWidget {
  const PhysicalCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.date,
    this.showMore = false,
    this.onMore,
  });

  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String date;
  final bool showMore;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: AppFonts.body,
                  ),
                ),
              ),
              const Spacer(),
              if (showMore)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.primaryColor,
                  ),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkup Date',
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  letterSpacing: 14 * (-3 / 100),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tap-to-open field row (date/label with a trailing icon) used inside the
/// important-dates edit dialogs on [StaffDatesTab].
class DialogField extends StatelessWidget {
  const DialogField({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.6),
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.staffLightBackgroundAltColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                suffix,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A dropdown field row used inside the important-dates edit dialogs on
/// [StaffDatesTab].
class DialogDropdown extends StatelessWidget {
  const DialogDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.6),
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.staffLightBackgroundAltColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryColor,
              ),
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
