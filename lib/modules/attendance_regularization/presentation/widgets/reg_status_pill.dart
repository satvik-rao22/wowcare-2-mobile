import 'package:flutter/widgets.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_pill.dart';

import '../../domain/entities/regularization_request.dart';

/// Status badge for a regularization request.
class RegStatusPill extends StatelessWidget {
  const RegStatusPill({super.key, required this.status});

  final RegStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(status);
    return Av2Pill(text: status.label, fill: colors.$1, textColor: colors.$2);
  }

  (Color, Color) _colors(RegStatus s) {
    switch (s) {
      case RegStatus.pending:
        return (Av2Colors.overtimeFill, Av2Colors.overtime);
      case RegStatus.approved:
        return (Av2Colors.successFill, Av2Colors.success);
      case RegStatus.cancelled:
        return (Av2Colors.neutralFill, Av2Colors.neutral);
    }
  }
}
