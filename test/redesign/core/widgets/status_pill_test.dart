import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const c = Colourway.l4;

  (Color? fill, Color? ink) colours(WidgetTester tester, String label) {
    final box = tester.widget<Container>(
      find.ancestor(of: find.text(label), matching: find.byType(Container)),
    );
    final text = tester.widget<Text>(find.text(label));
    return ((box.decoration! as BoxDecoration).color, text.style?.color);
  }

  group('StatusPill', () {
    testWidgets('each tone draws its own tint and ink', (tester) async {
      final expected = <PillTone, (Color, Color)>{
        PillTone.success: (c.successBg, c.successFg),
        PillTone.danger: (c.dangerBg, c.dangerFg),
        PillTone.neutral: (c.neutralBg, c.neutralFg),
        PillTone.staff: (c.staffBg, c.staffFg),
        PillTone.student: (c.studentBg, c.student),
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _host(StatusPill(label: entry.key.name, tone: entry.key)),
        );
        expect(
          colours(tester, entry.key.name),
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    testWidgets('custom takes the colours it is handed', (tester) async {
      await tester.pumpWidget(
        _host(
          StatusPill(
            label: 'Task',
            tone: PillTone.custom,
            foreground: c.task,
            background: c.taskBg,
          ),
        ),
      );
      expect(colours(tester, 'Task'), (c.taskBg, c.task));
    });

    testWidgets('neutral is the default', (tester) async {
      await tester.pumpWidget(_host(const StatusPill(label: 'Not Marked')));
      expect(colours(tester, 'Not Marked'), (c.neutralBg, c.neutralFg));
    });
  });
}
