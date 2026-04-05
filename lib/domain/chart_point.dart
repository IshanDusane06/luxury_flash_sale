/// Single sample for the live / historical chart (immutable, isolate-safe).
class ChartPoint {
  const ChartPoint({
    required this.tMs,
    required this.price,
  });

  final int tMs;
  final double price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartPoint && tMs == other.tMs && price == other.price;

  @override
  int get hashCode => Object.hash(tMs, price);
}
