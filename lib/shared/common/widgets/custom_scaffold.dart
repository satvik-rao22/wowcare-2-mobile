// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:schoolerp/core/common/widgets/custom_app_bar.dart';
// import 'package:schoolerp/core/common/widgets/custom_drawer.dart';
// import 'package:schoolerp/core/common/widgets/custom_navigation_bar.dart';
// import 'package:schoolerp/core/common/widgets/custom_refresh_indicator.dart';
// import 'package:schoolerp/core/common/widgets/gradient_background.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/util/staff_utils.dart';

// class GlobalScaffold extends StatefulWidget {
//   const GlobalScaffold({
//     required this.body,
//     this.hasBackButton = false,
//     this.floatingActionButton,
//     this.showCustomNavigationBar = true,
//     this.customButtonLayout,
//     this.isGloballyScrollable = true,
//     this.isRefreshable = false,
//     this.onRefresh,
//     this.tabs,
//     this.tabController,
//     this.tabBarStyle,
//     super.key,
//   });

//   final Widget body;
//   final bool hasBackButton;
//   final Widget? floatingActionButton;
//   final bool showCustomNavigationBar;
//   final Widget? customButtonLayout;
//   final bool isGloballyScrollable;
//   final bool isRefreshable;
//   final Future<void> Function()? onRefresh;
//   final List<Tab>? tabs;
//   final TabController? tabController;
//   final TabBarStyle? tabBarStyle;

//   @override
//   State<GlobalScaffold> createState() => _GlobalScaffoldState();
// }

// class _GlobalScaffoldState extends State<GlobalScaffold>
//     with TickerProviderStateMixin {
//   late ScrollController _scrollController;
//   bool _isVisible = true;

//   @override
//   void initState() {
//     super.initState();
//     if (context.isPersonnel) StaffUtils.refreshCurrentStaff(context);

