import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/extensions/messaging_time_formatter.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity_display.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';
import 'package:wowcare/app/di/conversation_list_cubit_factory.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_filter_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_tile.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/filter_indicator.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
part 'conversation_list_tiles.dart';
part 'conversation_list_chips.dart';

/// Reusable conversation list for STAFF_DIRECT, ROOM_CHAT, and ADMIN_CHAT.
///
/// Accepts [conversationType] and self-provisions a [ConversationListCubit]
/// scoped to this screen's lifetime. The three thin wrapper screens
/// (StaffMessagingScreen, ParentMessagingScreen, AdminChatScreen) simply pass
/// the corresponding type — no business logic lives in those wrappers.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({
    super.key,
    required this.conversationType,
    required this.onConversationTap,
    this.onCreateTap,
    this.title,
  });

  /// Determines which conversations are loaded and how the UI is labelled.
  final ConversationType conversationType;

  /// Called when the user taps a conversation tile.
  final void Function(ConversationEntity conversation) onConversationTap;

  /// Called when the user taps the compose / create FAB.
  /// Pass null to hide the FAB.
  final VoidCallback? onCreateTap;

  /// AppBar title override. Defaults to the type label.
  final String? title;

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // UI-only view state (Mandate 2): the client-side "unread only" toggle and
  // the role/identity resolved once from storage. Client-side filtering only —
  // no API — so these are widget-local. ValueNotifiers rather than `setState`
  // so the list body rebuilds off one merged listenable (with the search
  // controller), preserving the exact rebuild triggers the setStates had.
  final ValueNotifier<bool> _showUnreadOnly = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isGuardian = ValueNotifier<bool>(false);
  final ValueNotifier<String> _currentUserCode = ValueNotifier<String>('');
  late final ConversationListCubit _cubit;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Cubit deps resolved by an app-DI factory (Mandate 5: no serviceLocator in
    // views). This State still owns/closes the cubit — only construction moved.
    _cubit = buildConversationListCubit(
      conversationType: widget.conversationType,
    );
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _initRole();
    unawaited(_cubit.startWatching());
  }

  Future<void> _initRole() async {
    // Read identity through the owning cubit (Mandate 5: no StorageService in
    // views) — same underlying storage read as before.
    final role = await _cubit.readActiveSchoolRole();
    final userCode = (await _cubit.readCurrentUserCode() ?? '').trim();
    if (mounted) {
      _isGuardian.value =
          role?.toUpperCase() == 'GUARDIAN' || role?.toUpperCase() == 'PARENT';
      _currentUserCode.value = userCode;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    unawaited(_cubit.close());
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _showUnreadOnly.dispose();
    _isGuardian.dispose();
    _currentUserCode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Firestore stream auto-loads; no manual pagination needed.
  }

  void _onSearchChanged() {
    // The list body rebuilds via the merged ListenableBuilder (which listens to
    // _searchController); this handler only kicks off the debounced directory
    // search.
    // Only trigger staff directory search for STAFF_DIRECT conversations.
    if (widget.conversationType != ConversationType.staffDirect) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _cubit.searchStaffDirectory(_searchController.text);
    });
  }

  /// Show the filter bottom sheet for STAFF_DIRECT conversations.
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ConversationFilterSheet(),
    );
  }

  // ─── Filter ──────────────────────────────────────────────────────────────────

  List<ConversationEntity> _filtered(List<ConversationEntity> all) {
    final q = _searchController.text.trim().toLowerCase();
    return all.where((c) {
      if (_showUnreadOnly.value && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q)) return false;
      // Room Chat/Admin Chat are student-scoped — by default, hide
      // conversations for withdrawn (INACTIVE) students. UPCOMING is a
      // normal, not-yet-started enrollment state and stays visible.
      // STAFF_DIRECT conversations have no studentStatus at all, so this
      // is a no-op for them.
      final studentStatus = c.studentStatus?.trim().toUpperCase();
      if (studentStatus == 'INACTIVE') {
        return false;
      }
      return true;
    }).toList();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationListCubit>.value(
      value: _cubit,
      child: BlocBuilder<ConversationListCubit, ConversationListState>(
        builder: (context, state) {
          return ListenableBuilder(
            // Rebuild the body when the search text, the unread toggle, or the
            // resolved role/identity changes — the same triggers the removed
            // setStates fired on (the cubit state is handled by BlocBuilder).
            listenable: Listenable.merge([
              _searchController,
              _showUnreadOnly,
              _isGuardian,
              _currentUserCode,
            ]),
            builder: (context, _) {
              return GlobalScaffold(
                hasBackButton: false,

                body: CustomRefreshIndicator(
                  onRefresh: () =>
                      context.read<ConversationListCubit>().refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Search + Unread toggle ────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.messagingSearchFieldBg,
                                ),
                                child: CustomSearchBar(
                                  controller: _searchController,
                                  hintText: AppStrings.searchConversations,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Switch(
                                        value: _showUnreadOnly.value,
                                        activeThumbColor:
                                            AppColors.primaryColor,
                                        onChanged: (v) =>
                                            _showUnreadOnly.value = v,
                                      ),
                                      const SizedBox(width: AppSizes.xxs),
                                      Text(
                                        AppStrings.unreadOnly,
                                        style: AppTextStyles.size14.copyWith(
                                          fontSize: 13,
                                          color: AppColors.messagingTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Filter button (STAFF_DIRECT and ADMIN_CHAT for non-guardians)
                                      if (widget.conversationType ==
                                              ConversationType.staffDirect ||
                                          (widget.conversationType ==
                                                  ConversationType.adminChat &&
                                              !_isGuardian.value))
                                        FilterIndicator(
                                          hasActiveFilters:
                                              state.hasActiveFilters,
                                          filterCount:
                                              state.activeDesignations.length +
                                              state.activeStaffStatuses.length +
                                              state.activeClassroomCodes.length,
                                          onTap: () =>
                                              _showFilterSheet(context),
                                        ),
                                      _TypeChip(type: state.conversationType),
                                    ],
                                  ),
                                ],
                              ),
                              // Active filter chips
                              if (state.hasActiveFilters)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    8,
                                    0,
                                    0,
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      for (final d in state.activeDesignations)
                                        _FilterChip(
                                          label: d,
                                          onRemove: () {
                                            context
                                                .read<ConversationListCubit>()
                                                .applyFilters(
                                                  designations: state
                                                      .activeDesignations
                                                      .where((x) => x != d)
                                                      .toList(),
                                                  staffStatuses:
                                                      state.activeStaffStatuses,
                                                  classroomCodes: state
                                                      .activeClassroomCodes,
                                                );
                                          },
                                        ),
                                      for (final s in state.activeStaffStatuses)
                                        _FilterChip(
                                          label: s,
                                          onRemove: () {
                                            context
                                                .read<ConversationListCubit>()
                                                .applyFilters(
                                                  designations:
                                                      state.activeDesignations,
                                                  staffStatuses: state
                                                      .activeStaffStatuses
                                                      .where((x) => x != s)
                                                      .toList(),
                                                  classroomCodes: state
                                                      .activeClassroomCodes,
                                                );
                                          },
                                        ),
                                      for (final c
                                          in state.activeClassroomCodes)
                                        _FilterChip(
                                          label: c,
                                          onRemove: () {
                                            context
                                                .read<ConversationListCubit>()
                                                .applyFilters(
                                                  designations:
                                                      state.activeDesignations,
                                                  staffStatuses:
                                                      state.activeStaffStatuses,
                                                  classroomCodes: state
                                                      .activeClassroomCodes
                                                      .where((x) => x != c)
                                                      .toList(),
                                                );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // ── Error banner ─────────────────────────────────────────
                      if (state.errorMessage != null && state.hasConversations)
                        SliverToBoxAdapter(
                          child: _ErrorBanner(message: state.errorMessage!),
                        ),

                      // ── Loading (first load, empty list) ─────────────────────
                      if (state.isLoading && !state.hasConversations)
                        const MessagingShimmer(),

                      // ── Full-screen error (no cached data) ───────────────────
                      if (!state.isLoading &&
                          state.errorMessage != null &&
                          !state.hasConversations)
                        SliverFillRemaining(
                          child: _FullScreenError(
                            message: state.errorMessage!,
                            onRetry: () => context
                                .read<ConversationListCubit>()
                                .startWatching(),
                          ),
                        ),

                      // ── List ─────────────────────────────────────────────────
                      if (state.hasConversations || state.isFromCache)
                        _buildList(context, state),

                      // ── Empty state (no conversations and not loading) ────────
                      if (!state.isLoading &&
                          !state.hasConversations &&
                          state.errorMessage == null)
                        SliverFillRemaining(
                          child: _EmptyState(type: state.conversationType),
                        ),

                      // ── Load-more indicator ───────────────────────────────────
                      if (state.isLoading && state.hasConversations)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                            child: Center(
                              child: PrimaryCircularLoader(
                                size: 24,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),

                      // ── Staff directory (STAFF_DIRECT + active search only) ───
                      if (widget.conversationType ==
                              ConversationType.staffDirect &&
                          _searchController.text.trim().isNotEmpty)
                        _buildStaffDirectory(context, state),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
                floatingActionButton: widget.onCreateTap != null
                    ? FloatingActionButton(
                        onPressed: widget.onCreateTap,
                        backgroundColor: AppColors.primaryColor,
                        tooltip: AppStrings.newConversation,
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.messagingOnAccent,
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, ConversationListState state) {
    final filtered = _filtered(state.conversations);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            _showUnreadOnly.value
                ? AppStrings.noUnreadConversations
                : AppStrings.noResultsFor(_searchController.text),
            style: const TextStyle(color: AppColors.messagingTextSecondary),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ConversationListTile(
          conversationCode: filtered[index].code,
          contentBuilder: (context, conversation) => _ConversationTileContent(
            conversation: conversation,
            currentUserCode: _currentUserCode.value,
            onTap: () => widget.onConversationTap(conversation),
          ),
        ),
        childCount: filtered.length,
      ),
    );
  }

  /// Staff directory section — shown below conversations while search is active.
  /// Tapping a staff tile starts (or opens an existing) 1:1 conversation via
  /// the host screen's [onCreateTap] callback with the staff's userCode injected.
  ///
  /// Includes loading, error, and empty states with retry support.
  Widget _buildStaffDirectory(
    BuildContext context,
    ConversationListState state,
  ) {
    // Show error state with retry button
    if (state.hasStaffSearchError) {
      return SliverToBoxAdapter(
        child: AppErrorState(
          title: AppStrings.failedToSearchStaff,
          message: state.staffSearchErrorMessage,
          onRetry: () => context.read<ConversationListCubit>().retryStaffSearch(),
          compact: true,
        ),
      );
    }

    // Show loading indicator
    if (state.isSearchingStaff) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Center(child: PrimaryCircularLoader(size: 20, strokeWidth: 2)),
        ),
      );
    }

    // Show empty state when no results
    if (state.staffSearchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 0),
          child: Text(
            AppStrings.noStaffFoundFor(_searchController.text),
            style: AppTextStyles.size14.copyWith(
              fontSize: 12,
              color: AppColors.messagingTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Show staff directory list
    return SliverMainAxisGroup(
      slivers: [
        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.xxs),
            child: Text(
              AppStrings.staffDirectory,
              style: AppTextStyles.size14.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final staff = state.staffSearchResults[index];
            return _StaffDirectoryTile(
              staff: staff,
              isCreating:
                  state.isSearchingStaff &&
                  state.staffSearchErrorMessage == null,
              onTap: () async {
                // Create or get existing STAFF_DIRECT conversation
                await context
                    .read<ConversationListCubit>()
                    .createOrGetStaffDirectConversation(
                      staff.userCode,
                      staff.name,
                      staff.avatarAssetCode,
                    );
              },
            );
          }, childCount: state.staffSearchResults.length),
        ),
      ],
    );
  }
}

// ─── Staff directory tile ─────────────────────────────────────────────────────
