import 'dart:async';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/app_time.dart';

import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/newsletter_list_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/model/newsletter_list_item_model.dart';
import 'package:wowcare/presentation/features/newsletter/model/newsletter_preview_args.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_classroom_display.dart';
import 'package:wowcare/domain/features/newsletter/services/newsletter_thumbnail_resolver.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_list_shimmer.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/send_newsletter_list.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class SentNewsLetterTab extends StatefulWidget {
  const SentNewsLetterTab({super.key});

  @override
  State<SentNewsLetterTab> createState() => _SentNewsLetterTabState();
}

class _SentNewsLetterTabState extends State<SentNewsLetterTab> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final NewsletterListCubit _newsletterListCubit;
  late final ClassroomCubit _classroomCubit;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Both cubits are constructed by the messaging GoRoute builder (§5).
    // The load stays here: it is what keeps the request count and its timing
    // identical to before, and a `..loadActiveClassrooms()` in the route
    // builder would re-fire on every rebuild of that route (§5.4).
    _newsletterListCubit = context.read<NewsletterListCubit>();
    _classroomCubit = context.read<ClassroomCubit>()
      ..loadActiveClassrooms(force: true, applyAttendanceStaffScope: true);
    searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll);
    _newsletterListCubit.resolveStaffScopeAndLoad();
  }

  void _onScroll() => _maybeLoadNextPage();

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final NewsletterListState state = _newsletterListCubit.state;
    if (state.isLoadingMore || !state.hasMore || state.newsletters.isEmpty) {
      return;
    }
    final position = _scrollController.position;
    // Content shorter than the viewport but more pages exist → fetch next page.
    if (position.maxScrollExtent <= 0) {
      _newsletterListCubit.loadNextPage();
      return;
    }
    // Within 400px of the bottom → fetch next page.
    if (position.pixels >= position.maxScrollExtent - 400) {
      _newsletterListCubit.loadNextPage();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Not closed here any more: the messaging route owns both cubits and
    // closes them when it is disposed. Closing them from the tab would tear
    // down a route-scoped cubit the rest of that route still holds.
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait<void>([
      _newsletterListCubit.refresh(),
      _classroomCubit.loadActiveClassrooms(
        force: true,
        applyAttendanceStaffScope: true,
      ),
    ]);
  }

  void _applyFilters() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      final NewsletterListState state = _newsletterListCubit.state;
      if (state.isStaffScoped && !state.isStaffListBootstrapped) return;

      final List<String> selected = _codesForNames(
        state.selectedClassroomNames,
      );
      // Explicit, even though the bootstrap guard above already covers it:
      // `applyFilters(classroomCodes: null)` means "keep the existing codes",
      // so passing an unresolvable scope straight through would silently reuse
      // whatever was last queried instead of refusing.
      if (_newsletterListCubit.hasUnresolvableScope(selected)) return;

      _newsletterListCubit.applyFilters(
        search: searchController.text.trim(),
        classroomCodes: _newsletterListCubit.effectiveClassroomCodes(selected),
      );
    });
  }

  /// Maps the dropdown's classroom NAMES to codes. Stays in the view: the
  /// mapping lives in ClassroomCubit's state, which the cubit under refactor
  /// does not (and should not) hold.
  List<String> _codesForNames(List<String> names) {
    if (names.isEmpty) return const <String>[];
    final ClassroomState s = _classroomCubit.state;
    return s.classrooms
        .where(
          (c) => names.any((String name) => c.name.trim() == name.trim()),
        )
        .map((c) => c.code.trim())
        .where((String code) => code.isNotEmpty)
        .toSet()
        .toList();
  }

  void _maybeBootstrapStaffList(ClassroomState classroomState) {
    final NewsletterListState state = _newsletterListCubit.state;
    if (!state.isScopeResolved ||
        !state.isStaffScoped ||
        state.isStaffListBootstrapped) {
      return;
    }
    if (classroomState.isLoading) return;

    final String? primaryName = _primaryClassroomName(classroomState);
    final List<String> defaultNames = <String>[];
    if (primaryName != null && primaryName.isNotEmpty) {
      defaultNames.add(primaryName);
    } else {
      final options = _classroomNameOptions(classroomState);
      if (options.isNotEmpty) defaultNames.add(options.first);
    }

    _newsletterListCubit.bootstrapStaffList(
      defaultNames: defaultNames,
      selectedCodes: _codesForNames(defaultNames),
      search: searchController.text.trim(),
    );
  }

  String? _primaryClassroomName(ClassroomState classroomState) {
    final primaryCode = (_newsletterListCubit.state.primaryClassroomCode ?? '')
        .trim();
    if (primaryCode.isEmpty) return null;
    for (final classroom in classroomState.classrooms) {
      if (classroom.code.trim() == primaryCode) {
        final name = classroom.name.trim();
        return name.isNotEmpty ? name : primaryCode;
      }
    }
    return null;
  }

  Map<String, String> _classroomNameByCode(ClassroomState s) {
    return <String, String>{
      for (final c in s.classrooms) c.code.trim(): c.name.trim(),
    };
  }

  List<String> _classroomNameOptions(ClassroomState s) {
    final List<String> names =
        s.classrooms
            .map((c) => c.name.trim())
            .where((String n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return names;
  }

  String _classroomDisplayForLetter(
    Newsletter letter,
    Map<String, String> nameByCode,
  ) {
    return buildNewsletterClassroomLabel(
      classroomCodes: letter.classroomCodes,
      nameByCode: nameByCode,
      restrictToKnownClassrooms: _newsletterListCubit.state.isStaffScoped,
    );
  }

  List<String> _extractAssetCodesFromNewsletter(Newsletter letter) {
    final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
    final String text = '${letter.subtitle}\n${letter.bodyHtml}';
    final Set<String> codes = <String>{};
    for (final RegExpMatch match in codePattern.allMatches(text)) {
      final String code = (match.group(0) ?? '').trim();
      if (code.isNotEmpty) codes.add(code);
    }
    return codes.toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (BuildContext context, ClassroomState classroomState) {
        final Map<String, String> nameByCode = _classroomNameByCode(
          classroomState,
        );
        return BlocConsumer<NewsletterListCubit, NewsletterListState>(
          listener: (_, __) {},
          builder: (BuildContext context, NewsletterListState state) {
            // The bootstrap depends on BOTH cubits — the staff scope from
            // this one, the classroom list from the outer one — so the check
            // lives in the INNER builder. It used to sit in the outer builder,
            // which worked only because `setState` rebuilt the whole State.
            // Now that the scope lives in a cubit, the outer builder does not
            // re-run when it resolves, and a scope that lands after the
            // classroom list would never trigger the bootstrap: the list would
            // sit on its shimmer forever. This builder re-runs for either.
            if (state.isScopeResolved &&
                state.isStaffScoped &&
                !state.isStaffListBootstrapped) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _maybeBootstrapStaffList(classroomState);
              });
            }
            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    _SearchAndFilterBox(
                      searchController: searchController,
                      roomNames: _classroomNameOptions(classroomState),
                      selectedClassroomNames: state.selectedClassroomNames,
                      onClassroomsChanged: (List<String> values) {
                        // The selection drives the list API query, so it is
                        // cubit state (§2 bucket A). The debounce stays here.
                        _newsletterListCubit.selectClassroomNames(values);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Expanded(
                      child:
                          state.isStaffScoped &&
                              (!state.isScopeResolved ||
                                  !state.isStaffListBootstrapped ||
                                  classroomState.isLoading) &&
                              state.newsletters.isEmpty
                          ? const NewsletterListShimmer()
                          : state.isLoading && state.newsletters.isEmpty
                          ? const NewsletterListShimmer()
                          : state.newsletters.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppSizes.xl),
                                        child: Text(
                                          state.errorMessage ??
                                              AppStrings.newsletterNoneSent,
                                          style: AppTextStyles
                                              .newsletterEmptyState,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Builder(
                              builder: (BuildContext context) {
                                // After this list paints, top up the next
                                // page if the content is shorter than the
                                // viewport (mirrors staff_screen.dart).
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  _maybeLoadNextPage();
                                });
                                return ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount:
                                      state.newsletters.length +
                                      (state.isLoadingMore ? 1 : 0),
                                  itemBuilder: (BuildContext context, int index) {
                                    if (index >= state.newsletters.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSizes.md,
                                        ),
                                        child: Center(
                                          child: PrimaryCircularLoader(),
                                        ),
                                      );
                                    }
                                    final Newsletter letter =
                                        state.newsletters[index];
                                    final String sentDate =
                                        DateFormat('MMM dd, yyyy').format(
                                          letter.sentAt ??
                                              letter.createdAt ??
                                              AppTime.now(),
                                        );
                                    final String createdBy =
                                        letter.createdByName.trim().isNotEmpty
                                        ? letter.createdByName
                                        : AppStrings.newsletterUnknownAuthor;
                                    final thumbnail =
                                        resolveSentNewsletterThumbnail(
                                          letter,
                                        );
                                    final List<String> derivedAssetCodes =
                                        _extractAssetCodesFromNewsletter(
                                          letter,
                                        );
                                    final Set<String> allCodes = <String>{
                                      if (thumbnail.assetCode.isNotEmpty)
                                        thumbnail.assetCode,
                                      ...letter.attachments
                                          .map((a) => a.mediaCode.trim())
                                          .where((c) => c.isNotEmpty),
                                      ...derivedAssetCodes,
                                    };
                                    final int additionalAttachmentCount =
                                        allCodes.length > 1
                                        ? allCodes.length - 1
                                        : 0;
                                    final String listKey =
                                        letter.code.trim().isNotEmpty
                                        ? letter.code.trim()
                                        : 'newsletter-$index';
                                    return Padding(
                                      key: ValueKey<String>(listKey),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSizes.xs,
                                      ),
                                      child: NewsletterSentListCard(
                                        key: ValueKey<String>(listKey),
                                        newsLetter: NewsletterListItemModel(
                                          title: letter.title,
                                          classroom:
                                              _classroomDisplayForLetter(
                                                letter,
                                                nameByCode,
                                              ),
                                          sentDate: sentDate,
                                          createdBy: createdBy,
                                          recipientCount:
                                              letter.recipientCount,
                                          recipientNames:
                                              letter.recipientNames,
                                          recipients: letter.recipients,
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
                                          final String code = letter.code
                                              .trim();
                                          if (code.isEmpty) return;
                                          context.push(
                                            NewsletterRoutes.messagingPreview(
                                              code,
                                            ),
                                            extra: NewsletterPreviewArgs(
                                              initialNewsletter: letter,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
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
      },
    );
  }
}

/// Search field + classroom multi-select above the sent-newsletter list.
///
/// A private widget rather than a `_build…()` method: a method returning a
/// Widget cannot be const, cannot take a key, and rebuilds with its whole
/// enclosing widget (§6).
class _SearchAndFilterBox extends StatelessWidget {
  const _SearchAndFilterBox({
    required this.searchController,
    required this.roomNames,
    required this.selectedClassroomNames,
    required this.onClassroomsChanged,
  });

  final TextEditingController searchController;
  final List<String> roomNames;
  final List<String> selectedClassroomNames;
  final ValueChanged<List<String>> onClassroomsChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomSearchBar(
              controller: searchController,
              hintText: AppStrings.newsletterSearchHint,
            ),
          ),
          const SizedBox(width: AppSizes.xsPlus),
          Expanded(
            child: CustomMultiSelectDropdown(
              hintText: AppStrings.newsletterClassroomFilterHint,
              items: roomNames,
              selectedItems: selectedClassroomNames,
              showSelectAll: true,
              enableSearch: true,
              searchHintText: AppStrings.newsletterClassroomSearchHint,
              onChanged: onClassroomsChanged,
            ),
          ),
        ],
      ),
    );
  }
}
