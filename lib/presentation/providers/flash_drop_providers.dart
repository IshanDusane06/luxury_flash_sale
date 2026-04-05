import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/historical_bid_parser.dart';
import '../../data/mock_flash_drop_repository.dart';
import '../../domain/chart_point.dart';
import '../../domain/flash_drop_snapshot.dart';
import 'flash_drop_pdp_state.dart';

final mockFlashDropRepositoryProvider = Provider<MockFlashDropRepository>(
  (ref) => MockFlashDropRepository(),
);

/// Parsed historical series (heavy work done in isolate).
final historicalChartPointsProvider = FutureProvider<List<ChartPoint>>((ref) {
  return parseHistoricalBidPayloadInIsolate();
});

/// Single subscription: live snapshot + chart (history + rolling live tail).
final flashDropPdpStateProvider = StreamProvider<FlashDropPdpState>((ref) async* {
  final historical = await ref.watch(historicalChartPointsProvider.future);
  if (historical.isEmpty) {
    throw StateError('Historical bid tape is empty after parse.');
  }
  final repo = ref.watch(mockFlashDropRepositoryProvider);
  final liveTail = <ChartPoint>[];
  var lastT = historical.last.tMs;
  // Initial frame: show mostly history, focused on the latest segment.
  List<ChartPoint> windowLastPoints(List<ChartPoint> full) {
    const windowSize = 320;
    if (full.length <= windowSize) return full;
    final start = full.length - windowSize;
    return full.sublist(start);
  }

  var combined = [...historical, ...liveTail];
  yield FlashDropPdpState(
    snapshot: FlashDropSnapshot(
      currentPrice: historical.last.price,
      remainingInventory: 7,
    ),
    chartPoints: windowLastPoints(combined),
  );
  await for (final snap in repo.watchLiveFlashDrop(
    openingPrice: historical.last.price,
    openingInventory: 7,
  )) {
    lastT += 800;
    liveTail.add(ChartPoint(tMs: lastT, price: snap.currentPrice));
    if (liveTail.length > 64) {
      liveTail.removeAt(0);
    }
    combined = [...historical, ...liveTail];
    yield FlashDropPdpState(
      snapshot: snap,
      chartPoints: windowLastPoints(combined),
    );
  }
});
