import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/src/core/common/widgets/custom_app_bar.dart';
import 'package:wowcare/src/core/common/widgets/custom_navigation_bar.dart';

import '../widgets/my_day_card.dart';
import '../widgets/enrollment_card.dart';
import '../widgets/ratio_monitoring_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const String routeName = '/admin-dashboard';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isHandlingData = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAdminData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // refresh if needed
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Fetch data needed for admin dashboard (example providers/cubits)
      // final adminData = await context.read<AdminCubit>().getAdminDashboardData();
      // context.read<AdminProvider>().setData(adminData);

      await Future.delayed(const Duration(seconds: 2)); // mock delay

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const CustomScrollView(
        slivers: [
          // ✅ Use it as a sliver
          SliverToBoxAdapter(child: CustomAppBar()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyDayCard(),
                  SizedBox(height: 16),
                  EnrollmentCard(isDashboard: true),
                  SizedBox(height: 16),
                  RatioMonitoringCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      body: Center(
        child: SpinKitFoldingCube(color: Colors.blueAccent, size: 80),
      ),
    );
  }
}
