import 'package:flutter/material.dart';
import 'package:wowcare/presentation/common/widgets/custom_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: Center(
        child: const Text(
          'Dashboard module goes here',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}


