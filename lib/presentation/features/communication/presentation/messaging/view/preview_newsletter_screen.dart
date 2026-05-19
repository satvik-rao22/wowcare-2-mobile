import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/preview_newsletter_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_attachment_grid.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class PreviewNewsletterScreen extends StatefulWidget {
  const PreviewNewsletterScreen({
    super.key,
    required this.newsletterCode,
    this.initialNewsletter,
  });

  static const String routeName = 'preview-newsletter-screen';

  final String newsletterCode;
  final Newsletter? initialNewsletter;

  @override
  State<PreviewNewsletterScreen> createState() => _PreviewNewsletterScreenState();
}

class _PreviewNewsletterScreenState extends State<PreviewNewsletterScreen> {
  late final PreviewNewsletterCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<PreviewNewsletterCubit>()
      ..load(
        newsletterCode: widget.newsletterCode,
        initialNewsletter: widget.initialNewsletter,
      );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PreviewNewsletterCubit>.value(
      value: _cubit,
      child: GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: false,
        body: BlocBuilder<PreviewNewsletterCubit, PreviewNewsletterState>(
          builder: (BuildContext context, PreviewNewsletterState state) {
            if (state.isLoading && state.newsletter == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.newsletter == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.errorMessage ?? 'Unable to load newsletter.',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      _NewsletterPreviewBody(newsletter: state.newsletter!),
                      if (state.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NewsletterPreviewBody extends StatelessWidget {
  const _NewsletterPreviewBody({required this.newsletter});

  final Newsletter newsletter;

  String get _classroomLabel {
    if (newsletter.classroomCodes.isEmpty) return 'All Classrooms';
    return newsletter.classroomCodes.join(', ');
  }

  String get _sentDateLabel {
    final DateTime? date = newsletter.sentAt ?? newsletter.createdAt;
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final String bodyHtml = newsletter.bodyHtml.trim();
    final bool hasHtmlBody = bodyHtml.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsletter.title,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (newsletter.subtitle.trim().isNotEmpty &&
                    newsletter.subtitle.trim() != newsletter.title.trim()) ...[
                  const SizedBox(height: 6),
                  Text(
                    newsletter.subtitle,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _MetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: _sentDateLabel.isEmpty ? 'Sent date unavailable' : _sentDateLabel,
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.meeting_room_outlined,
                  label: _classroomLabel,
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.people_outline,
                  label: '${newsletter.recipientCount} recipients',
                ),
                if (newsletter.status.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _StatusChip(status: newsletter.status),
                ],
                const SizedBox(height: 16),
                if (hasHtmlBody)
                  Html(
                    data: bodyHtml,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: AppColors.primaryColor,
                        lineHeight: const LineHeight(1.4),
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 8),
                      ),
                    },
                  )
                else
                  Text(
                    'No preview content available.',
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 16),
                NewsletterAttachmentGrid(
                  newsletterId: newsletter.id,
                  attachments: newsletter.attachments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryColor.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.classroomStudentTabColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.themeColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
