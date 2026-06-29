import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// The 1–5 scale reference card shown on assessment profiles and dashboards
/// (PRD FR-SA-09 / FR-CA-11 / FR-SC-07).
class AssessmentGuideCard extends StatelessWidget {
  const AssessmentGuideCard({super.key});

  /// Short plain-language descriptor for each scale point (mirrors the web
  /// guide's "Just starting → Fully mastered").
  static const Map<int, String> _descriptors = <int, String>{
    1: 'Just starting',
    2: 'Making progress',
    3: 'Building skills',
    4: 'Nearly there',
    5: 'Fully mastered',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FF), Color(0xFFFBF5FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Assessment Guide',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...AssessmentScale.values.map((score) {
            final color = AssessmentUi.scaleColor(score);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          AssessmentScale.labelFor(score),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '· ${_descriptors[score] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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
