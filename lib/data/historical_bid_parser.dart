import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import '../domain/chart_point.dart';

/// Simulates a massive API payload (~50k records), parses JSON, and returns
/// chart-ready points. All heavy work runs in a background isolate so the UI
/// isolate stays responsive (spinner animates at 60fps).
Future<List<ChartPoint>> parseHistoricalBidPayloadInIsolate() {
  return Isolate.run(_generateParseAndDownsample);
}

/// Top-level for [Isolate.run] — must not close over main-isolate state.
List<ChartPoint> _generateParseAndDownsample() {
  final rnd = Random(42);
  final sb = StringBuffer();
  sb.write('[');
  var p = 11800.0;
  for (var i = 0; i < 50000; i++) {
    if (i > 0) {
      sb.write(',');
    }
    p += (rnd.nextDouble() - 0.48) * 42;
    sb.write('{"t":$i,"p":${p.toStringAsFixed(4)}}');
  }
  sb.write(']');

  final decoded = jsonDecode(sb.toString()) as List<dynamic>;

  const targetSamples = 1800;
  final step = max(1, decoded.length ~/ targetSamples);
  final out = <ChartPoint>[];
  for (var i = 0; i < decoded.length; i += step) {
    final m = decoded[i]! as Map<String, dynamic>;
    out.add(
      ChartPoint(
        tMs: (m['t']! as num).toInt() * 1000,
        price: (m['p']! as num).toDouble(),
      ),
    );
  }
  return out;
}
