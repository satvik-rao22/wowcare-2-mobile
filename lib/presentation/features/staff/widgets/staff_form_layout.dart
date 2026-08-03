import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffFormLayout extends StatelessWidget {
  const StaffFormLayout({
    super.key,
    required this.title,
    required this.child,
    required this.bottomBar,
    this.isKiosk = false,
    this.showKioskBackButton = false,
    this.showKioskLogoutMenu = true,
  });

  final String title;
  final Widget child;
  final Widget bottomBar;
  final bool isKiosk;

  /// Shows a back arrow in the kiosk header. Only relevant when [isKiosk] is
  /// true; the non-kiosk header already has a back button via [CustomAppBar].
  final bool showKioskBackButton;

  /// Shows a logout menu in the kiosk header. Only relevant when [isKiosk] is true.
  final bool showKioskLogoutMenu;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isKiosk
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 1),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          if (showKioskBackButton)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color(0xff573353),
                              ),
                              onPressed: () => Navigator.maybePop(context),
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: showKioskBackButton ? 0 : 16.0,
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/images/WowCarePNG.png',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'WowCare',
                              style: TextStyle(
                                color: Color(0xff573353),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (showKioskLogoutMenu)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xff573353)),
                              onSelected: (value) {
                                if (value == 'logout') {
                                  AppLogger.d('[Kiosk] Logout selected from menu');
                                  context.go('/kiosk/logout');
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.logout, size: 20, color: Color(0xff573353)),
                                      SizedBox(width: 12),
                                      Text('Logout'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                ],
              ),
            )
          : CustomAppBar(hasBackButton: true, isKiosk: isKiosk),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: responsive.containerWidth,
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
