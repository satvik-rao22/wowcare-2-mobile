import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';

/// The 34px chevron-left key that leads a drill-down's header (5a, 7a).
///
/// Without [onTap] it pops the nearest route, which is what it does on every
/// screen but a wizard step.
class BackKey extends StatelessWidget {
  const BackKey({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconKey(
    icon: AppIcons.chevronLeft,
    size: AppSizes.backKey,
    semanticLabel: AppStrings.back,
    onTap: onTap ?? () => unawaited(Navigator.maybePop(context)),
  );
}
