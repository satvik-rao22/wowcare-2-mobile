import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';

/// Shared chrome for regularization screens: brand gradient + transparent
/// AppBar. Matches the attendance_v2 look.
class RegScaffold extends StatelessWidget {
  const RegScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Av2Colors.scaffoldFill),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const BackButton(color: Av2Colors.primary),
          title: Text(title, style: Av2Text.title),
          centerTitle: false,
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}
