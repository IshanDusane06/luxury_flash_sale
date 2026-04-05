import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/chart_point.dart';

/// Premium minimal line + area chart driven by [CustomPainter].
class FlashDropLineChart extends StatelessWidget {
  const FlashDropLineChart({
    super.key,
    required this.points,
    this.lineColor = const Color(0xFF2EE59D),
    this.fillTopAlpha = 0.22,
  });

  final List<ChartPoint> points;
  final Color lineColor;
  final double fillTopAlpha;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FlashDropChartPainter(
          points: points,
          lineColor: lineColor,
          fillTopAlpha: fillTopAlpha,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FlashDropChartPainter extends CustomPainter {
  _FlashDropChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillTopAlpha,
  });

  final List<ChartPoint> points;
  final Color lineColor;
  final double fillTopAlpha;

  static const _maxPlotPoints = 200;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final plot = points.length > _maxPlotPoints
        ? points.sublist(points.length - _maxPlotPoints)
        : points;

    final w = size.width;
    final h = size.height;
    // Room for Y tick labels (left) and X tick labels (bottom).
    const padL = 44.0;
    const padR = 10.0;
    const padT = 10.0;
    const padB = 30.0;
    final innerW = w - padL - padR;
    final innerH = h - padT - padB;

    final minT = plot.first.tMs.toDouble();
    final maxT = plot.last.tMs.toDouble();
    final spanT = (maxT - minT).abs() < 1e-6 ? 1.0 : (maxT - minT);

    final yScale = _computeYScale(plot);

    double xAt(int i) {
      final t = plot[i].tMs.toDouble();
      return padL + (t - minT) / spanT * innerW;
    }

    double yAt(int i) {
      final p = plot[i].price;
      return padT + (1 - (p - yScale.minY) / yScale.spanY) * innerH;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = padT + innerH * i / 4;
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);
    }

    final path = Path()..moveTo(xAt(0), yAt(0));
    for (var i = 1; i < plot.length; i++) {
      path.lineTo(xAt(i), yAt(i));
    }

    final fillPath = Path.from(path)
      ..lineTo(xAt(plot.length - 1), h - padB)
      ..lineTo(xAt(0), h - padB)
      ..close();

    final fillShader = ui.Gradient.linear(
      Offset(0, padT),
      Offset(0, h - padB),
      [
        lineColor.withValues(alpha: fillTopAlpha),
        lineColor.withValues(alpha: 0.0),
      ],
    );

    canvas.drawPath(
      fillPath,
      Paint()..shader = fillShader,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final lastX = xAt(plot.length - 1);
    final lastY = yAt(plot.length - 1);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final baselineY = padT +
        (1 - (plot.first.price - yScale.minY) / yScale.spanY) * innerH;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    _dashLine(
      canvas,
      Offset(padL, baselineY),
      Offset(w - padR, baselineY),
      dashPaint,
    );

    _paintYLabels(
      canvas,
      yScale: yScale,
      padL: padL,
      padT: padT,
      innerH: innerH,
      h: h,
      padB: padB,
    );
    _paintXLabels(
      canvas,
      plot: plot,
      minT: minT,
      spanT: spanT,
      padL: padL,
      padT: padT,
      innerW: innerW,
      w: w,
      h: h,
      padB: padB,
    );
  }

  /// Y range from [plot] only, with padding. Avoids forcing e.g. 15% of price
  /// as minimum span (that made high-priced series look like a flat line).
  _YScale _computeYScale(List<ChartPoint> plot) {
    var minP = plot.map((e) => e.price).reduce(math.min);
    var maxP = plot.map((e) => e.price).reduce(math.max);
    var span = (maxP - minP).abs();
    if (span < 1e-12) {
      final c = minP;
      minP = c - 1;
      maxP = c + 1;
      span = 2;
    }
    final mid = (minP + maxP) / 2.0;
    final relativeSpan = mid.abs() > 1e-9 ? span / mid.abs() : span;

    double displaySpan;
    if (relativeSpan < 0.025) {
      // Tight band vs price level: expand so wiggles use most of the chart.
      displaySpan = math.max(
        span * 5.0,
        math.max(mid.abs() * 0.03, 4.0),
      );
    } else {
      displaySpan = span;
    }

    final center = (minP + maxP) / 2.0;
    var yMin = center - displaySpan / 2.0;
    var yMax = center + displaySpan / 2.0;
    final padOuter = (yMax - yMin) * 0.06;
    yMin -= padOuter;
    yMax += padOuter;
    final spanY = (yMax - yMin).abs() < 1e-9 ? 1.0 : (yMax - yMin);
    return _YScale(minY: yMin, maxY: yMax, spanY: spanY);
  }

  void _paintYLabels(
    Canvas canvas, {
    required _YScale yScale,
    required double padL,
    required double padT,
    required double innerH,
    required double h,
    required double padB,
  }) {
    const tickCount = 5;
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 10,
      height: 1.0,
    );
    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final value = yScale.maxY - t * (yScale.maxY - yScale.minY);
      final y = padT + t * innerH;
      final text = _formatPrice(value);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: padL - 4);
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
  }

  void _paintXLabels(
    Canvas canvas, {
    required List<ChartPoint> plot,
    required double minT,
    required double spanT,
    required double padL,
    required double padT,
    required double innerW,
    required double w,
    required double h,
    required double padB,
  }) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 10,
      height: 1.0,
    );
    final anchors = <double>[0, 0.5, 1.0];
    for (final a in anchors) {
      final tMs = minT + a * spanT;
      final x = padL + a * innerW;
      final text = _formatElapsedFromStart(
        plot.first.tMs,
        tMs.round(),
      );
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      var left = x - tp.width / 2;
      left = left.clamp(4.0, w - tp.width - 4);
      tp.paint(canvas, Offset(left, h - padB + 4));
    }
  }

  static String _formatPrice(double v) {
    if (v.abs() >= 1000) {
      return '\$${(v / 1000).toStringAsFixed(v.abs() >= 10000 ? 1 : 2)}k';
    }
    return '\$${v.toStringAsFixed(0)}';
  }

  /// Elapsed time from first sample (works for synthetic tMs timelines).
  static String _formatElapsedFromStart(int firstT, int tMs) {
    final sec = ((tMs - firstT) / 1000).round().clamp(0, 1 << 30);
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '${h}h ${mm}m';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _dashLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 5.0;
    final d = b - a;
    final len = d.distance;
    final dir = d / len;
    var dist = 0.0;
    while (dist < len) {
      final s = a + dir * dist;
      final e = a + dir * (dist + dash).clamp(0.0, len);
      canvas.drawLine(s, e, paint);
      dist += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _FlashDropChartPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillTopAlpha != fillTopAlpha;
  }
}

class _YScale {
  const _YScale({
    required this.minY,
    required this.maxY,
    required this.spanY,
  });

  final double minY;
  final double maxY;
  final double spanY;
}
