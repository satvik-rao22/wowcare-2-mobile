import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/user_profile_screen.dart';
import 'package:wowcare/presentation/features/user-profile/widgets/profile_menu_header.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/auth/usecases/forgot_password_usecase.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/util/storage_keys.dart';

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
    kToolbarHeight + (tabs != null ? kTextTabBarHeight : 0.0),
  );

  @override
  Widget build(BuildContext context) {
    final bool hasTabs =
        tabs != null && tabController != null && tabs!.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black,
      titleSpacing: 0,
      title: isParent && studentList != null
          ? Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SizedBox(
                width: 180,
                child: CustomDropdown(
                  hintText: 'Select child',
                  items: studentList!,
                ),
              ),
            )
          : null,
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
              icon: SvgPicture.asset(
                MediaRes.notificationsIcon,
                width: 22,
                height: 22,
              ),
              onPressed: () {},
            ),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(179, 38, 30, 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notificationCount > 99 ? '99+' : '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<int>(
          constraints: const BoxConstraints(maxWidth: 240),
          icon: SvgPicture.asset(MediaRes.kebabMenu, width: 22, height: 22),
          offset: const Offset(0, 48),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              enabled: false,
              height: 64,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 10,
                      top: 8,
                      bottom: 8,
                    ),
                    child: ProfileMenuHeader(),
                  ),
                ),
              ),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.account_circle_outlined, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Text(
                    'My Profile',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //const Text('My Profile'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 2,
              child: Row(
                children: [
                  Transform.rotate(angle: -pi / 4,
                  child: Icon(Icons.vpn_key, color: AppColors.primaryColor.withValues(alpha: 0.5))),
                  const SizedBox(width: 12),
                  Text(
                    'Sign-in pin : 5769', // hardcoded for now
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //const Text('My Profile'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 3,
              child: Row(
                children: [
                  Icon(Icons.autorenew_outlined, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Text(
                    'Switch Profile',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //const Text('My Profile'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 4,
              child: Row(
                children: [
                  Icon(Icons.business, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Text(
                    'Switch Organisation',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //const Text('My Profile'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 5,
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  const Text('Change Password',
                    style: TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 6,
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  SizedBox(width: 12),
                  Text('Notification settings', style: TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 7,
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  SizedBox(width: 12),
                  Text('Help', style: TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 8,
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.primaryColor.withValues(alpha: 0.5)),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrganizationSelectionScreen(
                      isSwitchFlow: true,
                    ),
                  ),
                );
                break;
              case 1:
                // Navigate to profile if available
                //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Profile')));
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen()),
                );
                break;
              case 5:
                _showChangePasswordBottomSheet(context);
                break;
              case 6:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationSettingsScreen()),
                );
                break;
              case 7:
                //const url = 'https://help.childcarewow.com/portal/en/home';
                const url = 'https://help.childcarewow.com/';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                break;
              case 8:
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logout tapped')));
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
                    tabAlignment:
                        tabBarStyle?.tabAlignment ?? TabAlignment.center,
                    indicator: tabBarStyle?.indicator,
                    indicatorPadding:
                        tabBarStyle?.indicatorPadding ?? EdgeInsets.zero,
                    isScrollable: tabBarStyle?.isScrollable ?? false,
                    labelColor: tabBarStyle?.labelColor ?? Colors.black87,
                    unselectedLabelColor:
                        tabBarStyle?.unselectedLabelColor ?? Colors.black54,
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
  final parentContext = context; // Save the parent context

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext bottomSheetContext) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isTablet = screenWidth > 600;
      final isLargeTablet = screenWidth > 900;
      final bottomSafe = MediaQuery.of(context).padding.bottom;

      // Responsive dimensions
      final horizontalPadding = isLargeTablet
          ? 32.0
          : isTablet
          ? 24.0
          : 16.0;

      final verticalPadding = isLargeTablet
          ? 32.0
          : isTablet
          ? 24.0
          : 16.0;

      final titleFontSize = isLargeTablet
          ? 20.0
          : isTablet
          ? 18.0
          : 16.0;

      final buttonHeight = isLargeTablet
          ? 56.0
          : isTablet
          ? 48.0
          : 40.0;

      final buttonFontSize = isLargeTablet
          ? 18.0
          : isTablet
          ? 16.0
          : 14.0;

      final borderRadius = isLargeTablet
          ? 24.0
          : isTablet
          ? 20.0
          : 16.0;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeTablet ? 1200.0 : double.infinity,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: verticalPadding,
                bottom: verticalPadding + bottomSafe,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: verticalPadding / 2),
                  // Title text centered
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding / 2,
                    ),
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  // Description text
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding / 2,
                    ),
                    child: Text(
                      'Are you sure you want to change your password? A password reset link will be sent to your registered email.',
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalPadding * 1.5),
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C7FD8)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius / 2,
                                ),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: "Manrope",
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: horizontalPadding / 2),
                      Expanded(
                        child: Container(
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius / 2),
                            gradient: AppColors.buildPrimaryGradient(),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              // Close bottom sheet first
                              if (bottomSheetContext.mounted) {
                                Navigator.pop(bottomSheetContext);
                              }
                              // Use the parent context saved before showing bottom sheet
                              if (parentContext.mounted) {
                                await _sendPasswordResetRequest(parentContext);
                              }
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius / 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Yes, Change Password',
                              style: TextStyle(
                                fontFamily: "Manrope",
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _sendPasswordResetRequest(BuildContext context) async {
  // Get logged in user's email from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString(StorageKeys.email) ?? '';

  if (email.isEmpty) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Unable to retrieve your email address',
      isError: true,
    );
    return;
  }

  final useCase = serviceLocator<ForgotPasswordUseCase>();

  final result = await useCase(email);

  if (!context.mounted) return;

  result.fold(
    (failure) {
      final msg = failure.message ?? failure.toString();
      CoreUtils.showTopSnackBar(
        context: context,
        message: msg,
        isError: true,
      );
    },
    (message) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
        duration: const Duration(seconds: 3),
      );
    },
  );
}
