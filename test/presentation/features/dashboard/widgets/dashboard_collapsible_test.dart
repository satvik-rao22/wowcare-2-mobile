import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_collapsible.dart';

/// Performance contract for the dashboard collapse animation.
///
/// Every dashboard card wraps its body in [DashboardCollapsible], so a slip
/// here costs every card on every dashboard. These tests pin the things that
/// keep it cheap: the body is built at most once per toggle and never per
/// animation frame, the body is not re-rasterised per frame while it moves,
/// nothing ticks while a card is at rest, a resting card is fully opaque and
/// unclipped, and a collapsed body is not in the tree at all.
void main() {
  Future<void> pumpFrames(WidgetTester tester, int count) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Finder inCollapsible(Type type) => find.descendant(
    of: find.byType(DashboardCollapsible),
    matching: find.byType(type),
  );

  RenderClipRect clipOf(WidgetTester tester) =>
      tester.renderObject<RenderClipRect>(inCollapsible(ClipRect));

  RenderAnimatedOpacity fadeOf(WidgetTester tester) =>
      tester.renderObject<RenderAnimatedOpacity>(inCollapsible(FadeTransition));

  double heightOf(WidgetTester tester) =>
      tester.getSize(find.byType(DashboardCollapsible)).height;

  group('DashboardCollapsible', () {
    testWidgets('a stable body is built once per mount, never per frame', (
      tester,
    ) async {
      int builds = 0;
      final Widget body = _Probe(onBuild: () => builds++);
      final _HostController host = _HostController();

      await tester.pumpWidget(_Host(controller: host, body: body));
      expect(builds, 1);
      expect(heightOf(tester), _Probe.height);

      host.collapsed = true;
      await tester.pump();
      await pumpFrames(tester, 6);
      expect(builds, 1, reason: 'animation frames must not rebuild the body');
      expect(heightOf(tester), lessThan(_Probe.height));
      expect(heightOf(tester), greaterThan(0));

      await tester.pumpAndSettle();
      expect(find.byType(_Probe), findsNothing);
      expect(heightOf(tester), 0);

      host.collapsed = false;
      await tester.pump();
      expect(builds, 2, reason: 'reopening remounts the body exactly once');
      await pumpFrames(tester, 6);
      expect(builds, 2, reason: 'opening frames must not rebuild the body');
      await tester.pumpAndSettle();
      expect(builds, 2);
      expect(heightOf(tester), _Probe.height);
    });

    testWidgets('a body rebuilt by its card costs one build per toggle', (
      tester,
    ) async {
      // Real cards pass `_buildBody(...)`, a fresh widget per card build. The
      // card rebuilds once per toggle (its own setState), so the body may be
      // built once per toggle, and still never per animation frame.
      int builds = 0;
      final _HostController host = _HostController();

      await tester.pumpWidget(
        _Host(
          controller: host,
          bodyBuilder: () => _Probe(onBuild: () => builds++),
        ),
      );
      expect(builds, 1);

      host.collapsed = true;
      await tester.pump();
      final int afterToggle = builds;
      expect(afterToggle, lessThanOrEqualTo(2));
      await pumpFrames(tester, 8);
      expect(builds, afterToggle, reason: 'no per-frame body builds');
      await tester.pumpAndSettle();
      expect(find.byType(_Probe), findsNothing);

      host.collapsed = false;
      await tester.pump();
      final int afterReopen = builds;
      expect(afterReopen, afterToggle + 1);
      await pumpFrames(tester, 8);
      expect(builds, afterReopen, reason: 'no per-frame body builds');
      await tester.pumpAndSettle();
      expect(builds, afterReopen);
    });

    testWidgets('the body is not re-rasterised on every animation frame', (
      tester,
    ) async {
      // The fade keeps the body in its own layer while it moves, so each
      // frame only re-composites that layer at a new alpha and height. If
      // this ever regresses to a repaint per frame, a heavy card body would
      // be redrawn 18 times per toggle.
      int paints = 0;
      final _HostController host = _HostController();
      await tester.pumpWidget(
        _Host(controller: host, body: _Probe(onPaint: () => paints++)),
      );
      expect(paints, 1);

      host.collapsed = true;
      await tester.pump();
      final int atStart = paints;
      await pumpFrames(tester, 10);
      expect(
        paints - atStart,
        lessThanOrEqualTo(2),
        reason: 'ten frames of motion must not repaint the body ten times',
      );
      await tester.pumpAndSettle();

      host.collapsed = false;
      await tester.pump();
      final int atReopen = paints;
      await pumpFrames(tester, 10);
      expect(paints - atReopen, lessThanOrEqualTo(2));
    });

    testWidgets('nothing ticks while the card is at rest', (tester) async {
      final _HostController host = _HostController();
      await tester.pumpWidget(_Host(controller: host, body: const _Probe()));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);

      host.collapsed = true;
      await tester.pump();
      await pumpFrames(tester, 3);
      expect(tester.binding.transientCallbackCount, 1);

      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);

      host.collapsed = false;
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a resting open card is fully opaque and unclipped', (
      tester,
    ) async {
      // A fully opaque fade is a no-op for the compositor; a partial one is a
      // saveLayer. And the clip only exists while the body is moving, so a
      // key's rim or a shadow at the foot of an open body is never cut off.
      final _HostController host = _HostController();
      await tester.pumpWidget(_Host(controller: host, body: const _Probe()));

      expect(fadeOf(tester).opacity.value, 1);
      expect(clipOf(tester).clipBehavior, Clip.none);

      host.collapsed = true;
      await tester.pump();
      await pumpFrames(tester, 6);
      expect(fadeOf(tester).opacity.value, lessThan(1));
      expect(fadeOf(tester).opacity.value, greaterThan(0));
      expect(clipOf(tester).clipBehavior, Clip.hardEdge);

      await tester.pumpAndSettle();
      expect(inCollapsible(ClipRect), findsNothing);
      expect(inCollapsible(FadeTransition), findsNothing);

      host.collapsed = false;
      await tester.pumpAndSettle();
      expect(fadeOf(tester).opacity.value, 1);
      expect(clipOf(tester).clipBehavior, Clip.none);
    });

    testWidgets('a card that starts collapsed never builds its body', (
      tester,
    ) async {
      int builds = 0;
      final _HostController host = _HostController(collapsed: true);
      await tester.pumpWidget(
        _Host(controller: host, body: _Probe(onBuild: () => builds++)),
      );
      expect(builds, 0);
      expect(find.byType(_Probe), findsNothing);
      expect(heightOf(tester), 0);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}

/// A card body that reports its builds and its paints.
class _Probe extends StatelessWidget {
  const _Probe({this.onBuild, this.onPaint});

  static const double height = 120;

  final VoidCallback? onBuild;
  final VoidCallback? onPaint;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return CustomPaint(
      size: const Size(double.infinity, height),
      painter: _CountingPainter(onPaint),
    );
  }
}

class _CountingPainter extends CustomPainter {
  const _CountingPainter(this.onPaint);

  final VoidCallback? onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint?.call();
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF888888));
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}

class _HostController extends ChangeNotifier {
  _HostController({bool collapsed = false}) : _collapsed = collapsed;

  bool _collapsed;
  bool get collapsed => _collapsed;
  set collapsed(bool value) {
    if (value == _collapsed) return;
    _collapsed = value;
    notifyListeners();
  }
}

/// Stands in for a dashboard card: owns the collapsed flag and rebuilds when
/// it flips, passing either one stable body or a fresh body per build.
class _Host extends StatelessWidget {
  const _Host({required this.controller, this.body, this.bodyBuilder})
    : assert(body != null || bodyBuilder != null);

  final _HostController controller;
  final Widget? body;
  final Widget Function()? bodyBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Column(
            children: [
              DashboardCollapsible(
                collapsed: controller.collapsed,
                child: body ?? bodyBuilder!(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
