import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_tab.dart';
import 'package:wowcare/presentation/features/newsletter/view/newsletter_tab.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_direct_messaging_screen.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../../../app/theme/colors.dart';

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

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int? _lastAppliedInitialIndex;
  String? _lastRouteTabQuery;

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
    final tabQuery =
        GoRouterState.of(context).uri.queryParameters['tab']?.trim().toLowerCase();
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
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isParentPersona =
        widget.userPersona == UserPersona.parent ||
        context.watch<RoleCubit>().isParent;

    // Drives MessagingTab's Staff/Parent sub-tab from the `msgTab` deep-link
    // query param, so the drawer's "Parent Messaging" item lands directly on
    // the Parent Messaging sub-tab instead of always opening Staff Messaging.
    final msgTabQuery = GoRouterState.of(context).uri.queryParameters['msgTab']
        ?.trim()
        .toLowerCase();
    final messagingSubTabIndex = msgTabQuery == 'parent' ? 1 : 0;

    return BlocProvider<CommunicationCubit>(
      create: (context) => serviceLocator<CommunicationCubit>(),
      child: GlobalScaffold(
        hasBackButton: widget.userPersona == UserPersona.parent ? false : true,
        showCustomNavigationBar: !isLandscape,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isParentPersona)
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.themeColor),
                ),
                indicatorPadding: const EdgeInsets.only(bottom: 8),
                labelStyle: const TextStyle(
                  color: Color(0xFF241631),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                ),
                labelColor: const Color(0xFF241631),
                unselectedLabelColor: AppColors.primaryColor.withValues(
                  alpha: 0.5,
                ),
                tabs: const [
                  Tab(text: 'Messaging'),
                  Tab(text: 'Newsletter'),
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
