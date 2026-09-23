import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/preview_newsletter_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_preview_content.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class PreviewNewsletterScreen extends StatefulWidget {
  const PreviewNewsletterScreen({
    super.key,
    required this.newsletterCode,
    this.initialNewsletter,
  });

  final String newsletterCode;
  final Newsletter? initialNewsletter;

  @override
  State<PreviewNewsletterScreen> createState() => _PreviewNewsletterScreenState();
}

class _PreviewNewsletterScreenState extends State<PreviewNewsletterScreen> {
  @override
  void initState() {
    super.initState();
    // §5.4: the cubit is constructed by the GoRoute builder, but the load is
    // triggered here rather than with a `..load()` in that builder. A
    // `pageBuilder` re-runs whenever the branch's route stack changes — a
    // push or a pop of any sibling — and firing the fetch from there would
    // re-request the newsletter on back navigation. `initState` runs once per
    // screen instance, which is exactly the call count the imperative push
    // this replaced produced.
    _load();
  }

  void _load() {
    context.read<PreviewNewsletterCubit>().load(
          newsletterCode: widget.newsletterCode,
          initialNewsletter: widget.initialNewsletter,
        );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: BlocBuilder<PreviewNewsletterCubit, PreviewNewsletterState>(
        builder: (BuildContext context, PreviewNewsletterState state) {
          if (state.isLoading && state.newsletter == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.newsletter == null) {
            // The failure state had no way out but the back button — and this
            // screen is the landing point for the NEWSLETTER_SENT push
            // deep-link, i.e. exactly when connectivity is least reliable.
            return AppErrorState(
              title: AppStrings.newsletterLoadFailed,
              message: state.errorMessage,
              retryLabel: AppStrings.newsletterRetry,
              onRetry: _load,
            );
          }

          return Column(
            children: [
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.xs),
                  child: Material(
                    color: AppColors.newsletterStaleBannerBackground,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xsPlus),
                      child: Text(
                        state.errorMessage!,
                        style: AppTextStyles.newsletterStaleBanner,
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
    );
  }
}
