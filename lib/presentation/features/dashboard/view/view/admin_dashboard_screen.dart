import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../widgets/billing-card.dart';
import '../widgets/childs-progress-card.dart';
import '../widgets/class-room-shift.dart';
import '../widgets/dashboard-Grid-Sections.dart';
import '../widgets/events_card.dart';
import '../widgets/movements-card.dart';
import '../widgets/my-day-card.dart';
import '../widgets/ratio-monitor.dart';
import '../widgets/to-do-cards.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            DashboardGridSection(),
            SizedBox(height: 16),

            MyDayCard(),
            SizedBox(height: 8),
            RatioMonitoringCard(),
            SizedBox(height: 8),
            ClassroomShiftsCard(),
            SizedBox(height: 8),
            MovementsCard(),
            SizedBox(height: 8),
            BillingCard(),
            SizedBox(height: 8),
            EventsCard(),
            SizedBox(height: 8),
            TodoCard(),
            SizedBox(height: 8),
            ChildsProgressCard(),
          ],
        ),
        // showCustomNavigationBar: true,
      ),
    );
  }
}
