/// Live tick from the mock WebSocket stream.
class FlashDropSnapshot {
  const FlashDropSnapshot({
    required this.currentPrice,
    required this.remainingInventory,
  });

  final double currentPrice;
  final int remainingInventory;
}
