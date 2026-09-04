import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// What select mode docks under the roster (6a): clear the picks, or message
/// them.
///
/// The bulk key is dead until something is picked, and says so rather than
/// disappearing, so the bar never changes height under a thumb.
class StaffSelectBar extends StatelessWidget {
  const StaffSelectBar({
    required this.selectedCount,
    required this.onClear,
    required this.onMessage,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the row to the height its keys actually need.
    return IntrinsicHeight(
      child: Container(
        padding: StaffSizes.dockedBarPad.copyWith(
          bottom: StaffSizes.dockedBarPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: Row(
          spacing: StaffSizes.wizardFooterGap,
          children: <Widget>[
            _QuietKey(label: AppStrings.clear, onTap: onClear),
            Expanded(
              child: _BulkKey(
                count: selectedCount,
                onTap: selectedCount == 0 ? null : onMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietKey extends StatelessWidget {
  const _QuietKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.subtle(c),
          padding: StaffSizes.dockedKeyPad,
          child: Text(
            label,
            style: StaffTextStyles.quietKey.copyWith(color: c.ink2),
          ),
        ),
      ),
    );
  }
}

/// The one action on the bar. Pink once somebody is picked; recessed and
/// unpressable until then.
class _BulkKey extends StatelessWidget {
  const _BulkKey({required this.count, required this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final label = count == 0
        ? StaffStrings.pickStaffToMessage
        : StaffStrings.messageCount(count);

    if (onTap == null) {
      return Semantics(
        button: true,
        enabled: false,
        label: label,
        child: SurfaceBox(
          surface: AppSurfaces.keyDisabled(c),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.bulkKey.copyWith(color: c.ink3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyPrimary(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.bulkKey.copyWith(color: c.onPink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
