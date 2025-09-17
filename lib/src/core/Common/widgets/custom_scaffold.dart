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
//                   ? const EdgeInsets.fromLTRB(8, 48, 8, 0)
//                   : const EdgeInsets.fromLTRB(8, 48, 8, 8)
//             : _isVisible
//             ? const EdgeInsets.fromLTRB(8, 8, 8, 0)
//             : const EdgeInsets.all(8),
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
//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: Scaffold(
//         appBar: AppBar(toolbarHeight: 0, scrolledUnderElevation: 0),
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
//             ? AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 height: _isVisible ? context.navBarHeight : 0,
//                 child: const Wrap(children: [CustomNavigationBar()]),
//               )
//             : widget.customButtonLayout,
//       ),
//     );
//   }
// }
