import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class TabBarStyle {
  final TabAlignment? tabAlignment;
  final Decoration? indicator;
  final EdgeInsetsGeometry? indicatorPadding;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final double? indicatorWeight;
  final TabBarIndicatorSize? indicatorSize;
  final bool? isScrollable;

  const TabBarStyle({
    this.tabAlignment,
    this.indicator,
    this.indicatorPadding,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorWeight,
    this.indicatorSize,
    this.isScrollable,
  });
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    this.hasBackButton = false,
    this.tabs,
    this.tabController,
    this.tabBarStyle,
    super.key,
  });

  final bool hasBackButton;
  final List<Tab>? tabs;
  final TabController? tabController;
  final TabBarStyle? tabBarStyle;

  @override
	Size get preferredSize => Size.fromHeight(
			kToolbarHeight + (tabs != null ? kTextTabBarHeight : 0.0));

  @override
  Widget build(BuildContext context) {
		final bool hasTabs = tabs != null && tabController != null && tabs!.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
        ),
      ),
			titleSpacing: 0,
			title: Row(
                children: [
					const SizedBox(width: 8),
					Image.asset(MediaRes.logo_wow, height: 28),
					const SizedBox(width: 8),
					const Text('WowCare'),
				],
			),
			leading: hasBackButton
          ? IconButton(
							icon: const Icon(Icons.arrow_back),
							onPressed: () => Navigator.maybePop(context),
						)
					: null,
			bottom: hasTabs
					? TabBar(
							controller: tabController,
							tabAlignment: tabBarStyle?.tabAlignment ?? TabAlignment.center,
							indicator: tabBarStyle?.indicator,
							indicatorPadding: tabBarStyle?.indicatorPadding ?? EdgeInsets.zero,
							isScrollable: tabBarStyle?.isScrollable ?? false,
							labelColor: tabBarStyle?.labelColor ?? Colors.white,
							unselectedLabelColor: tabBarStyle?.unselectedLabelColor ?? Colors.white70,
							indicatorWeight: tabBarStyle?.indicatorWeight ?? 2,
							indicatorSize: tabBarStyle?.indicatorSize,
							splashFactory: NoSplash.splashFactory,
							labelStyle: tabBarStyle?.labelStyle,
							unselectedLabelStyle: tabBarStyle?.unselectedLabelStyle,
							tabs: tabs!,
                )
              : null,
		);
	}
}
