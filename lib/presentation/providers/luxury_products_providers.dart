import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_luxury_product_repository.dart';
import '../../domain/luxury_product.dart';

final mockLuxuryProductRepositoryProvider = Provider<MockLuxuryProductRepository>(
  (ref) => const MockLuxuryProductRepository(),
);

final luxuryProductsProvider = Provider<List<LuxuryProduct>>((ref) {
  final repo = ref.watch(mockLuxuryProductRepositoryProvider);
  return repo.getAll();
});

final luxuryProductByIdProvider = Provider.family<LuxuryProduct?, String>((ref, id) {
  final products = ref.watch(luxuryProductsProvider);
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
});

