import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/newsletter_staff_scope.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/newsletter_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_classroom_display.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_entity_mapper.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_list_shimmer.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/send_newslatter_list.dart';
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
  List<String> _selectedClassroomNames = <String>[];
  Timer? _searchDebounce;
  bool _isStaffScoped = false;
  String? _primaryClassroomCode;
  List<String> _allowedClassroomCodes = const <String>[];
  bool _scopeResolved = false;
  bool _staffListBootstrapped = false;
  bool _adminListLoaded = false;

  @override
  void initState() {
    super.initState();
    _newsletterListCubit = serviceLocator<NewsletterListCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(force: true, applyAttendanceStaffScope: true);
    searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll);
    _resolveStaffScopeAndLoad();
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

  Future<void> _resolveStaffScopeAndLoad() async {
    final scope = await resolveNewsletterStaffScope();
    if (!mounted) return;
    setState(() {
      _isStaffScoped = scope.isScoped;
      _primaryClassroomCode = scope.primaryClassroomCode;
      _allowedClassroomCodes = scope.allowedClassroomCodes;
      _scopeResolved = true;
    });
    if (!_isStaffScoped && !_adminListLoaded) {
      _adminListLoaded = true;
      await _newsletterListCubit.loadInitial();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _newsletterListCubit.close();
    _classroomCubit.close();
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
      if (_isStaffScoped && !_staffListBootstrapped) return;
      _newsletterListCubit.applyFilters(
        search: searchController.text.trim(),
        classroomCodes: _effectiveClassroomCodesForApi(),
      );
    });
  }

  List<String> _selectedClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) return const <String>[];
    final ClassroomState s = _classroomCubit.state;
    return s.classrooms
        .where(
          (c) => _selectedClassroomNames.any(
            (String name) => c.name.trim() == name.trim(),
          ),
        )
        .map((c) => c.code.trim())
        .where((String code) => code.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _effectiveClassroomCodesForApi() {
    final selected = _selectedClassroomCodes();
    if (!_isStaffScoped) return selected;

    final Set<String> codes = <String>{};
    final primary = (_primaryClassroomCode ?? '').trim();
    if (primary.isNotEmpty) codes.add(primary);
    codes.addAll(selected);

    if (codes.isEmpty && _allowedClassroomCodes.isNotEmpty) {
      codes.add(_allowedClassroomCodes.first);
    }
    return codes.toList();
  }

  void _maybeBootstrapStaffList(ClassroomState classroomState) {
    if (!_scopeResolved || !_isStaffScoped || _staffListBootstrapped) return;
    if (classroomState.isLoading) return;

    final String? primaryName = _primaryClassroomName(classroomState);
    final List<String> defaultNames = <String>[];
    if (primaryName != null && primaryName.isNotEmpty) {
      defaultNames.add(primaryName);
    } else {
      final options = _classroomNameOptions(classroomState);
      if (options.isNotEmpty) defaultNames.add(options.first);
    }

    setState(() {
      _selectedClassroomNames = defaultNames;
      _staffListBootstrapped = true;
    });
    _newsletterListCubit.applyFilters(
      search: searchController.text.trim(),
      classroomCodes: _effectiveClassroomCodesForApi(),
    );
  }

  String? _primaryClassroomName(ClassroomState classroomState) {
    final primaryCode = (_primaryClassroomCode ?? '').trim();
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
      restrictToKnownClassrooms: _isStaffScoped,
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

  Widget _buildSearchAndFilterBox(ClassroomState classroomState) {
    final List<String> roomNames = _classroomNameOptions(classroomState);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomSearchBar(
              controller: searchController,
              hintText: 'Search',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomMultiSelectDropdown(
              hintText: 'Classroom',
              items: roomNames,
              selectedItems: _selectedClassroomNames,
              showSelectAll: true,
              enableSearch: true,
              searchHintText: 'Search classroom',
              onChanged: (List<String> values) {
                setState(() {
                  _selectedClassroomNames = values;
                });
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NewsletterListCubit>.value(value: _newsletterListCubit),
        BlocProvider<ClassroomCubit>.value(value: _classroomCubit),
      ],
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (BuildContext context, ClassroomState classroomState) {
          if (_scopeResolved && _isStaffScoped && !_staffListBootstrapped) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _maybeBootstrapStaffList(classroomState);
            });
          }
          final Map<String, String> nameByCode = _classroomNameByCode(
            classroomState,
          );
          return BlocConsumer<NewsletterListCubit, NewsletterListState>(
            listener: (_, __) {},
            builder: (BuildContext context, NewsletterListState state) {
              return CustomRefreshIndicator(
                onRefresh: _onRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      _buildSearchAndFilterBox(classroomState),
                      const SizedBox(height: 12),
                      Expanded(
                        child:
                            _isStaffScoped &&
                                (!_scopeResolved ||
                                    !_staffListBootstrapped ||
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
                                          padding: const EdgeInsets.all(24),
                                          child: Text(
                                            state.errorMessage ??
                                                'No Sent Newsletters',
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
                                            vertical: 16,
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
                                                DateTime.now(),
                                          );
                                      final String createdBy =
                                          letter.createdByName.trim().isNotEmpty
                                          ? letter.createdByName
                                          : 'Demo Test';
                                      final primaryAttachment =
                                          pickPrimaryListAttachment(letter);
                                      final List<String> derivedAssetCodes =
                                          _extractAssetCodesFromNewsletter(
                                            letter,
                                          );
                                      final Set<String> allCodes = <String>{
                                        ...letter.attachments
                                            .map((a) => a.mediaCode.trim())
                                            .where((c) => c.isNotEmpty),
                                        ...derivedAssetCodes,
                                      };
                                      final String primaryAssetCode =
                                          (primaryAttachment?.mediaCode ?? '')
                                              .trim()
                                              .isNotEmpty
                                          ? primaryAttachment!.mediaCode
                                          : (derivedAssetCodes.isNotEmpty
                                                ? derivedAssetCodes.first
                                                : '');
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
                                          vertical: 8,
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
                                            primaryAttachmentAssetCode:
                                                primaryAssetCode,
                                            primaryAttachmentMimeType: () {
                                              final mime =
                                                  (primaryAttachment
                                                              ?.mimeType ??
                                                          '')
                                                      .trim();
                                              if (mime.isNotEmpty) return mime;
                                              if (primaryAssetCode.isNotEmpty) {
                                                return 'image/*';
                                              }
                                              return null;
                                            }(),
                                            additionalAttachmentCount:
                                                additionalAttachmentCount,
                                          ),
                                          onTap: () {
                                            final String code = letter.code
                                                .trim();
                                            if (code.isEmpty) return;
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder:
                                                    (BuildContext context) =>
                                                        PreviewNewsletterScreen(
                                                          newsletterCode: code,
                                                          initialNewsletter:
                                                              letter,
                                                        ),
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
      ),
    );
  }
}
