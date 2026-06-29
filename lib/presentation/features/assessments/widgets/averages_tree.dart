import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Expandable Domain → Subdomain → (Milestone) averages tree used by the
/// classroom roll-up and school dashboard. Each domain row shows its colour dot,
/// name, band-coloured average and a rotating chevron; expanding reveals
/// subdomain averages and — when [showMilestones] is on — per-milestone bars.
class AssessmentAveragesTree extends StatefulWidget {
  const AssessmentAveragesTree({
    super.key,
    required this.domains,
    required this.records,
    this.showMilestones = false,
    this.milestoneFilter,
  });

  final List<AssessmentDomain> domains;
  final Iterable<Assessment> records;
  final bool showMilestones;
  final bool Function(AssessmentMilestone)? milestoneFilter;

  @override
  State<AssessmentAveragesTree> createState() => _AssessmentAveragesTreeState();
}

class _AssessmentAveragesTreeState extends State<AssessmentAveragesTree> {
  final Set<String> _open = {};
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    if (!_seeded && widget.domains.isNotEmpty) {
      _seeded = true;
      _open.add(widget.domains.first.id);
    }
    if (widget.domains.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No active domains for this period.',
            style: TextStyle(color: AssessmentUi.inkMuted)),
      );
    }
    return Column(
      children: widget.domains.map(_buildDomain).toList(),
    );
  }

  Widget _buildDomain(AssessmentDomain domain) {
    final avg = AssessmentAggregation.domainAverage(widget.records, domain.id);
    final color = AssessmentUi.domainColor(domain.id);
    final avgColor = AssessmentUi.scoreAccent(avg);
    final open = _open.contains(domain.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AssessmentUi.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (open) {
                _open.remove(domain.id);
              } else {
                _open.add(domain.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      domain.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AssessmentUi.ink,
                      ),
                    ),
                  ),
                  Text(
                    AssessmentAggregation.formatAverage(avg),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: avgColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Color(0xFFB7B1C4)),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: domain.activeSubdomains
                    .map((s) => _buildSubdomain(s))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubdomain(AssessmentSubdomain subdomain) {
    final avg =
        AssessmentAggregation.subdomainAverage(widget.records, subdomain.id);
    final avgColor = AssessmentUi.scoreAccent(avg);
    final milestones = subdomain.activeMilestones
        .where((m) => widget.milestoneFilter?.call(m) ?? true)
        .toList();

    return Container(
      padding: const EdgeInsets.only(top: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF2F0F8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subdomain.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF574F66),
                  ),
                ),
              ),
              Text(
                AssessmentAggregation.formatAverage(avg),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: avgColor,
                ),
              ),
            ],
          ),
          if (widget.showMilestones)
            ...milestones.map((m) => _buildMilestone(m)),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildMilestone(AssessmentMilestone milestone) {
    final avg =
        AssessmentAggregation.milestoneAverage(widget.records, milestone.id);
    final color = AssessmentUi.scoreAccent(avg);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 0, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              milestone.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A8398),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ((avg ?? 0) / 5).clamp(0, 1),
                minHeight: 5,
                backgroundColor: const Color(0xFFF0EEF6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              AssessmentAggregation.formatAverage(avg),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
