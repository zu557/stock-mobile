enum PurchaseStatus {
  draft('DRAFT'),
  completed('COMPLETED');

  const PurchaseStatus(this.apiValue);
  final String apiValue;
}

class PurchaseItem {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  final String productId;
  final String productName;
  final String productCode;
  final double quantity;
  final double unitCost;
  final double totalCost;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return PurchaseItem(
      productId:
          json['productId'] as String? ??
          (product is Map<String, dynamic> ? product['id'] as String? : null) ??
          '',
      productName: product is Map<String, dynamic>
          ? product['name'] as String? ?? 'Product'
          : 'Product',
      productCode: product is Map<String, dynamic>
          ? product['code'] as String? ?? ''
          : '',
      quantity: _number(json['quantity']),
      unitCost: _number(json['unitCost']),
      totalCost: _number(json['totalCost']),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitCost': unitCost,
  };
}

class Purchase {
  const Purchase({
    required this.id,
    required this.referenceNo,
    required this.purchasedAt,
    required this.status,
    required this.notes,
    required this.createdById,
    required this.createdByName,
    required this.items,
    required this.total,
  });

  final String id;
  final String? referenceNo;
  final DateTime purchasedAt;
  final PurchaseStatus status;
  final String? notes;
  final String? createdById;
  final String? createdByName;
  final List<PurchaseItem> items;
  final double total;

  bool get isDraft => status == PurchaseStatus.draft;

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((item) => PurchaseItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final rawStatus = json['status']?.toString();
    final status = PurchaseStatus.values.firstWhere(
      (value) => value.apiValue == rawStatus,
      orElse: () => PurchaseStatus.draft,
    );
    final createdBy = json['createdBy'];
    return Purchase(
      id: json['id'] as String,
      referenceNo: json['referenceNo'] as String?,
      purchasedAt:
          DateTime.tryParse(json['purchasedAt']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
      notes: json['notes'] as String?,
      createdById: json['createdById'] as String?,
      createdByName: createdBy is Map<String, dynamic>
          ? createdBy['name'] as String?
          : null,
      items: items,
      total: json['total'] == null
          ? items.fold(0, (sum, item) => sum + item.totalCost)
          : _number(json['total']),
    );
  }
}

class PurchaseInput {
  const PurchaseInput({
    required this.purchasedAt,
    required this.items,
    this.notes,
  });

  final DateTime purchasedAt;
  final List<PurchaseItem> items;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'purchasedAt': purchasedAt.toIso8601String(),
    'status': PurchaseStatus.draft.apiValue,
    'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
