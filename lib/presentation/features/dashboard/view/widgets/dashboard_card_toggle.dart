import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The small rimmed key that folds a dashboard card open and shut.
///
/// In the skeuomorphic language this is a real key: a neutral face on a 2px
/// rim, with a chevron that rotates as the card opens. Reused by every
/// dashboard card so the collapse affordance stays one recognisable object.
class DashboardCardToggle extends StatelessWidget {
  const DashboardCardToggle({
    super.key,
    required this.minimized,
    required this.onTap,
  });

  /// Whether the owning card is currently collapsed.
  final bool minimized;

  /// Called when the user taps the toggle.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      SkeuFoldKey(expanded: !minimized, onTap: onTap);
}
