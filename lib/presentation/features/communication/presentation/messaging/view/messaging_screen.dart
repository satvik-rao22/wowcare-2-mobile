import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/communication_providers.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_tab.dart';
import 'package:wowcare/presentation/features/newsletter/view/newsletter_tab.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_direct_messaging_screen.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/model/user_persona.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({
    super.key,
    required this.userPersona,
    this.initialTabIndex = 0,
  });
  final UserPersona userPersona;
  final int initialTabIndex;

  static const String routeName = '/messageFeed';

  /// Deep-link to the Newsletter top-level tab (Messaging vs Newsletter).
  static const String newsletterRoute = '$routeName?tab=newsletter';

  /// Deep-link straight to the Parent Messaging sub-tab (within the
  /// Messaging top-level tab), used by the drawer's "Parent Messaging" item
  /// so it doesn't land on Staff Messaging first.
  static const String parentMessagingRoute = '$routeName?msgTab=parent';

  /// Deep-link straight to the Staff Messaging sub-tab. Admin/Staff now land on
  /// Parent Messaging by default (see the sub-tab resolution in build()), so any
  /// entry that must open Staff Messaging (drawer/launcher "Staff Messaging",
  /// staff-message notifications) uses this explicit route.
  static const String staffMessagingRoute = '$routeName?msgTab=staff';

  /// The inbox location that lists a conversation of [type] — where back from
  /// a thread opened outside the inbox (a chat push-notification tap) lands.
  /// Guardians have no Staff/Parent sub-tabs, and an unknown type keeps the
  /// plain messaging home.
  static String inboxRouteFor(
    ConversationType? type, {
    required bool isParent,
  }) {
    if (isParent || type == null) return routeName;
    switch (type) {
      case ConversationType.staffDirect:
      case ConversationType.classroomChat:
        return staffMessagingRoute;
      case ConversationType.roomChat:
      case ConversationType.adminChat:
        return parentMessagingRoute;
    }
  }

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with
        TickerProviderStateMixin,
        SchoolSwitchReloadMixin,
        TabBecameVisibleMixin {
  // Messaging is branch index 3 in app_router.dart's shell.
  @override
  int get tabBranchIndex => 3;

  @override
  void onTabBecameVisible() {
    if (!mounted) return;
    // Same subtree-recreate trick as onSchoolSwitched() below, triggered by
    // switching back to this tab instead of a school/persona change.
    setState(() => _contextReloadEpoch++);
    // A `msgTab` link targets a Messaging sub-tab, so it must also land on the
    // Messaging top-level tab — even when the user last left this kept-alive
    // screen on Newsletter. didChangeDependencies can't catch that: the `tab`
    // query hasn't changed, and its guard doesn't see manual tab switches.
    // Post-frame, so GoRouterState already reflects the new location.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final msgTab = GoRouterState.of(context).uri.queryParameters['msgTab'];
      if (msgTab == null || msgTab.trim().isEmpty) return;
      _lastAppliedInitialIndex = 0;
      if (_tabController.index != 0) _tabController.animateTo(0);
    });
  }

  late TabController _tabController;
  int? _lastAppliedInitialIndex;
  String? _lastRouteTabQuery;

  // Bumped on a school OR persona switch to re-key (recreate) the
  // CommunicationCubit provider and the Staff/Parent messaging sub-tabs —
  // this branch screen is kept alive in the shell's IndexedStack across
  // both switch kinds and never re-inits on its own, so without this the
  // conversation list/thread state from the previous school/persona kept
  // showing (now pointing at wiped/empty caches) until the user manually
  // navigated away and back.
  //
  // Mandate 2: this stays `setState` deliberately. It is not UI micro-state
  // nor business data — it is a whole-subtree re-key trigger, and the
  // `BlocProvider` it re-keys wraps the entire body, so a `ValueNotifier` +
  // `ValueListenableBuilder` would rebuild exactly the same subtree with no
  // scoping win, while adding risk to load-bearing switch-invalidation.
  int _contextReloadEpoch = 0;

  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    setState(() => _contextReloadEpoch++);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _lastAppliedInitialIndex = widget.initialTabIndex.clamp(0, 1);
    _lastRouteTabQuery = widget.initialTabIndex == 1 ? 'newsletter' : null;
  }

  @override
  void didUpdateWidget(covariant MessagingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 1);
    _lastRouteTabQuery = nextIndex == 1 ? 'newsletter' : null;
    _applyDeepLinkTabIndex(nextIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Shell branches can keep this widget alive; apply drawer deep-links only
    // when the route `tab` query actually changes (not on every rebuild).
    final tabQuery = GoRouterState.of(
      context,
    ).uri.queryParameters['tab']?.trim().toLowerCase();
    if (tabQuery == _lastRouteTabQuery) return;
    _lastRouteTabQuery = tabQuery;
    _applyDeepLinkTabIndex(tabQuery == 'newsletter' ? 1 : 0);
  }

  void _applyDeepLinkTabIndex(int nextIndex) {
    final clamped = nextIndex.clamp(0, 1);
    if (clamped == _lastAppliedInitialIndex) return;
    _lastAppliedInitialIndex = clamped;
    if (_tabController.index != clamped) {
      _tabController.animateTo(clamped);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Always derived live from RoleCubit — widget.userPersona is only the
    // value resolved when this branch's route was first built (go_router's
    // StatefulShellRoute.indexedStack keeps this screen alive across persona
    // switches without rebuilding that route), so it must never be OR'd in
    // here or persona switches would get stuck showing the first persona
    // that ever opened this tab.
    final bool isParentPersona = context.watch<RoleCubit>().isParent;

    // Drives MessagingTab's Staff/Parent sub-tab from the `msgTab` deep-link
    // query param, so the drawer's "Parent Messaging" item lands directly on
    // the Parent Messaging sub-tab instead of always opening Staff Messaging.
    final msgTabQuery = GoRouterState.of(
      context,
    ).uri.queryParameters['msgTab']?.trim().toLowerCase();
    // Admin/Staff default to the Parent Messaging (Parent Communication) sub-tab; only an explicit
    // `msgTab=staff` deep link (drawer/launcher "Staff Messaging", staff-message notifications)
    // opens Staff Messaging. Parents never see these sub-tabs (they get ParentDirectMessagingScreen).
    final messagingSubTabIndex = msgTabQuery == 'staff' ? 0 : 1;

    return BlocProvider<CommunicationCubit>(
      key: ValueKey('communication_cubit_$_contextReloadEpoch'),
      create: (context) => resolveCommunicationCubit(),
      child: GlobalScaffold(
        hasBackButton: !isParentPersona,
        showCustomNavigationBar: !isLandscape,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isParentPersona)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: AppColors.transparentColor,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.themeColor),
                ),
                indicatorPadding: const EdgeInsets.only(bottom: 8),
                labelStyle: AppTextStyles.size16.copyWith(
                  color: AppColors.messagingTabLabel,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: AppTextStyles.size16.copyWith(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
                labelColor: AppColors.messagingTabLabel,
                unselectedLabelColor: AppColors.primaryColor.withValues(
                  alpha: 0.5,
                ),
                tabs: const [
                  Tab(text: AppStrings.messagingTitle),
                  Tab(text: AppStrings.newsletter),
                ],
              ),
            if (isParentPersona)
              const Expanded(child: ParentDirectMessagingScreen())
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MessagingTab(
                      key: ValueKey('messaging_tab_$messagingSubTabIndex'),
                      initialTabIndex: messagingSubTabIndex,
                    ),
                    const NewsLatterTab(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
