import '../../domain/chart_point.dart';
import '../../domain/flash_drop_snapshot.dart';

/// Combined PDP state: latest live tick + merged chart series.
class FlashDropPdpState {
  const FlashDropPdpState({
    required this.snapshot,
    required this.chartPoints,
  });

  final FlashDropSnapshot snapshot;
  final List<ChartPoint> chartPoints;
}
