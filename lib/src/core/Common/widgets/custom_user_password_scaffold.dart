import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:wowcare/src/core/extentions/context_extentions.dart';

import 'custom_app_bar.dart';
import 'custom_drawer.dart';
import 'gradient_background.dart';
import 'reusable_password_change_button.dart';

class UserPasswordChangeGlobalScaffold extends StatefulWidget {
  const UserPasswordChangeGlobalScaffold({
    required this.body,
    this.hasBackButton = false,
    this.floatingActionButton,
    this.showCustomNavigationBar = true,
    this.customButtonLayout,
    this.isGloballyScrollable = true,
    super.key,
  });

  final Widget body;
  final bool hasBackButton;
  final Widget? floatingActionButton;
  final bool showCustomNavigationBar;
  final Widget? customButtonLayout;
  final bool isGloballyScrollable;

  @override
  State<UserPasswordChangeGlobalScaffold> createState() =>
      _UserPasswordChangeGlobalScaffoldState();
}

class _UserPasswordChangeGlobalScaffoldState
    extends State<UserPasswordChangeGlobalScaffold> {
  late ScrollController _scrollController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isVisible) {
        setState(() {
          _isVisible = false;
        });
      }
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
        });
      }
    }
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: _isVisible
            ? const EdgeInsets.fromLTRB(8, 8, 8, 0)
            : const EdgeInsets.all(8),
        child: widget.body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0, scrolledUnderElevation: 0),
        drawer: const CustomDrawer(),
        drawerEnableOpenDragGesture: false,
        body: GradientBackground(
          child: NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: CustomAppBar(hasBackButton: widget.hasBackButton),
              ),
            ],
            body: _buildBody(),
          ),
        ),
        extendBody: true,
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: widget.showCustomNavigationBar
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _isVisible ? context.navBarHeight : 0,
                child: Wrap(children: [ReusablePasswordActionButtons()]),
              )
            : widget.customButtonLayout,
      ),
    );
  }
}
