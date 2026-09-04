import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_avatar.dart';

/// What the record sheet can be asked for.
enum AttendanceAction {
  /// Sign In, or Override Sign In on somebody marked absent, or a second
  /// sign in on somebody who already went home.
  signIn,
  signOut,
  transfer,
  markAbsent,
  undoAbsence,
  editTimes,
  openProfile,
}

/// Everything that can be done to one record (4a), reached from the
/// **More actions** key at the foot of the open row.
///
/// The one pink key is whichever way the day goes next. The grid under it
/// holds the rest, dimmed and dead where the record says they are off: Mark
/// Absent is off once someone is here, and there is nothing to edit until a
/// time is recorded.
class RecordActionsSheet extends StatelessWidget {
  const RecordActionsSheet({
    required this.record,
    required this.now,
    this.canEditTimes = true,
    super.key,
  });

  final AttendanceRecord record;

  /// The school's clock, for "here so long already".
  final ClockTime now;

  /// An Admin may edit a recorded time even on a day that is otherwise read
  /// only.
  final bool canEditTimes;

  static Future<AttendanceAction?> show(
    BuildContext context, {
    required AttendanceRecord record,
    required ClockTime now,
    bool canEditTimes = true,
  }) => showAppSheet<AttendanceAction>(
    context,
    builder: (_) => RecordActionsSheet(
      record: record,
      now: now,
      canEditTimes: canEditTimes,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppBottomSheet(
      header: _header(c),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.sheetGap,
        children: <Widget>[
          _note(c),
          PrimaryKey(
            label: _primaryLabel,
            onTap: () => Navigator.of(context).pop(_primaryAction),
          ),
          _grid(context),
          Text(
            _footer,
            textAlign: TextAlign.center,
            style: AttendanceTextStyles.footnote.copyWith(color: c.ink3),
          ),
        ],
      ),
    );
  }

  Widget _header(Colourway c) => Row(
    spacing: AttendanceSizes.sheetHeaderGap,
    children: <Widget>[
      AttendanceAvatar(
        initials: record.initials,
        status: record.status,
        audience: record.audience,
        size: AttendanceSizes.headerAvatar,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSizes.rowTextGap,
          children: <Widget>[
            Text(
              record.fullName,
              style: AppTextStyles.detailTitle.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              AttendanceStrings.sheetScope(
                record.scopeLabel,
                isExpected: record.isExpectedToday,
              ),
              style: AttendanceTextStyles.heroSub.copyWith(color: c.ink2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );

  /// The tinted block that says where the day got to.
  Widget _note(Colourway c) {
    final (fill, ink) = switch (record.status) {
      _ when record.isSignedIn => (c.successBg, c.successFg),
      _ when record.isAbsent => (c.dangerBg, c.dangerFg),
      _ when record.isSignedOut => (c.neutralBg, c.ink),
      _ => (c.well, c.ink2),
    };

    return SurfaceBox(
      surface: AppSurfaces.glyphTile(c, fill: fill, radius: AppRadii.inner),
      padding: AttendanceSizes.sheetNotePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AttendanceSizes.sheetNoteGap,
        children: <Widget>[
          Text(
            _noteTitle,
            style: AttendanceTextStyles.sheetNoteEyebrow.copyWith(color: ink),
          ),
          Text(
            _noteBody,
            style: AttendanceTextStyles.sheetNoteBody.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }

  String get _noteTitle {
    final inAt = record.signedInTime;
    final outAt = record.signedOutTime;
    if (record.isSignedIn && inAt != null) {
      return AttendanceStrings.noteSignedIn(inAt.label);
    }
    if (record.isSignedOut && outAt != null) {
      return AttendanceStrings.noteSignedOut(outAt.label);
    }
    if (record.isAbsent) return AttendanceStrings.noteAbsent;
    return AttendanceStrings.noteNotMarked;
  }

  String get _noteBody {
    final inAt = record.signedInTime;
    final outAt = record.signedOutTime;

    if (record.isSignedIn && inAt != null) {
      return AttendanceStrings.noteSignedInBody(
        record.signedInBy ?? AttendanceStrings.detailNotRecorded,
        record.signedInMethod?.onThe ?? AttendanceStrings.detailNotRecorded,
        AttendanceFormats.between(inAt, now),
      );
    }
    if (record.isSignedOut && outAt != null) {
      return AttendanceStrings.noteSignedOutBody(
        record.signedOutBy ?? AttendanceStrings.detailNotRecorded,
        record.signedOutMethod?.onThe ?? AttendanceStrings.detailNotRecorded,
        inAt == null
            ? AttendanceStrings.detailNotRecorded
            : AttendanceFormats.between(inAt, outAt),
      );
    }
    if (record.isAbsent) {
      return AttendanceStrings.noteAbsentBody(
        record.absenceReason ?? AppStrings.absent,
      );
    }
    return record.isExpectedToday
        ? AttendanceStrings.noteNotMarkedBody
        : AttendanceStrings.noteNotExpectedBody;
  }

  String get _primaryLabel {
    if (record.isSignedIn) return AppStrings.signOut;
    if (record.isAbsent) return AttendanceStrings.overrideSignIn;
    if (record.isSignedOut) return AttendanceStrings.signBackIn;
    return AppStrings.signIn;
  }

  AttendanceAction get _primaryAction =>
      record.isSignedIn ? AttendanceAction.signOut : AttendanceAction.signIn;

  String get _footer {
    if (record.isSignedIn) return AttendanceStrings.footerSignedIn;
    if (record.isAbsent) return AttendanceStrings.footerAbsent;
    if (record.isSignedOut) return AttendanceStrings.footerSignedOut;
    return AttendanceStrings.footerNotMarked;
  }

  /// The four everyday actions, two by two. A key that is off keeps its
  /// place, dimmed, and does not move.
  Widget _grid(BuildContext context) {
    void pop(AttendanceAction action) =>
        Navigator.of(context).pop<AttendanceAction>(action);

    final absentIsUndo = record.isAbsent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AttendanceSizes.sheetGridGap,
      children: <Widget>[
        Row(
          spacing: AttendanceSizes.sheetGridGap,
          children: <Widget>[
            Expanded(
              child: _GridKey(
                label: AttendanceStrings.transfer,
                isOn: record.canTransfer,
                onTap: () => pop(AttendanceAction.transfer),
              ),
            ),
            Expanded(
              child: _GridKey(
                label: absentIsUndo
                    ? AttendanceStrings.undoAbsence
                    : AttendanceStrings.markAbsent,
                isOn: absentIsUndo || record.canMarkAbsent,
                onTap: () => pop(
                  absentIsUndo
                      ? AttendanceAction.undoAbsence
                      : AttendanceAction.markAbsent,
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: AttendanceSizes.sheetGridGap,
          children: <Widget>[
            Expanded(
              child: _GridKey(
                label: AttendanceStrings.editTimes,
                isOn: canEditTimes && record.canEditTimes,
                onTap: () => pop(AttendanceAction.editTimes),
              ),
            ),
            Expanded(
              child: _GridKey(
                label: AttendanceStrings.openProfile,
                isOn: true,
                onTap: () => pop(AttendanceAction.openProfile),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One key in the sheet's grid.
class _GridKey extends StatelessWidget {
  const _GridKey({
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  final String label;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final key = SecondaryKey(
      label: label,
      padding: AttendanceSizes.sheetGridKeyPad,
      onTap: isOn ? onTap : null,
    );
    if (isOn) return key;
    return Opacity(opacity: AttendanceSizes.keyOffOpacity, child: key);
  }
}
