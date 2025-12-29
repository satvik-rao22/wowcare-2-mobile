import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';

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
    this.notificationCount = 0,
		this.isParent = false,
		this.studentList,
    super.key,
  });

  final bool hasBackButton;
  final List<Tab>? tabs;
  final TabController? tabController;
  final TabBarStyle? tabBarStyle;
  final int notificationCount;
	final bool isParent;
	final List<String>? studentList;

  @override
	Size get preferredSize => Size.fromHeight(
			kToolbarHeight + (tabs != null ? kTextTabBarHeight : 0.0));

  @override
  Widget build(BuildContext context) {
		final bool hasTabs = tabs != null && tabController != null && tabs!.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black,
			titleSpacing: 0,
			title: isParent? Padding(
			  padding: const EdgeInsets.only(left: 20),
			  child: SizedBox(width: 180,child: CustomDropdown(hintText: 'Select child', items: studentList!)),
			):null,
			leading: hasBackButton
	          ? IconButton(
						icon: SvgPicture.asset(MediaRes.backButton),
						onPressed: () => Navigator.maybePop(context),
						)
					: Builder(
							builder: (context) => IconButton(
								icon: SvgPicture.asset(MediaRes.hamburgerIcon),
								onPressed: () => Scaffold.of(context).openDrawer(),
							),
					),
			actions: [
				IconButton(
					icon: SvgPicture.asset(MediaRes.chatsIcon, width: 22, height: 22),
					onPressed: () {},
				),
				Stack(
					children: [
						IconButton(
							icon: SvgPicture.asset(MediaRes.notificationsIcon, width: 22, height: 22),
							onPressed: () {},
						),
						if (notificationCount > 0)
							Positioned(
								right: 8,
								top: 8,
								child: Container(
									padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
									decoration: BoxDecoration(
										color: const Color.fromRGBO(179, 38, 30, 1),
										borderRadius: BorderRadius.circular(10),
									),
									child: Text(
										notificationCount > 99 ? '99+' : '$notificationCount',
										style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
									),
								),
						),
					],
				),
				PopupMenuButton<int>(
					icon: SvgPicture.asset(MediaRes.kebabMenu, width: 22, height: 22),
					offset: const Offset(0, 48),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
					itemBuilder: (context) => [
						const PopupMenuItem<int>(
							enabled: false,
							height: 120,
							child: Center(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										CircleAvatar(radius: 30, child: Text('W', style: TextStyle(fontSize: 24))),
										SizedBox(height: 8),
										Text('WowCare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
										Text('User', style: TextStyle(fontSize: 12, color: Colors.grey)),
									],
								),
							),
						),
						PopupMenuItem<int>(
							value: 1,
            child: Row(children: const [Icon(Icons.person, color: Colors.black87), SizedBox(width: 12), Text('My Profile')]),
						),
						PopupMenuItem<int>(
							value: 2,
            child: Row(children: const [Icon(Icons.lock_outline, color: Colors.black87), SizedBox(width: 12), Text('Change Password')]),
						),
						PopupMenuItem<int>(
							value: 3,
            child: Row(children: const [Icon(Icons.help_outline, color: Colors.black87), SizedBox(width: 12), Text('Help')]),
						),
						PopupMenuItem<int>(
							value: 4,
            child: Row(children: const [Icon(Icons.logout, color: Colors.black87), SizedBox(width: 12), Text('Logout')]),
						),
					],
					onSelected: (value) async {
						switch (value) {
							case 1:
								// Navigate to profile if available
								ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Profile')));
								break;
							case 2:
								_showChangePasswordBottomSheet(context);
								break;
							case 3:
								const url = 'https://help.childcarewow.com/portal/en/home';
								final uri = Uri.parse(url);
								if (await canLaunchUrl(uri)) {
									await launchUrl(uri, mode: LaunchMode.externalApplication);
								}
								break;
							case 4:
								ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout tapped')));
								break;
						}
					},
				),
			],
			bottom: hasTabs
					? PreferredSize(
							preferredSize: Size.fromHeight(kTextTabBarHeight + 2),
							child: Column(
								children: [
									Container(
										height: 1.5,
										decoration: BoxDecoration(
											gradient: AppColors.buildSecondaryGradient(),
										),
									),
									TabBar(
										controller: tabController,
										tabAlignment: tabBarStyle?.tabAlignment ?? TabAlignment.center,
										indicator: tabBarStyle?.indicator,
										indicatorPadding: tabBarStyle?.indicatorPadding ?? EdgeInsets.zero,
										isScrollable: tabBarStyle?.isScrollable ?? false,
										labelColor: tabBarStyle?.labelColor ?? Colors.black87,
										unselectedLabelColor: tabBarStyle?.unselectedLabelColor ?? Colors.black54,
										indicatorWeight: tabBarStyle?.indicatorWeight ?? 2,
										indicatorSize: tabBarStyle?.indicatorSize,
										splashFactory: NoSplash.splashFactory,
										labelStyle: tabBarStyle?.labelStyle,
										unselectedLabelStyle: tabBarStyle?.unselectedLabelStyle,
										tabs: tabs!,
									),
								],
							),
			        )
	            : PreferredSize(
						preferredSize: const Size.fromHeight(1.5),
						child: Container(
							height: 1.5,
							decoration: BoxDecoration(
								gradient: AppColors.buildSecondaryGradient(),
							),
						),
				),
		);
	}
}

void _showChangePasswordBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to change your password? We will send a reset link to your email.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link requested')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Yes, Change Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
