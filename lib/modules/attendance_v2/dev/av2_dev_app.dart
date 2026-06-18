import 'package:flutter/material.dart';

import '../core/theme/av2_colors.dart';
import '../data/fixtures/staff_overtime_fixtures.dart';
import '../presentation/controllers/av2_period.dart';
import '../presentation/screens/staff_detail_view.dart';
import '../presentation/widgets/av2_detail_scaffold.dart';

/// Standalone preview of the static screen (fixture data, no DI / backend):
///
///   flutter run -t lib/modules/attendance_v2/dev/av2_dev_app.dart
///
/// Resize the window to see mobile → tablet → desktop.
void main() => runApp(const Av2DevApp());

class Av2DevApp extends StatelessWidget {
  const Av2DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance V2 — preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(seedColor: Av2Colors.primary),
      ),
      home: const _DevHost(),
    );
  }
}

class _DevHost extends StatefulWidget {
  const _DevHost();
  @override
  State<_DevHost> createState() => _DevHostState();
}

class _DevHostState extends State<_DevHost> {
  final _profile = StaffOvertimeFixtures.sample;
  late Av2Period _period =
      Av2Period(start: _profile.rangeStart, end: _profile.rangeEnd, isWholeMonth: true);

  @override
  Widget build(BuildContext context) {
    return Av2DetailScaffold(
      onExport: () {},
      body: StaffDetailView(
        profile: _profile,
        period: _period,
        onPeriodChanged: (p) => setState(() => _period = p),
      ),
    );
  }
}
