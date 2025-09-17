import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomRefreshIndicator extends StatelessWidget {
  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double? displacement;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: AppColors.themeColor,
      color: Colors.white,
      displacement: displacement ?? 24,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

