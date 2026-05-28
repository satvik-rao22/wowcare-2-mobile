import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_report_card.dart';

enum GeneratedReportFileType { xlsx, pdf }

class GeneratedReportItem {
  const GeneratedReportItem({
    required this.fileName,
    required this.generatedAt,
    required this.type,
  });

  final String fileName;
  final DateTime generatedAt;
  final GeneratedReportFileType type;
}

class GeneratedReportsList extends StatelessWidget {
  const GeneratedReportsList({
    super.key,
    required this.items,
    this.onView,
    this.onDownload,
  });

  final List<GeneratedReportItem> items;
  final ValueChanged<GeneratedReportItem>? onView;
  final ValueChanged<GeneratedReportItem>? onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            'Recently Generated Reports',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff573353),
              height: 20 / 16,
            ),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No reports generated yet.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff573353).withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          for (int i = 0; i < items.length; i++) ...[
            GeneratedReportCard(
              item: items[i],
              onView: onView == null ? null : () => onView!(items[i]),
              onDownload:
                  onDownload == null ? null : () => onDownload!(items[i]),
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}
