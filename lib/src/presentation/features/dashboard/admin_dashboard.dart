import 'package:flutter/material.dart';
import 'package:wowcare/src/core/common/widgets/custom_app_bar.dart';
import 'package:wowcare/src/core/common/widgets/custom_navigation_bar.dart';

import 'dasboard-view/widgets/my_day_card.dart';
import 'dasboard-view/widgets/enrollment_card.dart';
import 'dasboard-view/widgets/ratio_monitoring_card.dart';

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
    if (_isLoading) {
      return _loadingScreen(); // show loading screen until data loads
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(child: const CustomAppBar()),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const MyDayCard(),
                const SizedBox(height: 16),
                const EnrollmentCard(isDashboard: true),
                const SizedBox(height: 16),
                const RatioMonitoringCard(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/images/WowCarePNG.png'),
              height: 100,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              color: Colors.blueAccent,
              backgroundColor: Colors.grey[200],
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom delegate for SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 60; // Match the preferred height of CustomAppBar

  @override
  double get minExtent => 60; // Match the preferred height of CustomAppBar

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
