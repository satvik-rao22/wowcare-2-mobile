import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_out_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_center_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view/user_profile_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/profile_menu_header_cubit.dart';
import 'package:wowcare/presentation/features/user-profile/widgets/profile_menu_header.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../presentation/features/user-profile/view/notification_settings_screen.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/auth/usecases/forgot_password_usecase.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';

import '../../../src/app_router.dart';

class TabBarStyle {
  final TabAlignment? tabAlignment;
  final Decoration? indicator;
  final EdgeInsetsGeometry? indicatorPadding;
  final Color? dividerColor;
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
    this.dividerColor,
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
    this.isKiosk = false,
    super.key,
  });

  final bool hasBackButton;
  final List<Tab>? tabs;
  final TabController? tabController;
  final TabBarStyle? tabBarStyle;
  final int notificationCount;
  final bool isParent;
  final List<String>? studentList;
  final bool isKiosk;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (tabs != null ? kTextTabBarHeight : 0.0),
  );

  @override
  Widget build(BuildContext context) {
    final bool hasTabs =
        tabs != null && tabController != null && tabs!.isNotEmpty;
    // Capture the current route name once per build so the notification bell
    // can skip pushing a duplicate when already on that screen.
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black,
      titleSpacing: 0,
      title: isParent
          ? BlocBuilder<ParentChildCubit, ParentChildState>(
              builder: (context, state) {
                final cubit = context.read<ParentChildCubit>();
                final names = cubit.childNames;
                final canPickChild = !state.isLoading && names.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    width: 220,
                    child: CustomDropdown(
                      hintText: state.isLoading
                          ? 'Loading children...'
                          : 'No children linked',
                      items: names,
                      selectedItem: state.selectedChild?.name,
                      onSelect: cubit.selectByName,
                      prependHintAsSelectableItem: false,
                      isEnabled: canPickChild,
                    ),
                  ),
                );
              },
            )
          : null,
      leading: hasBackButton
          ? IconButton(
              icon: SvgPicture.asset(MediaRes.backButton),
              onPressed: () {
                // Use GoRouter's navigation for proper back handling in shell routes.
                // In StatefulShellRoute, context.canPop() may not work as expected because
                // the route hierarchy differs from traditional Navigator stacks.
                // Always try to pop from the shell context first, preserving route history.
                debugPrint(
                  '[CustomAppBar] Back button pressed. '
                  'canPop=${context.canPop()}, currentRoute=${ModalRoute.of(context)?.settings.name}',
                );

                if (context.canPop()) {
                  context.pop();
                } else {
                  // Fallback: navigate to dashboard if nothing to pop
                  context.go(DashboardScreen.routeName);
                }
              },
            )
          : Builder(
              builder: (context) => IconButton(
                icon: SvgPicture.asset(MediaRes.hamburgerIcon),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      actions: [
        if (!isKiosk)
          BlocBuilder<UnreadBadgeCubit, UnreadBadgeState>(
            builder: (context, badgeState) {
              final role = context.read<RoleCubit>();
              final int unreadCount = role.isParent
                  ? badgeState.parentTotal
                  : role.isAdmin
                  ? badgeState.adminTotal
                  : badgeState.staffTotal;
              return Stack(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      MediaRes.chatsIcon,
                      width: 22,
                      height: 22,
                    ),
                    onPressed: () => context.push(AppRoutes.messagingEntry),
                  ),
                  if (unreadCount > 0)
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
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (!isKiosk)
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  MediaRes.notificationsIcon,
                  width: 22,
                  height: 22,
                ),
                onPressed: () {
                  // Don't stack a second notification page when the bell is
                  // tapped again while already on it.
                  if (currentRoute == NotificationCenterScreen.routeName)
                    return;
                  context.push(NotificationCenterScreen.routeName);
                },
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
        if (!isKiosk) const _AppBarKebabMenu(),
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
                    dividerColor: tabBarStyle?.dividerColor,
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

// ---------------------------------------------------------------------------
// Kebab (three-dot) popup menu — extracted as a StatefulWidget so it can
// load role availability asynchronously and hide "Switch Profile" when the
// logged-in user only has a single role at the current school.
// ---------------------------------------------------------------------------

class _AppBarKebabMenu extends StatefulWidget {
  const _AppBarKebabMenu();

  @override
  State<_AppBarKebabMenu> createState() => _AppBarKebabMenuState();
}

class _AppBarKebabMenuState extends State<_AppBarKebabMenu> {
  bool _hasSwitchableProfiles = false;
  late final ProfileMenuHeaderCubit _profileHeaderCubit;

  @override
  void initState() {
    super.initState();
    _profileHeaderCubit = ProfileMenuHeaderCubit(
      serviceLocator<StorageService>(),
    );
    _profileHeaderCubit.loadSummary();
    _loadSwitchProfileAvailability();
  }

  @override
  void dispose() {
    _profileHeaderCubit.close();
    super.dispose();
  }

  Future<void> _loadSwitchProfileAvailability() async {
    try {
      final storage = serviceLocator<StorageService>();
      final org = (await storage.getString(StorageKeys.organizationCode) ?? '')
          .trim();
      final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (org.isEmpty || school.isEmpty) return;
      final users = await readCachedUserAccessDetailsUsers(storage);
      final distinct = distinctActiveRolesForCurrentSchoolFromUserDetails(
        users,
        org,
        school,
      );
      if (mounted) {
        setState(() => _hasSwitchableProfiles = distinct.length > 1);
      }
    } catch (_) {
      // Default remains false — safe to not show the item.
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final bool isParentPersona = context.read<RoleCubit>().isParent;

    bool hasMultipleOrganizations = false;
    try {
      final authCubit = context.read<AuthCubit>();
      final state = authCubit.state;
      if (state is AuthLoaded) {
        final orgCodes = state.loginResponse.roles
            .map((r) => r.organizationCode)
            .where((c) => c.isNotEmpty)
            .toSet();
        hasMultipleOrganizations = orgCodes.length > 1;
      }
    } catch (_) {}

    return PopupMenuButton<int>(
      constraints: const BoxConstraints(maxWidth: 240),
      icon: SvgPicture.asset(MediaRes.kebabMenu, width: 22, height: 22),
      offset: const Offset(0, 48),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: BlocProvider.value(
                  value: _profileHeaderCubit,
                  child: ProfileMenuHeader(isParentPersona: isParentPersona),
                ),
              ),
            ),
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
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
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              Transform.rotate(
                angle: -pi / 4,
                child: Icon(
                  Icons.vpn_key,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<String?>(
                future: serviceLocator<StorageService>().getString(
                  StorageKeys.staffPin,
                ),
                builder: (context, snapshot) {
                  final pin = (snapshot.data ?? '').trim();
                  final text = pin.isNotEmpty
                      ? 'Sign-in pin : $pin'
                      : 'Sign-in pin';
                  return Text(
                    text,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
        if (_hasSwitchableProfiles)
          PopupMenuItem<int>(
            value: 3,
            child: Row(
              children: [
                Icon(
                  Icons.autorenew_outlined,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
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
              ],
            ),
          ),
        if (hasMultipleOrganizations)
          PopupMenuItem<int>(
            value: 4,
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
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
              ],
            ),
          ),
        PopupMenuItem<int>(
          value: 5,
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              const Text(
                'Change Password',
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
              Icon(
                Icons.settings,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Notification settings',
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
          value: 7,
          child: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Help',
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
          value: 8,
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
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
      ],
      onSelected: (value) async {
        switch (value) {
          case 4:
            if (currentRoute == '/org-selection') break;
            final authCubit = context.read<AuthCubit>();
            if (authCubit.state is! AuthLoaded) {
              await authCubit.loadCachedData();
              if (!context.mounted) return;
            }
            context.go(
              '/org-selection',
              extra: <String, dynamic>{'isSwitchFlow': true},
            );
            break;
          case 1:
            if (currentRoute == UserProfileScreen.routeName) break;
            final storage = serviceLocator<StorageService>();
            final name =
                (await storage.getString(StorageKeys.displayName) ?? '').trim();
            final email = (await storage.getString(StorageKeys.email) ?? '')
                .trim();
            final activeRole =
                (await storage.getString(StorageKeys.activeSchoolRole) ?? '')
                    .trim();
            if (!context.mounted) return;
            context.go(
              UserProfileScreen.routeName,
              extra: <String, dynamic>{
                'userName': name,
                'userEmail': email,
                'userPersona': activeRole,
              },
            );
            break;
          case 3:
            await _switchToNextProfileFromAppBar(context);
            if (mounted) {
              await _loadSwitchProfileAvailability();
              _profileHeaderCubit.loadSummary();
            }
            break;
          case 5:
            _showChangePasswordBottomSheet(context);
            break;
          case 6:
            if (currentRoute == NotificationSettingsScreen.routeName) break;
            context.go(NotificationSettingsScreen.routeName);
            break;
          case 7:
            const url = 'https://help.childcarewow.com/';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            break;
          case 8:
            SignOutScreen.show(context);
            break;
        }
      },
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
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2,
                            ),
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

Future<void> _switchToNextProfileFromAppBar(BuildContext context) async {
  final storage = serviceLocator<StorageService>();
  final name = (await storage.getString(StorageKeys.displayName) ?? '').trim();
  final email = (await storage.getString(StorageKeys.email) ?? '').trim();
  final activeRole =
      (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();

  if (!context.mounted) return;

  final cubit = serviceLocator<UserProfileCubit>();
  try {
    cubit.seed(name: name, email: email, persona: activeRole);
    await cubit.load(isParent: context.read<RoleCubit>().isParent);
    if (!context.mounted) return;

    final roles = cubit.state.distinctRolesForCurrentSchool
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (roles.length <= 1) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'No other profiles available to switch to.',
        isError: true,
      );
      return;
    }

    // Find current role and determine the next one (cycle through the list).
    final cached = (cubit.state.cachedActiveSchoolRole ?? '').trim();
    var currentIndex = -1;
    if (cached.isNotEmpty) {
      for (var i = 0; i < roles.length; i++) {
        if (roles[i].toUpperCase() == cached.toUpperCase()) {
          currentIndex = i;
          break;
        }
      }
    }
    final nextIndex = currentIndex < 0
        ? 0
        : ((currentIndex + 1) % roles.length);
    final nextRole = roles[nextIndex];

    await cubit.persistPersonaSwitch(nextRole);
    if (!context.mounted) return;

    context.read<ParentChildCubit>().invalidate();

    // Mirrors UserProfileScreen._applyPersonaSwitch so both Switch Profile entry
    // points behave identically. Do NOT change the visible persona until the
    // required APIs are done; only flip the UI at the end via
    // applySwitchedPersona.
    //
    // Preload guardian data BEFORE RoleCubit flips to parent so the global
    // dropdown doesn't show a loading state.
    final targetIsGuardian = roleStringIsGuardianPersona(nextRole);
    if (targetIsGuardian) {
      await cubit.loadGuardianProfileForParent();
      if (!context.mounted) return;
      await context.read<ParentChildCubit>().ensureLoaded(force: true);
    }
    if (!context.mounted) return;

    await context.read<RoleCubit>().refreshAccessFromServer(force: true);

    final orgCode = (cubit.state.organizationCode ?? '').trim();
    final schoolCode = (cubit.state.schoolCode ?? '').trim();
    if (orgCode.isNotEmpty && schoolCode.isNotEmpty) {
      try {
        await context.read<AuthCubit>().prefetchStaffProfileForOrgAndSchool(
          organizationCode: orgCode,
          schoolCode: schoolCode,
        );
      } catch (_) {}
    }
    if (!context.mounted) return;

    // Now that prefetch is complete, apply the persona to the UI.
    cubit.applySwitchedPersona(nextRole);
    if (!context.mounted) return;

    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Switched to ${StringUtils.staffTypeToDisplayRole(nextRole)}',
      isSuccess: true,
    );

    await cubit.refreshSwitchProfileAvailability();
    if (!context.mounted) return;
    await cubit.load(isParent: context.read<RoleCubit>().isParent);
    if (!context.mounted) return;

    // Land on the new persona's dashboard. DashboardScreen branches on RoleCubit,
    // so this shows the correct (admin/staff/parent) dashboard and rebuilds it
    // fresh — otherwise a stale Billing/Messaging/etc. screen lingers after the
    // switch and shows the previous persona's data.
    context.go(DashboardScreen.routeName);
  } catch (e) {
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Could not switch profile: $e',
      isError: true,
    );
  } finally {
    cubit.close();
  }
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
      CoreUtils.showTopSnackBar(context: context, message: msg, isError: true);
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
