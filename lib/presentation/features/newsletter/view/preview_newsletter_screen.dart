import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/newsletter/cubit/preview_newsletter_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_preview_content.dart';
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
                      NewsletterPreviewContent(newsletter: state.newsletter!),
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
