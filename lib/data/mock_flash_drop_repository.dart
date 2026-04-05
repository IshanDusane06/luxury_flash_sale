import 'dart:async';
import 'dart:math';

import '../domain/flash_drop_snapshot.dart';

/// Mock “WebSocket” that emits live price + inventory on a fixed cadence.
class MockFlashDropRepository {
  MockFlashDropRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _interval = Duration(milliseconds: 800);

  Stream<FlashDropSnapshot> watchLiveFlashDrop({
    required double openingPrice,
    int openingInventory = 7,
  }) async* {
    var price = openingPrice;
    var inventory = openingInventory;
    final minPrice = max(1000.0, openingPrice * 0.75);
    final maxPrice = openingPrice * 1.25;

    while (true) {
      await Future<void>.delayed(_interval);
      final drift = (_random.nextDouble() - 0.5) * 180;
      price = (price + drift).clamp(minPrice, maxPrice);
      if (_random.nextDouble() < 0.15 && inventory > 0) {
        inventory -= 1;
      }
      yield FlashDropSnapshot(
        currentPrice: double.parse(price.toStringAsFixed(2)),
        remainingInventory: inventory,
      );
    }
  }
}
