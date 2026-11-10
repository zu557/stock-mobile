enum ProductUnit {
  piece('PIECE'),
  box('BOX'),
  pack('PACK'),
  kg('KG'),
  liter('LITER'),
  meter('METER');

  const ProductUnit(this.apiValue);
  final String apiValue;
}

enum StockStatus {
  outOfStock('OUT_OF_STOCK'),
  low('LOW'),
  inStock('IN_STOCK');

  const StockStatus(this.apiValue);
  final String apiValue;
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.reorderLevel,
    required this.currentStock,
    required this.stockStatus,
    this.isActive = true,
    this.description,
    this.categoryId,
    this.categoryName,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final ProductUnit unit;
  final double reorderLevel;
  final double currentStock;
  final StockStatus stockStatus;
  final bool isActive;
  final String? categoryId;
  final String? categoryName;

  static double _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final quantity = _parseNumber(
      json['currentStock'] ?? json['quantityOnHand'],
    );
    final reorder = _parseNumber(json['reorderLevel']);
    final category = json['category'];
    final statusValue = json['stockStatus']?.toString();
    final status = StockStatus.values.firstWhere(
      (value) => value.apiValue == statusValue,
      orElse: () => quantity == 0
          ? StockStatus.outOfStock
          : quantity <= reorder
          ? StockStatus.low
          : StockStatus.inStock,
    );
    return Product(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: ProductUnit.values.firstWhere(
        (value) => value.apiValue == json['unit'],
        orElse: () => ProductUnit.piece,
      ),
      reorderLevel: reorder,
      currentStock: quantity,
      stockStatus: status,
      isActive: json['isActive'] as bool? ?? true,
      categoryId:
          json['categoryId'] as String? ??
          (category is Map<String, dynamic> ? category['id'] as String? : null),
      categoryName: category is Map<String, dynamic>
          ? category['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toInputJson() => {
    'code': code,
    'name': name,
    'description': description,
    'unit': unit.apiValue,
    'reorderLevel': reorderLevel,
    'categoryId': categoryId,
  };
}

class ProductInput {
  const ProductInput({
    required this.code,
    required this.name,
    required this.unit,
    required this.reorderLevel,
    required this.categoryId,
    this.description,
  });

  final String code;
  final String name;
  final ProductUnit unit;
  final double reorderLevel;
  final String categoryId;
  final String? description;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'description': description,
    'unit': unit.apiValue,
    'reorderLevel': reorderLevel,
    'categoryId': categoryId,
  };
}

class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<Product> products;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory ProductPage.fromJson(Map<String, dynamic> json) => ProductPage(
    products: (json['data'] as List<dynamic>? ?? const [])
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    limit: (json['limit'] as num?)?.toInt() ?? 10,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}
