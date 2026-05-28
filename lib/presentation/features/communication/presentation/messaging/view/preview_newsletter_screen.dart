import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
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

  bool _looksLikeStructuredPayload(String value) {
    final String text = value.trim();
    if (text.isEmpty) return false;
    if ((text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'))) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('"parts"') ||
        lower.contains('"imageurl"') ||
        lower.contains('"type"');
  }

  List<NewsletterAttachment> _effectiveAttachments() {
    final List<NewsletterAttachment> base = newsletter.attachments;
    final Set<String> seenCodes = base
        .map((NewsletterAttachment a) => a.mediaCode.trim().toUpperCase())
        .where((String c) => c.isNotEmpty)
        .toSet();

    final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
    final String searchText = '${newsletter.subtitle}\n${newsletter.bodyHtml}';
    final Iterable<RegExpMatch> matches = codePattern.allMatches(searchText);

    final List<NewsletterAttachment> derived = <NewsletterAttachment>[];
    for (final RegExpMatch m in matches) {
      final String code = (m.group(0) ?? '').trim();
      if (code.isEmpty) continue;
      final String normalized = code.toUpperCase();
      if (seenCodes.contains(normalized)) continue;
      seenCodes.add(normalized);
      derived.add(
        NewsletterAttachment(
          id: -derived.length - 1,
          mediaCode: code,
          fileName: '',
          mimeType: 'image/*',
        ),
      );
    }

    if (base.isEmpty) return derived;
    return <NewsletterAttachment>[...base, ...derived];
  }

  @override
  Widget build(BuildContext context) {
    final String rawSubtitle = newsletter.subtitle.trim();
    final String subtitle =
        _looksLikeStructuredPayload(rawSubtitle) ? '' : rawSubtitle;
    final List<NewsletterAttachment> effectiveAttachments =
        _effectiveAttachments();

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
                if (subtitle.isNotEmpty) ...[
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (effectiveAttachments.isNotEmpty) ...[
                  NewsletterAttachmentGrid(
                    newsletterId: newsletter.id,
                    attachments: effectiveAttachments,
                    crossAxisCount: 1,
                    childAspectRatio: 2.2,
                    showFileName: false,
                  ),
                  const SizedBox(height: 12),
                ] else
                  Text(
                    'No attachments available.',
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
