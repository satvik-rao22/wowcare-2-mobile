import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// The whole record, opened in place under its row (4a).
///
/// Every line here is already on the row that was fetched, so opening one
/// costs no call. Three of them have never been drawn before: the method the
/// sign in or sign out was taken on, whether the person was expected today,
/// and the transfer trail. Duration is arithmetic on the two times.
class AttendanceRowDetails extends StatelessWidget {
  const AttendanceRowDetails({
    required this.record,
    this.onMoreActions,
    super.key,
  });

  final AttendanceRecord record;

  /// The key at the foot. Null hides it, which is what a read-only day and a
  /// locked classroom do.
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AttendanceSizes.detailGap,
      children: <Widget>[
        Container(height: AppSizes.hairline, color: c.divider),
        for (final line in _lines) _line(c, line.$1, line.$2),
        if (onMoreActions != null)
          SecondaryKey(
            label: AttendanceStrings.moreActionsKey,
            onTap: onMoreActions,
          ),
      ],
    );
  }

  /// The record, in the order the frame reads it out.
  List<(String, String)> get _lines {
    final scopeLabel = record.audience.isStudents
        ? AttendanceStrings.detailClassroom
        : AttendanceStrings.detailRole;
    final lines = <(String, String)>[];

    switch (record.status) {
      case _ when record.isSignedIn:
        lines.add((AttendanceStrings.detailSignedIn, _signedIn));
        lines.add((AttendanceStrings.detailBy, record.signedInBy ?? _none));
        lines.add((scopeLabel, record.scopeLabel));
        lines.add((AttendanceStrings.detailExpected, _expected));
      case _ when record.isSignedOut:
        lines.add((
          AttendanceStrings.detailSignedIn,
          record.signedInTime?.label ?? _none,
        ));
        lines.add((AttendanceStrings.detailSignedOut, _signedOut));
        lines.add((AttendanceStrings.detailBy, record.signedOutBy ?? _none));
        lines.add((AttendanceStrings.detailDuration, _duration));
        lines.add((scopeLabel, record.scopeLabel));
      case _ when record.isAbsent:
        lines.add((
          AttendanceStrings.detailSignedIn,
          AttendanceStrings.detailMarkedAbsent,
        ));
        lines.add((
          AttendanceStrings.detailReason,
          record.absenceReason ?? _none,
        ));
        lines.add((scopeLabel, record.scopeLabel));
      case _:
        lines.add((
          AttendanceStrings.detailSignedIn,
          AttendanceStrings.noteNotMarked,
        ));
        lines.add((AttendanceStrings.detailExpected, _expected));
        lines.add((scopeLabel, record.scopeLabel));
    }

    final trail = record.transfer;
    if (trail != null) {
      lines.add((
        AttendanceStrings.detailTransfer,
        '${AttendanceStrings.transferPath(trail.fromClassroom, trail.toClassroom)}'
            ' · '
            '${AttendanceStrings.transferSequence(trail.sequenceNumber, trail.totalSequenceCount)}',
      ));
      lines.add((
        AttendanceStrings.detailTransferredBy,
        AttendanceStrings.transferBy(trail.transferredBy, trail.reason),
      ));
      final next = trail.nextActionTime;
      if (next != null) {
        lines.add((AttendanceStrings.detailNextAction, next.label));
      }
    }

    return lines;
  }

  static const String _none = AttendanceStrings.detailNotRecorded;

  String get _signedIn {
    final at = record.signedInTime;
    if (at == null) return _none;
    final method = record.signedInMethod;
    return method == null
        ? at.label
        : AttendanceStrings.timeAndMethod(at.label, method.label);
  }

  String get _signedOut {
    final at = record.signedOutTime;
    if (at == null) return _none;
    final method = record.signedOutMethod;
    return method == null
        ? at.label
        : AttendanceStrings.timeAndMethod(at.label, method.label);
  }

  /// A staff member has a rostered shift start. A student has only whether
  /// they were expected at all, which is what the API actually holds.
  String get _expected {
    if (!record.audience.isStudents) {
      return record.expectedTime?.label ?? _none;
    }
    return record.isExpectedToday
        ? AttendanceStrings.expectedToday
        : AttendanceStrings.expectedNotToday;
  }

  String get _duration {
    final from = record.signedInTime;
    final to = record.signedOutTime;
    if (from == null || to == null) return _none;
    return AttendanceFormats.between(from, to);
  }

  /// The label is measured first and the value takes what is left, so a long
  /// transfer reason wraps rather than running past the card.
  Widget _line(Colourway c, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSizes.rowGap,
    children: <Widget>[
      SizedBox(
        width: AttendanceSizes.detailLabelWidth,
        child: Text(
          label,
          style: AttendanceTextStyles.detailLabel.copyWith(color: c.ink3),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AttendanceTextStyles.detailValue.copyWith(color: c.ink),
        ),
      ),
    ],
  );
}
