import 'package:flutter/material.dart';
// Using a simple Scaffold for now to avoid unresolved widget dependencies

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text(
          'Dashboard module goes here',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


