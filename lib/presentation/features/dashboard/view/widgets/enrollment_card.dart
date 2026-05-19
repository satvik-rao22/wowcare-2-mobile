import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';

/// Colours for the breakdown bar segments that have no exact theme constant.
const Color _signedOutColor = Color(0xFF8BB4EF);
const Color _notMarkedColor = Color(0xFFEBC398);

/// One labelled segment of a breakdown bar (name + count + colour).
class _Seg {
  const _Seg(this.name, this.count, this.color);

  final String name;
  final int count;
  final Color color;
}

/// Converts raw count segments into [ProgressItemHelper]s for
/// [CustomStatBarCard]. The bar `value` is the count expressed as a percentage
/// of [total] (so the segments fill the bar exactly), while the legend label
/// keeps the real count, e.g. "Signed-in (15)".
List<ProgressItemHelper> _percentItems({
  required int total,
  required List<_Seg> raw,
}) {
  return raw
      .map(
        (s) => ProgressItemHelper(
          label: '${s.name} (${s.count})',
          value: total == 0 ? 0 : s.count / total * 100,
          color: s.color,
        ),
      )
      .toList();
}

/// "Today's School Status" dashboard card.
///
/// UI-only: shows school-wide capacity stats plus enrolled-student,
/// expected-student and expected-staff breakdown bars built with the shared
/// [CustomStatBarCard].
class EnrollmentCard extends StatefulWidget {
  const EnrollmentCard({super.key, this.isDashboard = false});

  /// Kept for API compatibility with the dashboard feed.
  final bool isDashboard;

  @override
  State<EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<EnrollmentCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCardHeader(
            title: "Today's School Status",
            minimized: _minimized,
            onToggle: () => setState(() => _minimized = !_minimized),
          ),

          if (!_minimized) ...[
            const SizedBox(height: 16),

            // ── Capacity summary — three stat columns ─────────────────────
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatColumn(value: '12', label: 'Total Classrooms'),
                ),
                Expanded(
                  child: _StatColumn(value: '120', label: 'Total Capacity'),
                ),
                Expanded(
                  child: _StatColumn(
                    value: '83%',
                    label: 'Full time Equivalent',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Month-over-month trend ────────────────────────────────────
            const Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: AppColors.successColor,
                ),
                SizedBox(width: 6),
                Text(
                  '5% vs last month',
                  style: TextStyle(
                    color: AppColors.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),

            // ── Breakdown bars (shared CustomStatBarCard) ─────────────────
            CustomStatBarCard(
              title: 'Enrolled Students',
              number: '104',
              fullWidthBar: true,
              embedded: true,
              titleFontSize: 14,
              items: _percentItems(
                total: 104,
                raw: const [
                  _Seg('Active', 100, AppColors.lightBlueProgressBar),
                  _Seg('Upcoming', 4, AppColors.mustardProgressBar),
                ],
              ),
            ),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            CustomStatBarCard(
              title: 'Expected Students',
              number: '104',
              fullWidthBar: true,
              embedded: true,
              titleFontSize: 14,
              items: _percentItems(
                total: 104,
                raw: const [
                  _Seg('Signed-in', 15, AppColors.colorBox),
                  _Seg('Absent', 2, AppColors.colorBox2),
                  _Seg('Signed-out', 15, _signedOutColor),
                  _Seg('Not Marked', 72, _notMarkedColor),
                ],
              ),
            ),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            CustomStatBarCard(
              title: 'Expected Staff',
              number: '27',
              fullWidthBar: true,
              embedded: true,
              titleFontSize: 14,
              items: _percentItems(
                total: 27,
                raw: const [
                  _Seg('Signed-in', 23, AppColors.colorBox),
                  _Seg('Absent', 2, AppColors.colorBox2),
                  _Seg('Signed-out', 2, _signedOutColor),
                  _Seg('Not Marked', 0, _notMarkedColor),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single capacity stat (big value + wrapping label) in the summary row.
class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.themeColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // No ellipsis — the label wraps so it stays fully readable.
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
