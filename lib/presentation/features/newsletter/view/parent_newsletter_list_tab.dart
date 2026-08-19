import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_entity.dart';
import 'package:wowcare/presentation/features/newsletter/util/newsletter_entity_mapper.dart';
import 'package:wowcare/presentation/features/newsletter/util/newsletter_thumbnail_resolver.dart';
import 'package:wowcare/presentation/features/newsletter/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_list_shimmer.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/send_newslatter_list.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class ParentNewsletterListTab extends StatefulWidget {
  const ParentNewsletterListTab({super.key});

  @override
  State<ParentNewsletterListTab> createState() =>
      _ParentNewsletterListTabState();
}

class _ParentNewsletterListTabState extends State<ParentNewsletterListTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

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
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _onRefresh(BuildContext context) async {
    final code = (context.read<ParentChildCubit>().selectedChild?.code ?? '')
        .trim();
    if (code.isEmpty) return;
    await context.read<StudentNewslettersCubit>().loadFirstPage(
      studentCode: code,
      forceRefresh: true,
    );
  }

  List<NewsletterEntity> _filterItems(List<NewsletterEntity> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((NewsletterEntity item) {
      final haystack = '${item.title} ${item.subtitle} ${item.createdByName}'
          .toLowerCase();
      return haystack.contains(_searchQuery);
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
        final filtered = _filterItems(state.items);

        return CustomRefreshIndicator(
          onRefresh: () => _onRefresh(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                SkeuPanel(
                  radius: SkeuRadius.xxl,
                  padding: const EdgeInsets.all(12),

                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: studentCode.isEmpty
                      ? _emptyMessage('Select a child to view newsletters.')
                      : state.isLoading && state.items.isEmpty
                      ? const NewsletterListShimmer()
                      : filtered.isEmpty
                      ? _emptyScrollable(
                          state.errorMessage.isNotEmpty
                              ? state.errorMessage
                              : 'No Newsletters',
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.pixels <
                                notification.metrics.maxScrollExtent - 120) {
                              return false;
                            }
                            if (state.hasMore && !state.isPaginationLoading) {
                              context
                                  .read<StudentNewslettersCubit>()
                                  .loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                filtered.length +
                                (state.isPaginationLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: PrimaryCircularLoader()),
                                );
                              }

                              final NewsletterEntity entity = filtered[index];
                              final previewNewsletter =
                                  mapNewsletterEntityToNewsletter(entity);
                              final sentDate = DateFormat('MMM dd, yyyy')
                                  .format(
                                    entity.updatedAt ??
                                        entity.createdAt ??
                                        AppTime.now(),
                                  );
                              final createdBy =
                                  entity.createdByName.trim().isNotEmpty
                                  ? entity.createdByName.trim()
                                  : '-';
                              final thumbnail = resolveNewsletterThumbnail(
                                entity,
                              );
                              final derivedAssetCodes =
                                  extractAssetCodesFromNewsletterEntity(entity);
                              final Set<String> allCodes = <String>{
                                if (thumbnail.assetCode.isNotEmpty)
                                  thumbnail.assetCode,
                                ...previewNewsletter.attachments
                                    .map((a) => a.mediaCode.trim())
                                    .where((c) => c.isNotEmpty),
                                ...derivedAssetCodes,
                              };
                              final int additionalAttachmentCount =
                                  allCodes.length > 1 ? allCodes.length - 1 : 0;
                              final listKey = entity.code.trim().isNotEmpty
                                  ? entity.code.trim()
                                  : 'parent-newsletter-$index';

                              return Padding(
                                key: ValueKey<String>(listKey),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: NewsletterSentListCard(
                                  showRecipientCount: false,
                                  newsLetter: NewsletterListItemModel(
                                    title: entity.title,
                                    classroom: classroomLabel,
                                    sentDate: sentDate,
                                    createdBy: createdBy,
                                    recipientCount: entity.recipientCount,
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PreviewNewsletterScreen(
                                          newsletterCode: code,
                                          initialNewsletter: previewNewsletter,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
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
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
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
