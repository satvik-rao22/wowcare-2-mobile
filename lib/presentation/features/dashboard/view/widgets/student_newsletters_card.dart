import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';

// ---------------------------------------------------------------------------
// Local mock model – mirrors the shape of NewsletterModel without any entity
// or API dependency.
// ---------------------------------------------------------------------------
class _NewsletterItem {
  const _NewsletterItem({
    required this.title,
    required this.createdBy,
    required this.lastModified,
    required this.recipientCount,
    required this.classroom,
    required this.accentColor,
  });

  final String title;
  final String createdBy;
  final String lastModified;
  final int recipientCount;
  final String classroom;
  final Color accentColor;
}

const List<_NewsletterItem> _mockNewsletters = [
  _NewsletterItem(
    title: 'Spring Picnic Reminder',
    createdBy: 'Sarah Johnson',
    lastModified: 'May 14, 2026',
    recipientCount: 42,
    classroom: 'Sunflower Room',
    accentColor: Color(0xFFFFD54F),
  ),
  _NewsletterItem(
    title: 'Monthly Curriculum Update',
    createdBy: 'David Lee',
    lastModified: 'May 7, 2026',
    recipientCount: 58,
    classroom: 'Butterfly Room',
    accentColor: Color(0xFF80CBC4),
  ),
  _NewsletterItem(
    title: 'Health & Safety Guidelines',
    createdBy: 'Maria Gomez',
    lastModified: 'Apr 29, 2026',
    recipientCount: 35,
    classroom: 'Rainbow Room',
    accentColor: Color(0xFFEF9A9A),
  ),
];

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------
class StudentNewslettersCard extends StatefulWidget {
  const StudentNewslettersCard({super.key});

  @override
  State<StudentNewslettersCard> createState() => _StudentNewslettersCardState();
}

class _StudentNewslettersCardState extends State<StudentNewslettersCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardCardHeader(
              title: 'Newsletter',
              showRedirect: true,
              onRedirect: () {},
              minimized: _minimized,
              onToggle: () => setState(() => _minimized = !_minimized),
            ),
            if (!_minimized) ...[
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockNewsletters.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  return _NewsletterRow(item: _mockNewsletters[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual newsletter row
// ---------------------------------------------------------------------------
class _NewsletterRow extends StatelessWidget {
  const _NewsletterRow({required this.item});

  final _NewsletterItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder image thumbnail
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.article_outlined,
                color: item.accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(label: 'Created by', value: item.createdBy),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.lastModified,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.recipientCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _MetaRow(label: 'Classroom', value: item.classroom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(color: AppColors.primaryColor, fontSize: 13),
        ),
      ],
    );
  }
}
