import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// The 1–5 scale reference card shown on assessment profiles and dashboards
/// (PRD FR-SA-09 / FR-CA-11 / FR-SC-07).
class AssessmentGuideCard extends StatelessWidget {
  const AssessmentGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Guide',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...AssessmentScale.values.map((score) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AssessmentUi.scaleColor(score),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AssessmentScale.labelFor(score),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
