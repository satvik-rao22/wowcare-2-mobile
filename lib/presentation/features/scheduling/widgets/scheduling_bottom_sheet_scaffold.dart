import 'package:flutter/material.dart';

import 'package:wowcare/core/responsive/app_breakpoints.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Shared bottom-sheet frame for scheduling's confirmation/info sheets.
///
/// Consolidates the width/safe-area sizing that [NoScheduleBottomSheet],
/// [StaffAbsentBottomSheet], [StaffNoAvailabilityBottomSheet] and
/// [ShiftOverrideBottomSheet] used to each hand-roll identically. Callers
/// supply just their own content as [children]; the scaffold handles the
/// `SafeArea` + max-width + padding + rounded-top-corner card underneath.
class SchedulingBottomSheetScaffold extends StatelessWidget {
  const SchedulingBottomSheetScaffold({super.key, required this.children});

  final List<Widget> children;

  /// Font size for the sheet's title text — exposed so callers can style
  /// their title `Text` consistently with the rest of the scaffold.
  static double titleFontSize(BuildContext context) =>
      context.responsive(compact: 15.0, medium: 16.0, expanded: 18.0);

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = context.screenSize == ScreenSizeClass.expanded;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    final horizontalPadding =
        context.responsive(compact: 16.0, medium: 24.0, expanded: 32.0);
    final verticalPadding =
        context.responsive(compact: 20.0, medium: 24.0, expanded: 32.0);
    final borderRadius =
        context.responsive(compact: 16.0, medium: 20.0, expanded: 24.0);

    return SafeArea(
      top: false,
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
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
