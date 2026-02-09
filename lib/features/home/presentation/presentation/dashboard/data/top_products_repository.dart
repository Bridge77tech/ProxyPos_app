import 'dart:async';

import 'model/product_model.dart';
import 'model/variant.dart';

/// Repository responsible for fetching top products.
abstract class TopProductsRepository {
  Future<List<Products>> fetchTopProducts({Map<String, dynamic> params});
}

/// A temporary in-memory repository returning stubbed data until backend is wired.
class InMemoryTopProductsRepository implements TopProductsRepository {
  @override
  Future<List<Products>> fetchTopProducts({Map<String, dynamic> params = const {}}) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));

    // Return some stubbed products
    return [
      Products(
        id: '1',
        name: 'Nestle Nido Essential',
        barcode: '1234567890',
        category: 'Dairy',
        currentStock: 20,
        piecesPerPack: 6,
        imagePath: 'assets/images/item.png',
        variants: [
          Variants(
            id: 'v1',
            size: 'Tin 150g',
            packPrice: 100.0,
          ),
        ],
      ),
      Products(
        id: '2',
        name: 'Coca-Cola',
        barcode: '0987654321',
        category: 'Beverage',
        currentStock: 50,
        piecesPerPack: 12,
        imagePath: 'assets/images/item.png',
        variants: [
          Variants(
            id: 'v2',
            size: 'Bottle 500ml',
            packPrice: 12.5,
          ),
        ],
      ),
    ];
  }
}
