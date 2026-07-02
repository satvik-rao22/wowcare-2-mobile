import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Period-over-period radar comparison (PRD §12.3, FR-CA-10, FR-SC-05): the
/// current period (indigo) vs the previous period (amber), one axis per domain.
///
/// Fully custom-painted for a mobile-first feel:
///  • **Interactive** — tap any domain point (or its label) to reveal a callout
///    with the exact current/previous scores; tap again or tap the centre to
///    dismiss.
///  • **Animated** — the polygons sweep out from the centre on first build and
///    smoothly tween from the old shape to the new one whenever the data
///    changes (e.g. the educator updates scores or switches month), so progress
///    visibly "morphs" rather than snapping.
///
/// Accessibility (PRD §21.4): wrapped in a [Semantics] node whose label is a
/// textual data table; a colour legend is rendered below. A grouped-bar
/// fallback is used for < 3 domains (a radar needs ≥ 3 axes).
class AssessmentRadarChart extends StatefulWidget {
  const AssessmentRadarChart({
    super.key,
    required this.title,
    required this.data,
    required this.currentLabel,
    required this.previousLabel,
    this.maxValue = 5,
  });

  final String title;
  final List<RadarDatum> data;
  final String currentLabel;
  final String previousLabel;

  /// Top of the scale (scores are 1–5).
  final double maxValue;

  @override
  State<AssessmentRadarChart> createState() => _AssessmentRadarChartState();
}

