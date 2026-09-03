import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';

/// The dashboard's own header: the hamburger that opens More, a greeting over
/// the school and the date, then Scan QR and the bell.
///
/// The hamburger is the house menu key everywhere in this app; More is not a
/// tab, because five slots are all a bar can carry.
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  const DashboardHeader({
    required this.firstName,
    required this.place,
    required this.dateLabel,
    required this.notificationCount,
    required this.onOpenMore,
    required this.onScanQr,
    required this.onOpenNotifications,
    this.isGuardian = false,
    super.key,
  });

  final String firstName;

  /// The school for an Admin, their classroom for a Staff member.
  final String place;
  final String dateLabel;
  final int notificationCount;

  final VoidCallback onOpenMore;
  final VoidCallback onScanQr;
  final VoidCallback onOpenNotifications;

  /// A guardian is greeted rather than wished a good morning: they are not
  /// starting a shift.
  final bool isGuardian;

  /// The bar's own height: an action key, plus the pad above and below it.
  @override
  Size get preferredSize =>
      Size.fromHeight(AppSizes.iconKey + AppSizes.headerBarPad.vertical);

  @override
  Widget build(BuildContext context) => AppHeaderBar.dashboard(
    title: isGuardian
        ? DashboardStrings.hello(firstName)
        : DashboardStrings.goodMorning(firstName),
    subline: DashboardStrings.subline(place, dateLabel),
    leading: IconKey(
      icon: AppIcons.menu,
      semanticLabel: AppStrings.more,
      onTap: onOpenMore,
    ),
    actions: <Widget>[
      IconKey(
        icon: AppIcons.scanQr,
        semanticLabel: AppStrings.scanQr,
        iconColor: context.colours.pink,
        onTap: onScanQr,
      ),
      IconKey(
        icon: AppIcons.bell,
        semanticLabel: AppStrings.notifications,
        badgeCount: notificationCount,
        onTap: onOpenNotifications,
      ),
    ],
  );
}
