import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// The frame every screen sits in: the page tray, a header, the body, and
/// optionally a FAB and a bottom bar.
///
/// [scrollable] wraps the body in a bouncing `SingleChildScrollView` with
/// [bodyPadding] as its padding, so the last card clears the FAB and the tab
/// bar. [onRefresh] adds pull to refresh, which implies scrolling. The FAB is
/// placed where the design puts it: 20 from the right, 16 above the bottom
/// bar.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.body,
    this.header,
    this.fab,
    this.bottomBar,
    this.bodyPadding = AppSizes.bodyPad,
    this.scrollable = false,
    this.onRefresh,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget body;

  /// An `AppHeaderBar`, or nothing. Sits under the status bar inset.
  final Widget? header;

  /// An `AppFab`.
  final Widget? fab;

  /// An `AppTabBar`, or a docked action row.
  final Widget? bottomBar;

  final EdgeInsetsGeometry bodyPadding;
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Scaffold(
      backgroundColor: c.page,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            ?header,
            Expanded(child: _body(c)),
          ],
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: const _AppFabLocation(),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      bottomNavigationBar: bottomBar,
    );
  }

  Widget _body(Colourway c) {
    if (!scrollable && onRefresh == null) {
      return Padding(padding: bodyPadding, child: body);
    }

    final scroll = SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: bodyPadding,
      child: body,
    );

    if (onRefresh == null) return scroll;
    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: c.pink,
      backgroundColor: c.card,
      child: scroll,
    );
  }
}

/// 20 from the right edge, 16 above whatever is at the bottom: the tab bar,
/// a docked action row, or the screen edge. The 16 is what is left of the
/// design's 104px FAB bottom once the 88px tab bar is taken out.
class _AppFabLocation extends FloatingActionButtonLocation {
  const _AppFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    final fab = g.floatingActionButtonSize;
    const gap = AppSizes.fabBottom - AppSizes.tabBarHeight;
    return Offset(
      g.scaffoldSize.width - fab.width - AppSizes.fabRight,
      g.contentBottom - fab.height - gap,
    );
  }
}
