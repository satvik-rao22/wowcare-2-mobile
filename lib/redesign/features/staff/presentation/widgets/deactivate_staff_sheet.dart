import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6f. What deactivating a staff member does, said out loud before it is
/// done: the classroom loses them, the Sign-In PIN stops working, app access
/// ends, and nothing at all is deleted.
///
/// Resolves to true when the key is pressed, and to null on dismiss or on
/// "Keep them active".
class DeactivateStaffSheet extends StatelessWidget {
  const DeactivateStaffSheet({required this.member, super.key});

  final StaffMember member;

  static Future<bool?> show(
    BuildContext context, {
    required StaffMember member,
  }) => showAppSheet<bool>(
    context,
    builder: (_) => DeactivateStaffSheet(member: member),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final scope = StaffStrings.scopeOf(member);

    return AppBottomSheet(
      header: _Header(member: member),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StaffSizes.sheetSectionGap,
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: StaffSizes.changeRowGap,
              children: <Widget>[
                const SectionEyebrow(label: StaffStrings.whatChangesToday),
                _Change(label: scope, value: StaffStrings.losesStaff),
                _Change(
                  label: StaffStrings.pinNumbered(member.signInPin),
                  value: StaffStrings.stopsWorking,
                ),
                const _Change(
                  label: StaffStrings.appAccess,
                  value: StaffStrings.ends,
                ),
                _Change(
                  label: StaffStrings.keptOnFile,
                  value: StaffStrings.keptItems,
                  valueColor: c.successFg,
                ),
              ],
            ),
          ),
          SurfaceBox(
            surface: AppSurfaces.tile(c, fill: c.staffBg, line: c.staffLine),
            padding: AppSizes.alertPad,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.alertGap,
              children: <Widget>[
                Icon(
                  AppIcons.alertTriangle,
                  size: AppSizes.alertIcon,
                  color: c.staffFg,
                ),
                Expanded(
                  child: Text(
                    StaffStrings.deactivateWarning(scope),
                    style: StaffTextStyles.warning.copyWith(color: c.staffFg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StaffSizes.sheetSectionGap,
          children: <Widget>[
            DestructiveKey(
              label: StaffStrings.deactivateKey(member.firstName),
              padding: StaffSizes.sheetKeyPad,
              onTap: () => Navigator.of(context).pop(true),
            ),
            Center(
              child: TextLink(
                label: StaffStrings.keepActive,
                color: c.ink2,
                style: StaffTextStyles.dockedKey,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: StaffSizes.sheetSectionGap,
      children: <Widget>[
        AppAvatar(
          initials: member.initials,
          size: StaffSizes.sheetAvatar,
          tone: AvatarTone.staff,
          textStyle: StaffTextStyles.sheetInitials,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                StaffStrings.deactivateQuestion(member.name),
                style: AppTextStyles.detailTitle.copyWith(color: c.ink),
              ),
              Text(
                StaffStrings.sinceLine(
                  member.designation,
                  StaffStrings.scopeOf(member),
                  member.since == null
                      ? StaffStrings.dash
                      : StaffStrings.date(member.since!),
                ),
                style: StaffTextStyles.sheetSub.copyWith(color: c.ink2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line of "What changes today": what it is on the left, what becomes of
/// it on the right.
class _Change extends StatelessWidget {
  const _Change({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: StaffSizes.changeRowGap,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: StaffTextStyles.changeLabel.copyWith(color: c.ink2),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: StaffTextStyles.changeValue.copyWith(
              color: valueColor ?? c.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