//     _scrollController = ScrollController();
//     _scrollController.addListener(_scrollListener);
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollListener() {
//     if (_scrollController.position.userScrollDirection ==
//         ScrollDirection.reverse) {
//       if (_isVisible) {
//         setState(() {
//           _isVisible = false;
//         });
//       }
//     }

//     if (_scrollController.position.userScrollDirection ==
//         ScrollDirection.forward) {
//       if (!_isVisible) {
//         setState(() {
//           _isVisible = true;
//         });
//       }
//     }
//   }

//   Widget _buildBody() {
//     return SafeArea(
//       child: Padding(
//         padding: widget.tabs != null
//             ? _isVisible
//                 ? const EdgeInsets.fromLTRB(8, 48, 8, 0)
//                 : const EdgeInsets.fromLTRB(8, 48, 8, 8)
//             : _isVisible
//                 ? const EdgeInsets.fromLTRB(8, 8, 8, 0)
//                 : const EdgeInsets.all(8),
//         child: widget.isRefreshable
//             ? CustomRefreshIndicator(
//                 onRefresh: widget.onRefresh ?? () async {},
//                 child: widget.body,
//               )
//             : widget.body,
//       ),
//     );
//   }

//   List<Widget> _buildHeaderSlivers(
//     BuildContext context,
//     bool innerBoxIsScrolled,
//   ) {
//     return [
//       SliverOverlapAbsorber(
//         handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
//         sliver: CustomAppBar(
//           hasBackButton: widget.hasBackButton,
//           tabController: widget.tabController,
//           tabBarStyle: widget.tabBarStyle,
//           tabs: widget.tabs,
//         ),
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double navHeight = CustomNavigationBar.navBarHeight > 0
//         ? CustomNavigationBar.navBarHeight
//         : 80; // fallback height until measured

//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: Scaffold(
//         appBar: AppBar(
//           toolbarHeight: 0,
//           scrolledUnderElevation: 0,
//         ),
//         drawer: (context.isPersonnel || context.isGuardian)
//             ? const CustomDrawer()
//             : null,
//         drawerEnableOpenDragGesture: false,
//         body: GradientBackground(
//           child: NestedScrollView(
//             controller: _scrollController,
//             floatHeaderSlivers: true,
//             headerSliverBuilder: _buildHeaderSlivers,
//             body: _buildBody(),
//           ),
//         ),
//         extendBody: true,
//         floatingActionButton: widget.floatingActionButton,
//         bottomNavigationBar: widget.showCustomNavigationBar
//             ? SafeArea(
//                 bottom: true,
//                 top: false,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   height: _isVisible ? navHeight : 0,
//                   child: CustomNavigationBar(
//                     key: CustomNavigationBar.navBarKey, // <-- attach key
//                   ),
//                 ),
//               )
//             : widget.customButtonLayout,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/usecases/get_unread_aggregates_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_unread_count_for_type_usecase.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/unread_badge_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_drawer.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:provider/provider.dart';

class GlobalScaffold extends StatefulWidget {
  const GlobalScaffold({
    required this.body,
    this.hasBackButton = false,
    this.floatingActionButton,
    this.showCustomNavigationBar = true,
    this.isParent = false,
    this.studentList,
    this.customButtonLayout,
    /// When null, defaults to 8 px on all sides.
    this.bodyPadding,
    /// Forces a specific nav-bar slot to highlight regardless of the shell's
    /// current branch. Pass 1 for screens conceptually under the Attendance tab.
    this.activeTabIndexOverride,
    super.key,
  });

  final Widget body;
  final bool hasBackButton;
  final Widget? floatingActionButton;
  final bool showCustomNavigationBar;
  final bool isParent;
  final List<String>? studentList;
  final Widget? customButtonLayout;
  final EdgeInsetsGeometry? bodyPadding;
  final int? activeTabIndexOverride;

  @override
  State<GlobalScaffold> createState() => _GlobalScaffoldState();
}

class _GlobalScaffoldState extends State<GlobalScaffold> {
  bool _showBars = true;
  late final UnreadBadgeCubit _unreadBadgeCubit;

  @override
  void initState() {
    super.initState();
    _unreadBadgeCubit = UnreadBadgeCubit(
      watchUnreadCountForTypeUseCase:
          serviceLocator<WatchUnreadCountForTypeUseCase>(),
      getUnreadAggregatesUseCase: serviceLocator<GetUnreadAggregatesUseCase>(),
    )..startWatching();
  }

  @override
  void dispose() {
    _unreadBadgeCubit.close();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Hide the bottom nav while scrolling DOWN (reverse), reveal it when
    // scrolling UP (forward) — app-wide, since every screen uses this scaffold.
    // The app bar stays pinned regardless (handled in build).
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      final direction = notification.direction;
      if (direction == ScrollDirection.reverse && _showBars) {
        setState(() => _showBars = false);
      } else if (direction == ScrollDirection.forward && !_showBars) {
        setState(() => _showBars = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleCubit>();
    final isParentRole = roleProvider.isParent;

    final appBar = CustomAppBar(
      hasBackButton: widget.hasBackButton,
      isParent: isParentRole || widget.isParent,
      studentList: widget.studentList,
    );

    return BlocProvider<UnreadBadgeCubit>.value(
      value: _unreadBadgeCubit,
      child: GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        // App bar stays pinned; only the bottom nav hides on scroll.
        appBar: appBar,
        drawer: const CustomDrawer(),
        drawerEnableOpenDragGesture: false,
        body: GradientBackground(
          child: SafeArea(
            // Let the Scaffold's appBar handle the top inset; we only
            // inset for bottom so content never goes behind system bars,
            // while always starting directly under the blue header.
            top: false,
            bottom: true,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: Padding(
                padding: widget.bodyPadding ?? const EdgeInsets.all(8),
                child: widget.body,
              ),
            ),
          ),
        ),
        extendBody: true,
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: widget.showCustomNavigationBar
            // Let the bar size to its natural height (same as the attendance
            // screens). AnimatedSize keeps the hide-on-scroll animation by
            // collapsing to zero, without forcing a fixed height that
            // overflows on devices with a large bottom system inset.
            ? AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _showBars
                    ? CustomNavigationBar(
                        activeTabIndexOverride: widget.activeTabIndexOverride,
                      )
                    : const SizedBox.shrink(),
              )
            : widget.customButtonLayout,
      ),
    ),
    );
  }
}
