/// Represents a purchasable “Flash Drop” luxury item.
///
/// This model is intentionally small because the PDP animation and live chart
/// are the main focus; product detail data can be expanded later.
class LuxuryProduct {
  const LuxuryProduct({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

