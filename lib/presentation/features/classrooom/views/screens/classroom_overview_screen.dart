import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class ClassroomOverviewScreen extends StatelessWidget {
  const ClassroomOverviewScreen({Key? key}) : super(key: key);
  static const routeName = '/classroom-overview-screen';

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Classroom Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _OverviewStatCard(title: 'Enrolled', value: '48'),
                  _OverviewStatCard(title: 'Expected', value: '36'),
                  _OverviewStatCard(title: 'Staff', value: '12'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _RatioMonitoringPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.5, color: Color.fromARGB(255, 232, 234, 234)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioMonitoringPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1.5, color: Color.fromARGB(255, 232, 234, 234)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ratio Monitoring', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Bar(color: Colors.lightBlue[200]!)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: Colors.amber)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: Colors.green[200]!)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Available'),
                Text('Scheduled'),
                Text('Unscheduled'),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)));
  }
}
