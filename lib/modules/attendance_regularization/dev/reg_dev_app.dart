import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';

import '../data/fixtures/regularization_fixtures.dart';
import '../presentation/screens/reg_admin_inbox_view.dart';
import '../presentation/entry/reg_requests_list.dart';
import '../presentation/widgets/reg_scaffold.dart';
import '../presentation/widgets/reg_bulk_signin_gate_sheet.dart';
import '../presentation/widgets/reg_request_detail_sheet.dart';
import '../presentation/widgets/reg_resolve_sheet.dart';

/// Standalone preview of the regularization screens/widgets (static data):
///
///   flutter run -t lib/modules/attendance_regularization/dev/reg_dev_app.dart
void main() => runApp(const RegDevApp());

class RegDevApp extends StatelessWidget {
  const RegDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Regularization — preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(seedColor: Av2Colors.primary),
      ),
      home: const _DevMenu(),
    );
  }
}

class _DevMenu extends StatelessWidget {
  const _DevMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: Av2Colors.scaffoldGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Regularization preview', style: Av2Text.title),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Av2Spacing.md),
            children: [
              _btn(context, 'Next-day gate (staff)', () async {
                await showRegResolveSheet(
                  context,
                  item: RegularizationFixtures.pendingGate,
                  mandatory: true,
                );
              }),
              const SizedBox(height: Av2Spacing.sm),
              _btn(
                context,
                'Sign-out missing (admin, auto-approved)',
                () async {
                  await showRegResolveSheet(
                    context,
                    item: RegularizationFixtures.pendingGate,
                    mandatory: true,
                    byAdmin: true,
                    staffName: 'Mohan Sonone',
                  );
                },
              ),
              const SizedBox(height: Av2Spacing.sm),
              _btn(
                context,
                'Bulk sign-in gate — 10 of 50 blocked (admin)',
                () async {
                  await showRegBulkSignInGateSheet(
                    context,
                    blocked: RegularizationFixtures.bulkSignInGate,
                    otherCount: 40,
                  );
                },
              ),
              const SizedBox(height: Av2Spacing.sm),
              _btn(context, 'Staff: my regularizations', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegScaffold(
                      title: 'My regularizations',
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(Av2Spacing.md),
                        child: Builder(
                          builder: (inner) => RegRequestsList(
                            requests: RegularizationFixtures.myRequests,
                            currentUserCode: 'STF_1',
                            onShowDetail: (r) =>
                                showRegRequestDetailSheet(inner, request: r),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: Av2Spacing.sm),
              _btn(context, 'Admin: requests inbox', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegScaffold(
                      title: 'Regularization requests',
                      body: Padding(
                        padding: const EdgeInsets.all(Av2Spacing.md),
                        child: RegAdminInboxView(
                          requests: RegularizationFixtures.adminInbox,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Av2Colors.surface,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(Av2Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
            border: Border.all(color: Av2Colors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: Av2Text.bodyMedium)),
              const Icon(Icons.chevron_right, color: Av2Colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
