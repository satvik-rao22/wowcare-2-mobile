import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_avatar.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_row_details.dart';

/// One person's day (4a): a card that opens where it stands.
///
/// A tap opens the record rather than jumping to the action sheet, because
/// the question most of the time is "when did they get in and who signed
/// them", not "what can I do to them". The sheet is one key away, at the foot
/// of the open record.
class AttendanceRow extends StatelessWidget {
  const AttendanceRow({
    required this.record,
    required this.isExpanded,
    required this.onTap,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onMoreActions,
    super.key,
  });

  final AttendanceRecord record;
  final bool isExpanded;
  final VoidCallback onTap;

  final bool isSelectMode;
  final bool isSelected;

  /// Null while the day is read only or the classroom is locked.
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: EdgeInsets.zero,
      clipContent: true,
      lineColor: isSelected ? c.pink : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            selected: isSelectMode ? isSelected : null,
            label: record.fullName,
            child: Pressable.surface(
              onTap: onTap,
              child: Padding(
                padding: AttendanceSizes.rowPad,
                child: Row(
                  spacing: AppSizes.rowGap,
                  children: <Widget>[
                    if (isSelectMode) AppCheckbox(checked: isSelected),
                    AttendanceAvatar(
                      initials: record.initials,
                      status: record.status,
                      audience: record.audience,
                    ),
                    Expanded(child: _names(c)),
                    _pill(c),
                    AnimatedRotation(
                      duration: AppMotion.fast,
                      curve: AppMotion.ease,
                      turns: isExpanded ? .5 : 0,
                      child: Icon(
                        AppIcons.chevronDown,
                        size: AppSizes.rowChevron,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded && !isSelectMode)
            Padding(
              padding: AttendanceSizes.detailPad,
              child: AttendanceRowDetails(
                record: record,
                onMoreActions: onMoreActions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _names(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSizes.rowTextGap,
    children: <Widget>[
      Text(
        record.fullName,
        style: AppTextStyles.rowName.copyWith(color: c.ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        _subline,
        style: AppTextStyles.rowSub.copyWith(color: c.ink3),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  /// The second line carries the method every sign in was taken on, which is
  /// returned on every row and has never been shown.
  String get _subline {
    final scope = record.scopeLabel;
    final inAt = record.signedInTime;
    final outAt = record.signedOutTime;

    if (record.isSignedIn && inAt != null) {
      return AttendanceStrings.rowSignedIn(
        scope,
        inAt.label,
        record.signedInMethod?.label ?? '',
      );
    }
    if (record.isSignedOut && outAt != null) {
      return AttendanceStrings.rowSignedOut(
        scope,
        inAt?.label ?? AttendanceStrings.detailNotRecorded,
        outAt.label,
      );
    }
    if (record.isAbsent) {
      return record.absenceReason ?? AppStrings.absent;
    }
    return record.isExpectedToday
        ? AttendanceStrings.rowExpected(scope)
        : AttendanceStrings.rowNotExpected(scope);
  }

  Widget _pill(Colourway c) {
    final inAt = record.signedInTime;
    final outAt = record.signedOutTime;

    if (record.isSignedIn && inAt != null) {
      return StatusPill(
        label: AttendanceStrings.pillSignedIn(inAt.label),
        tone: PillTone.success,
        small: true,
      );
    }
    if (record.isSignedOut && outAt != null) {
      return StatusPill(
        label: AttendanceStrings.pillSignedOut(outAt.label),
        foreground: c.ink,
        background: c.neutralBg,
        small: true,
      );
    }
    if (record.isAbsent) {
      return const StatusPill(
        label: AppStrings.absent,
        tone: PillTone.danger,
        small: true,
      );
    }

    final due = record.expectedTime;
    return StatusPill(
      label: due == null
          ? AppStrings.notMarked
          : AttendanceStrings.pillDue(due.label),
      foreground: c.ink3,
      background: c.card,
      line: c.keyBorder,
      small: true,
    );
  }
}