class _AssessmentRadarChartState extends State<AssessmentRadarChart>
    with SingleTickerProviderStateMixin {
  // Themed: current period draws in the active brand colour; previous is a
  // muted companion tone per theme.
  static Color get _current => AssessmentUi.brand;
  static Color get _previous => AssessmentUi.isThemeV2
      ? const Color(0xFF8AD6D3) // muted cyan (2.0)
      : const Color(0xFFC4B5FD); // muted violet (1.0)

  late final AnimationController _controller;
  late final Animation<double> _t;

  // Tween endpoints, element-wise, so the lines morph between shapes.
  late List<double> _curFrom;
  late List<double> _curTo;
  late List<double> _prevFrom;
  late List<double> _prevTo;

  int? _selected;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _curTo = _readCurrent();
    _prevTo = _readPrevious();
    // Start collapsed at the centre and sweep outward on first build.
    _curFrom = List<double>.filled(_curTo.length, 0);
    _prevFrom = List<double>.filled(_prevTo.length, 0);
    unawaited(_controller.forward());
  }

  @override
  void didUpdateWidget(AssessmentRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCur = _readCurrent();
    final newPrev = _readPrevious();
    final lengthChanged = newCur.length != _curTo.length;
    if (lengthChanged ||
        !_listsEqual(newCur, _curTo) ||
        !_listsEqual(newPrev, _prevTo)) {
      final p = _t.value;
      // Re-tween from whatever is on screen right now to the new values.
      _curFrom = lengthChanged
          ? List<double>.filled(newCur.length, 0)
          : _lerpList(_curFrom, _curTo, p);
      _prevFrom = lengthChanged
          ? List<double>.filled(newPrev.length, 0)
          : _lerpList(_prevFrom, _prevTo, p);
      _curTo = newCur;
      _prevTo = newPrev;
      if (lengthChanged) _selected = null;
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> _readCurrent() => widget.data.map((d) => d.current).toList();
  List<double> _readPrevious() => widget.data.map((d) => d.previous).toList();

  static bool _listsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.0001) return false;
    }
    return true;
  }

  static List<double> _lerpList(List<double> a, List<double> b, double t) {
    return List<double>.generate(
      a.length,
      (i) => a[i] + (b[i] - a[i]) * t,
      growable: false,
    );
  }

  String get _semanticsSummary {
    final parts = widget.data
        .map((d) => '${d.domainName}: '
            '${widget.currentLabel} ${d.current.toStringAsFixed(1)}, '
            '${widget.previousLabel} ${d.previous.toStringAsFixed(1)}')
        .join('. ');
    return '${widget.title}. $parts';
  }

  void _handleTap(Offset local, Size size) {
    final geo = _RadarGeometry(size, widget.data.length, widget.maxValue);
    final v = local - geo.center;
    final dist = v.distance;
    // A tap near the middle clears the selection.
    if (dist < geo.radius * 0.12) {
      if (_selected != null) setState(() => _selected = null);
      return;
    }
    // Snap to the nearest axis by angle, within a generous outer ring so the
    // label, the vertex and the connecting lines are all comfortably tappable.
    if (dist > geo.radius * 1.5) {
      if (_selected != null) setState(() => _selected = null);
      return;
    }
    final tapAngle = math.atan2(v.dy, v.dx);
    var best = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < widget.data.length; i++) {
      final delta = _angularDistance(tapAngle, geo.angle(i));
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    setState(() => _selected = _selected == best ? null : best);
  }

  static double _angularDistance(double a, double b) {
    var d = (a - b).abs() % (2 * math.pi);
    if (d > math.pi) d = 2 * math.pi - d;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return LayoutBuilder(
      builder: (context, panel) {
        // Drive padding, title size and chart height off the panel's own width
        // so the chart sizes correctly inside a narrow two-column rail too.
        final panelWidth = panel.maxWidth;
        final pad = AssessmentUi.cardPadding(panelWidth);
        final chartHeight = AssessmentUi.radarHeight(panelWidth);
        return Container(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad - 2),
          decoration: AssessmentUi.softSurface(accent: _current),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _current.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.radar_rounded, size: 19,
                        color: _current),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: AssessmentUi.cardTitleStyle(panelWidth)),
                  ),
                ],
              ),
              if (data.length >= 3) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Text(
                    'Tap a point to see its score',
                    style:
                        TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: chartHeight,
                child: Semantics(
                  label: _semanticsSummary,
                  child: data.length < 3
                      ? _BarFallback(
                          data: data,
                          current: _current,
                          previous: _previous,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(constraints.maxWidth,
                                constraints.maxHeight);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) =>
                                  _handleTap(d.localPosition, size),
                              child: AnimatedBuilder(
                                animation: _t,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: size,
                                    painter: _RadarPainter(
                                      current:
                                          _lerpList(_curFrom, _curTo, _t.value),
                                      previous: _lerpList(
                                          _prevFrom, _prevTo, _t.value),
                                      labels: data
                                          .map((d) => d.domainName)
                                          .toList(),
                                      maxValue: widget.maxValue,
                                      currentColor: _current,
                                      previousColor: _previous,
                                      selected: _selected,
                                      currentLabel: widget.currentLabel,
                                      previousLabel: widget.previousLabel,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendDot(color: _current, label: widget.currentLabel),
                  _LegendDot(color: _previous, label: widget.previousLabel),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shared geometry so the painter and hit-testing agree on where each vertex is.
class _RadarGeometry {
  _RadarGeometry(this.size, this.count, this.maxValue)
      : center = Offset(size.width / 2, size.height / 2),
        radius = (math.min(size.width, size.height) / 2) - _labelGutter;

  static const double _labelGutter = 38;

  final Size size;
  final int count;
  final double maxValue;
  final Offset center;
  final double radius;

  double angle(int i) => -math.pi / 2 + (2 * math.pi * i) / count;

  Offset vertex(double value, int i) {
    final r = radius * (value / maxValue).clamp(0.0, 1.0);
    final a = angle(i);
    return center + Offset(math.cos(a) * r, math.sin(a) * r);
  }

  Offset axisEnd(int i) {
    final a = angle(i);
    return center + Offset(math.cos(a) * radius, math.sin(a) * radius);
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.current,
    required this.previous,
    required this.labels,
    required this.maxValue,
    required this.currentColor,
    required this.previousColor,
    required this.selected,
    required this.currentLabel,
    required this.previousLabel,
  });

  final List<double> current;
  final List<double> previous;
  final List<String> labels;
  final double maxValue;
  final Color currentColor;
  final Color previousColor;
  final int? selected;
  final String currentLabel;
  final String previousLabel;

  static const int _rings = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n < 3) return;
    final geo = _RadarGeometry(size, n, maxValue);

    _paintGrid(canvas, geo, n);
    _paintAxes(canvas, geo, n);
    // Previous underneath, current on top.
    _paintPolygon(canvas, geo, previous, previousColor, 0.16);
    _paintPolygon(canvas, geo, current, currentColor, 0.26);
    _paintVertices(canvas, geo, previous, previousColor);
    _paintVertices(canvas, geo, current, currentColor);
    _paintLabels(canvas, geo, n);
    if (selected != null && selected! < n) {
      _paintCallout(canvas, geo, size, selected!);
    }
  }

  void _paintGrid(Canvas canvas, _RadarGeometry geo, int n) {
    for (var ring = 1; ring <= _rings; ring++) {
      final f = ring / _rings;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = geo.angle(i);
        final p = geo.center +
            Offset(math.cos(a) * geo.radius * f, math.sin(a) * geo.radius * f);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          // Outer rings a touch darker than inner ones for a subtle depth cue.
          ..color = Color.lerp(
              const Color(0xFFF1F3F9), const Color(0xFFDFE3EE), f)!,
      );
    }
  }

  void _paintAxes(Canvas canvas, _RadarGeometry geo, int n) {
    final paint = Paint()
      ..color = const Color(0xFFE4E7F0)
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final highlighted = i == selected;
      paint
        ..color = highlighted
            ? currentColor.withValues(alpha: 0.45)
            : const Color(0xFFE4E7F0)
        ..strokeWidth = highlighted ? 1.6 : 1;
      canvas.drawLine(geo.center, geo.axisEnd(i), paint);
    }
  }

  void _paintPolygon(Canvas canvas, _RadarGeometry geo, List<double> values,
      Color color, double fillAlpha) {
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = geo.vertex(values[i], i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: fillAlpha));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  void _paintVertices(Canvas canvas, _RadarGeometry geo, List<double> values,
      Color color) {
    for (var i = 0; i < values.length; i++) {
      final p = geo.vertex(values[i], i);
      final isSel = i == selected;
      canvas.drawCircle(p, isSel ? 6 : 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(p, isSel ? 5 : 3, Paint()..color = color);
    }
  }

  void _paintLabels(Canvas canvas, _RadarGeometry geo, int n) {
    for (var i = 0; i < n; i++) {
      final a = geo.angle(i);
      final isSel = i == selected;
      final anchor = geo.center +
          Offset(math.cos(a) * (geo.radius + 14),
              math.sin(a) * (geo.radius + 14));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? currentColor : const Color(0xFF6B7280),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 78);
      // Position the label box so it radiates outward from its anchor.
      final cos = math.cos(a);
      final sin = math.sin(a);
      var dx = anchor.dx - tp.width / 2;
      if (cos > 0.3) dx = anchor.dx; // right side: left-align to anchor
      if (cos < -0.3) dx = anchor.dx - tp.width; // left side: right-align
      final dy = anchor.dy - (sin < -0.3 ? tp.height : (sin > 0.3 ? 0 : tp.height / 2));
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  void _paintCallout(Canvas canvas, _RadarGeometry geo, Size size, int i) {
    final curVal = current[i];
    final prevVal = previous[i];
    // Anchor on the outer of the two series points for this axis.
    final anchorVal = math.max(curVal, prevVal);
    final anchor = geo.vertex(anchorVal, i);

    final title = labels[i];
    final line1 = '${AssessmentAggregation.formatAverage(curVal)}  '
        '· $currentLabel';
    final line2 = '${AssessmentAggregation.formatAverage(prevVal)}  '
        '· $previousLabel';

    final titleTp = _tp(title, const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1B2559)));
    final l1Tp = _tp(line1, const TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
    final l2Tp = _tp(line2, const TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

    const pad = 10.0;
    const dot = 8.0;
    const gap = 6.0;
    final contentW = [
      titleTp.width,
      dot + gap + l1Tp.width,
      dot + gap + l2Tp.width,
    ].reduce(math.max);
    final w = contentW + pad * 2;
    final h = pad * 2 + titleTp.height + 6 + l1Tp.height + 4 + l2Tp.height;

    // Place the bubble above the anchor by default, flipping below / clamping
    // so it always stays inside the chart bounds.
    var left = anchor.dx - w / 2;
    var top = anchor.dy - h - 12;
    if (top < 4) top = anchor.dy + 12; // not enough room above → drop below
    top = top.clamp(4.0, size.height - h - 4);
    left = left.clamp(4.0, size.width - w - 4);
    final rect = Rect.fromLTWH(left, top, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Soft shadow + card.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = currentColor.withValues(alpha: 0.20),
    );

    var y = top + pad;
    titleTp.paint(canvas, Offset(left + pad, y));
    y += titleTp.height + 6;
    canvas.drawCircle(Offset(left + pad + dot / 2, y + l1Tp.height / 2),
        dot / 2, Paint()..color = currentColor);
    l1Tp.paint(canvas, Offset(left + pad + dot + gap, y));
    y += l1Tp.height + 4;
    canvas.drawCircle(Offset(left + pad + dot / 2, y + l2Tp.height / 2),
        dot / 2, Paint()..color = previousColor);
    l2Tp.paint(canvas, Offset(left + pad + dot + gap, y));
  }

  TextPainter _tp(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 160);

  @override
  bool shouldRepaint(_RadarPainter old) {
    return selected != old.selected ||
        !_AssessmentRadarChartState._listsEqual(current, old.current) ||
        !_AssessmentRadarChartState._listsEqual(previous, old.previous) ||
        currentLabel != old.currentLabel ||
        previousLabel != old.previousLabel;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}

/// Grouped-bar fallback for 1–2 domains (radar requires ≥ 3 axes).
class _BarFallback extends StatelessWidget {
  const _BarFallback({
    required this.data,
    required this.current,
    required this.previous,
  });

  final List<RadarDatum> data;
  final Color current;
  final Color previous;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('No data for this period',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.domainName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _bar(d.current / 5, current,
                  AssessmentAggregation.formatAverage(d.current)),
              const SizedBox(height: 4),
              _bar(d.previous / 5, previous,
                  AssessmentAggregation.formatAverage(d.previous)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _bar(double fraction, Color color, String label) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            // Animate the fill from empty to its value on build.
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
