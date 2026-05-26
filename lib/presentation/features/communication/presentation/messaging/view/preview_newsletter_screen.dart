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

  @override
  Widget build(BuildContext context) {
    final String bodyHtml = newsletter.bodyHtml.trim();
    final bool hasHtmlBody = bodyHtml.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            newsletter.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (newsletter.subtitle.trim().isNotEmpty) ...[
                  Text(
                    newsletter.subtitle,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _PreviewMetaRow(
                  label: 'Created by',
                  value: newsletter.createdByName.trim().isNotEmpty
                      ? newsletter.createdByName
                      : 'Demo Test',
                ),
                const SizedBox(height: 4),
                _PreviewMetaRow(
                  label: 'Date',
                  value: DateFormat('MMM dd, yyyy').format(
                    newsletter.sentAt ?? newsletter.createdAt ?? DateTime.now(),
                  ),
                ),
                const SizedBox(height: 4),
                _PreviewMetaRow(
                  label: 'Classroom',
                  value: _classroomLabel,
                ),
                const SizedBox(height: 12),
                if (newsletter.attachments.isNotEmpty) ...[
                  NewsletterAttachmentGrid(
                    newsletterId: newsletter.id,
                    attachments: newsletter.attachments,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasHtmlBody)
                  Html(
                    data: bodyHtml,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: AppColors.primaryColor.withValues(alpha: 0.88),
                        lineHeight: const LineHeight(1.45),
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 10),
                      ),
                      'img': Style(
                        width: Width(100, Unit.percent),
                        margin: Margins.only(bottom: 12),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PreviewMetaRow extends StatelessWidget {
  const _PreviewMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.58),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
