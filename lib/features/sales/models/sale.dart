enum SaleStatus {
  completed('COMPLETED');

  const SaleStatus(this.apiValue);
  final String apiValue;
}

class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String productId;
  final String productName;
  final String productCode;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return SaleItem(
      productId: product is Map<String, dynamic>
          ? product['id'] as String? ?? ''
          : json['productId'] as String? ?? '',
      productName: product is Map<String, dynamic>
          ? product['name'] as String? ?? 'Product'
          : 'Product',
      productCode: product is Map<String, dynamic>
          ? product['code'] as String? ?? ''
          : '',
      quantity: _number(json['quantity']),
      unitPrice: _number(json['unitPrice']),
      totalPrice: _number(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class Sale {
  const Sale({
    required this.id,
    required this.referenceNo,
    required this.soldAt,
    required this.status,
    required this.notes,
    required this.createdByName,
    required this.items,
    required this.total,
  });

  final String id;
  final String? referenceNo;
  final DateTime soldAt;
  final SaleStatus status;
  final String? notes;
  final String? createdByName;
  final List<SaleItem> items;
  final double total;

  factory Sale.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((value) => SaleItem.fromJson(value as Map<String, dynamic>))
        .toList();
    final createdBy = json['createdBy'];
    return Sale(
      id: json['id'] as String,
      referenceNo: json['referenceNo'] as String?,
      soldAt:
          DateTime.tryParse(json['soldAt']?.toString() ?? '') ?? DateTime.now(),
      status: SaleStatus.completed,
      notes: json['notes'] as String?,
      createdByName: createdBy is Map<String, dynamic>
          ? createdBy['name'] as String?
          : null,
      items: items,
      total: json['total'] == null
          ? items.fold(0, (sum, item) => sum + item.totalPrice)
          : _number(json['total']),
    );
  }
}

class SaleInput {
  const SaleInput({required this.soldAt, required this.items, this.notes});

  final DateTime soldAt;
  final List<SaleItem> items;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'soldAt': soldAt.toIso8601String(),
    'status': SaleStatus.completed.apiValue,
    'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
