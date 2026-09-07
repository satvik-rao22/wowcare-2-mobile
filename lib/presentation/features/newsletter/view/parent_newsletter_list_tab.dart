import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';

import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/newsletter/model/newsletter_list_item_model.dart';
import 'package:wowcare/presentation/features/newsletter/model/newsletter_preview_args.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_entity.dart';
import 'package:wowcare/data/features/newsletter/mappers/newsletter_entity_mapper.dart';
import 'package:wowcare/domain/features/newsletter/services/newsletter_thumbnail_resolver.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_list_shimmer.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/send_newsletter_list.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class ParentNewsletterListTab extends StatefulWidget {
  const ParentNewsletterListTab({super.key});

  @override
  State<ParentNewsletterListTab> createState() => _ParentNewsletterListTabState();
}

class _ParentNewsletterListTabState extends State<ParentNewsletterListTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  /// Client-side search over the page the cubit already holds. UI micro-state
  /// (§2 bucket B): it never reaches the API, never leaves this widget and is
  /// read by nothing else. Contrast `SentNewsLetterTab`, whose search IS a
  /// query parameter and therefore lives in its cubit.
  ///
  /// A final field, not created in `build()`, and disposed below.
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _searchQuery.value = _searchController.text.trim().toLowerCase();
    });
  }

  /// Pulls the next page when the list cannot ask for one by scrolling.
  ///
  /// Search here is CLIENT-SIDE over the loaded pages — the student endpoint
  /// takes only `status`/`page`/`size`, so there is no server-side query to
  /// delegate to. That made the old behaviour wrong in a specific way: a
  /// search narrowing 10 loaded rows down to 2 leaves a list shorter than the
  /// viewport, `ScrollNotification` never fires because there is nothing to
  /// scroll, and pagination stalls forever. A newsletter on page 3 was simply
  /// unreachable, reported as "No Newsletters".
  ///
  /// So pagination is driven by two things now: the user scrolling (unchanged)
  /// and this, which fires when scrolling is not possible or the search has no
  /// matches yet.
  ///
  /// Terminates because `hasMore` comes from the server and every path is
  /// gated on it. It deliberately does NOT retry after a failure — `loadMore`
  /// leaves `hasMore` true when a page fails, so retrying here would hammer a
  /// failing endpoint.
  void _scheduleAutoPaginate({
    required StudentNewslettersState state,
    required String query,
    required int visibleCount,
  }) {
    if (!state.hasMore ||
        state.isPaginationLoading ||
        state.errorMessage.isNotEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<StudentNewslettersCubit>();
      final latest = cubit.state;
      if (!latest.hasMore ||
          latest.isPaginationLoading ||
          latest.errorMessage.isNotEmpty) {
        return;
      }
      final bool cannotScroll = !_scrollController.hasClients ||
          _scrollController.position.maxScrollExtent <= 0;
      // Nothing matched yet, or the list is too short to scroll: the user has
      // no way to ask for the next page, so ask for it on their behalf.
      if (visibleCount == 0 || cannotScroll) cubit.loadMore();
    });
  }

  Future<void> _onRefresh(BuildContext context) async {
    final code =
        (context.read<ParentChildCubit>().selectedChild?.code ?? '').trim();
    if (code.isEmpty) return;
    await context.read<StudentNewslettersCubit>().loadFirstPage(
          studentCode: code,
          forceRefresh: true,
        );
  }

  List<NewsletterEntity> _filterItems(
    List<NewsletterEntity> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    return items.where((NewsletterEntity item) {
      final haystack =
          '${item.title} ${item.subtitle} ${item.createdByName}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String _classroomLabel(ParentChildCubit parentChild) {
    final child = parentChild.selectedChild;
    final name = (child?.primaryClassroomName ?? child?.classroom ?? '')
        .toString()
        .trim();
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final parentChild = context.watch<ParentChildCubit>();
    final classroomLabel = _classroomLabel(parentChild);
    final studentCode = (parentChild.selectedChild?.code ?? '').trim();

    return BlocBuilder<StudentNewslettersCubit, StudentNewslettersState>(
      builder: (context, state) {
        return CustomRefreshIndicator(
          onRefresh: () => _onRefresh(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    border: Border.all(color: AppColors.cardBorderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: AppStrings.newsletterSearchHint,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    // The two branches that do NOT depend on the query are
                    // built once here and handed to the builder untouched —
                    // typing in the search box never rebuilds them. Null means
                    // "neither applies", so the builder falls through to the
                    // branches that do filter. Branch order is unchanged.
                    child: studentCode.isEmpty
                        ? _emptyMessage(AppStrings.newsletterSelectChild)
                        : state.isLoading && state.items.isEmpty
                            ? const NewsletterListShimmer()
                            : null,
                    builder:
                        (BuildContext context, String query, Widget? child) {
                      if (child != null) return child;
                      final filtered = _filterItems(state.items, query);
                      _scheduleAutoPaginate(
                        state: state,
                        query: query,
                        visibleCount: filtered.length,
                      );
                      return filtered.isEmpty
                          ? _emptyScrollable(
                              _emptyStateMessage(state: state, query: query),
                            )
                          : NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification.metrics.pixels <
                                        notification.metrics.maxScrollExtent -
                                            120) {
                                      return false;
                                    }
                                    if (state.hasMore &&
                                        !state.isPaginationLoading) {
                                      context
                                          .read<StudentNewslettersCubit>()
                                          .loadMore();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: filtered.length +
                                        (state.isPaginationLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= filtered.length) {
                                        return const Padding(
                                          padding: EdgeInsets.all(AppSizes.md),
                                          child: Center(
                                            child: PrimaryCircularLoader(),
                                          ),
                                        );
                                      }

                                      final NewsletterEntity entity =
                                          filtered[index];
                                      final previewNewsletter =
                                          mapNewsletterEntityToNewsletter(
                                        entity,
                                      );
                                      final sentDate = DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(
                                        entity.updatedAt ??
                                            entity.createdAt ??
                                            AppTime.now(),
                                      );
                                      final createdBy =
                                          entity.createdByName.trim().isNotEmpty
                                              ? entity.createdByName.trim()
                                              : AppStrings
                                                  .newsletterUnknownAuthor;
                                      final thumbnail =
                                          resolveNewsletterThumbnail(entity);
                                      final derivedAssetCodes =
                                          extractAssetCodesFromNewsletterEntity(
                                        entity,
                                      );
                                      final Set<String> allCodes = <String>{
                                        if (thumbnail.assetCode.isNotEmpty)
                                          thumbnail.assetCode,
                                        ...previewNewsletter.attachments
                                            .map((a) => a.mediaCode.trim())
                                            .where((c) => c.isNotEmpty),
                                        ...derivedAssetCodes,
                                      };
                                      final int additionalAttachmentCount =
                                          allCodes.length > 1
                                              ? allCodes.length - 1
                                              : 0;
                                      final listKey = entity.code.trim().isNotEmpty
                                          ? entity.code.trim()
                                          : 'parent-newsletter-$index';

                                      return Padding(
                                        key: ValueKey<String>(listKey),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSizes.xs,
                                        ),
                                        child: NewsletterSentListCard(
                                          showRecipientCount: false,
                                          newsLetter: NewsletterListItemModel(
                                            title: entity.title,
                                            classroom: classroomLabel,
                                            sentDate: sentDate,
                                            createdBy: createdBy,
                                            recipientCount:
                                                entity.recipientCount,
                                            primaryAttachmentAssetCode:
                                                thumbnail.assetCode.isNotEmpty
                                                    ? thumbnail.assetCode
                                                    : null,
                                            primaryAttachmentDirectUrl:
                                                thumbnail.directUrl.isNotEmpty
                                                    ? thumbnail.directUrl
                                                    : null,
                                            primaryAttachmentMimeType:
                                                thumbnail.mimeType.isNotEmpty
                                                    ? thumbnail.mimeType
                                                    : null,
                                            additionalAttachmentCount:
                                                additionalAttachmentCount,
                                          ),
                                          onTap: () {
                                            final code = entity.code.trim();
                                            if (code.isEmpty) return;
                                            context.push(
                                              NewsletterRoutes.dashboardPreview(
                                                code,
                                              ),
                                              extra: NewsletterPreviewArgs(
                                                initialNewsletter:
                                                    previewNewsletter,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Which "nothing here" message applies.
  ///
  /// The old code showed "No Newsletters" for all three cases, which is how a
  /// search that had simply not paged far enough looked identical to a child
  /// with no newsletters at all.
  String _emptyStateMessage({
    required StudentNewslettersState state,
    required String query,
  }) {
    if (state.errorMessage.isNotEmpty) return state.errorMessage;
    if (query.isEmpty) return AppStrings.newsletterNoneParent;
    // Searching, no match YET, but pages are still arriving.
    if (state.hasMore || state.isPaginationLoading) {
      return AppStrings.newsletterSearching;
    }
    return AppStrings.newsletterNoSearchMatches;
  }

  Widget _emptyMessage(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Text(
                  message,
                  style: AppTextStyles.newsletterEmptyState,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyScrollable(String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Text(
                  message,
                  style: AppTextStyles.newsletterEmptyState,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
