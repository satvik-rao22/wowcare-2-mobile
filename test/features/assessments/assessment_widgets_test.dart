import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_shell_chrome.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_scope_chip.dart';
import 'package:wowcare/presentation/features/assessments/widgets/averages_tree.dart';
import 'package:wowcare/presentation/features/assessments/widgets/domain_score_tile.dart';
import 'package:wowcare/presentation/features/assessments/widgets/scale_button_row.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ScaleButtonRow', () {
    testWidgets('renders five buttons and reports the picked score',
        (tester) async {
      int? picked;
      await tester.pumpWidget(_host(
        ScaleButtonRow(value: 2, onPick: (v) => picked = v),
      ));

      for (final n in ['1', '2', '3', '4', '5']) {
        expect(find.text(n), findsOneWidget);
      }

      await tester.tap(find.text('4'));
      expect(picked, 4);
    });
  });

  group('AssessmentBottomNav', () {
    testWidgets('shows all four sections and emits the tapped one',
        (tester) async {
      AssessmentSection? selected;
      await tester.pumpWidget(_host(
        AssessmentBottomNav(
          current: AssessmentSection.students,
          onSelect: (s) => selected = s,
        ),
      ));

      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Classrooms'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Parameters'), findsOneWidget);

      await tester.tap(find.text('Parameters'));
      expect(selected, AssessmentSection.framework);
    });
  });

  group('DomainScoreTile', () {
    testWidgets('formats a score to one decimal', (tester) async {
      await tester.pumpWidget(_host(
        const DomainScoreTile(shortLabel: 'Social', score: 3.5),
      ));
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('3.5'), findsOneWidget);
    });

    testWidgets('renders a dash when unscored', (tester) async {
      await tester.pumpWidget(_host(
        const DomainScoreTile(shortLabel: 'Cognitive', score: null),
      ));
      expect(find.text('–'), findsOneWidget);
    });
  });

  group('AssessmentScopeChip', () {
    testWidgets('shows the value and a chevron when tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_host(
        AssessmentScopeChip(
          icon: Icons.home_rounded,
          eyebrow: 'CLASSROOM',
          value: 'Sunflower Room',
          onTap: () => tapped = true,
        ),
      ));
      expect(find.text('CLASSROOM'), findsOneWidget);
      expect(find.text('Sunflower Room'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      await tester.tap(find.text('Sunflower Room'));
      expect(tapped, isTrue);
    });

    testWidgets('shows a lock instead of a chevron when locked', (tester) async {
      await tester.pumpWidget(_host(
        const AssessmentScopeChip(
          icon: Icons.home_rounded,
          value: 'My Room',
          locked: true,
        ),
      ));
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });
  });

  group('AssessmentAveragesTree', () {
    final now = DateTime(2026, 6, 1);
    final domain = AssessmentDomain(
      id: 'soc',
      name: 'Social & Emotional',
      createdAt: now,
      updatedAt: now,
      subdomains: [
        AssessmentSubdomain(
          id: 'soc.reg',
          domainId: 'soc',
          name: 'Self-Regulation',
          createdAt: now,
          updatedAt: now,
          milestones: [
            AssessmentMilestone(
              id: 'soc.reg.1',
              subdomainId: 'soc.reg',
              domainId: 'soc',
              name: 'Manages transitions',
              assignedAgeGroups: const ['AGE-3-4Y'],
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
      ],
    );

    Assessment record(int score) => Assessment(
          id: 'a1',
          studentId: 's1',
          milestoneId: 'soc.reg.1',
          subdomainId: 'soc.reg',
          domainId: 'soc',
          score: score,
          assessedBy: 'u1',
          assessedAt: now,
          periodStart: now,
          periodEnd: now,
        );

    testWidgets('renders the domain average and expands to children',
        (tester) async {
      await tester.pumpWidget(_host(
        SizedBox(
          width: 360,
          child: AssessmentAveragesTree(
            domains: [domain],
            records: [record(4)],
            showMilestones: true,
          ),
        ),
      ));

      // Domain row + its average (first domain auto-expands).
      expect(find.text('Social & Emotional'), findsOneWidget);
      expect(find.text('4.0'), findsWidgets);
      expect(find.text('Self-Regulation'), findsOneWidget);
      expect(find.text('Manages transitions'), findsOneWidget);
    });
  });
}
