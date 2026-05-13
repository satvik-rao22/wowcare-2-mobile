import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../widgets/billing-card.dart';
import '../widgets/childs-progress-card.dart';
import '../widgets/events_card.dart';
import '../widgets/movements-card.dart';
import '../widgets/my-day-card.dart';
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Welcome {User Name}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 8),
                const Text(
                  'Need your attention',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.start,
                ),
              ],
            ),

            MyDayCard(),
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
