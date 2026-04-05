import '../domain/luxury_product.dart';

/// In-memory catalog used by the PDP + list page.
class MockLuxuryProductRepository {
  const MockLuxuryProductRepository();

  List<LuxuryProduct> getAll() => const [
        LuxuryProduct(
          id: 'rolex_submariner',
          title: 'Rolex Submariner',
          subtitle: 'Oystersteel · Cerachrom · Calibre 3235',
        ),
        LuxuryProduct(
          id: 'omega_seamaster',
          title: 'Omega Seamaster',
          subtitle: 'Co-Axial · Titanium · Wave dial',
        ),
        LuxuryProduct(
          id: 'tag_heuer_carrera',
          title: 'TAG Heuer Carrera',
          subtitle: 'Chronograph · Calibre 16 · Sapphire',
        ),
        LuxuryProduct(
          id: 'designer_sneaker_limited',
          title: 'Designer Sneaker (Limited)',
          subtitle: 'Italian leather · Hand-finished stitching',
        ),
        LuxuryProduct(
          id: 'patek_philippe_auction',
          title: 'Patek Philippe (Auction)',
          subtitle: 'Rare dial · Executive ref. edition',
        ),
      ];
}

