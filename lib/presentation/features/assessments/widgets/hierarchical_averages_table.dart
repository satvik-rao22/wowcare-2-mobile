import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';

/// Read-only Domain → Subdomain → Milestone averages table shared by the
/// Classroom Assessment Profile (PRD §13.2) and the School Assessment dashboard
/// (§14.1). Averages use the shared exclude-unscored formula (BR-CA-01) and
/// render to one decimal place (FR-CA-09). A milestone with no scores shows "—".
class HierarchicalAveragesTable extends StatelessWidget {
  const HierarchicalAveragesTable({
    super.key,
    required this.title,
    required this.domains,
    required this.records,
    this.milestoneFilter,
  });

  final String title;

  /// Active domains to render.
  final List<AssessmentDomain> domains;

  /// Assessment records already scoped to the relevant students + period.
  final Iterable<Assessment> records;

  /// Optional predicate to limit which milestones are listed (e.g. only those
  /// assigned to a classroom). When null, all active milestones are shown.
  final bool Function(AssessmentMilestone)? milestoneFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (domains.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No assessments recorded for this period.',
                  style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...domains.map((d) => _buildDomain(context, d)),
        ],
      ),
    );
  }

  Widget _buildDomain(BuildContext context, AssessmentDomain domain) {
    final subdomains = domain.activeSubdomains
        .map((s) => MapEntry(
              s,
              s.activeMilestones
                  .where((m) => milestoneFilter?.call(m) ?? true)
                  .toList(),
            ))
        .where((e) => e.value.isNotEmpty)
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(domain.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ScoreBadge(
                score:
                    AssessmentAggregation.domainAverage(records, domain.id)),
          ],
        ),
        subtitle: domain.description.isEmpty
            ? null
            : Text(domain.description,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
        children: subdomains.map((entry) {
          final subdomain = entry.key;
          final milestones = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.themeColor),
                    Expanded(
                      child: Text(subdomain.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    ScoreBadge(
                      dense: true,
                      score: AssessmentAggregation.subdomainAverage(
                          records, subdomain.id),
                    ),
                  ],
                ),
              ),
              ...milestones.map((m) => Padding(
                    padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(m.name,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade800)),
                        ),
                        Text(
                          AssessmentAggregation.formatAverage(
                            AssessmentAggregation.milestoneAverage(
                                records, m.id),
                          ),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
