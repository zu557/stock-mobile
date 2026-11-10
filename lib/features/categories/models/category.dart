class Category {
  const Category({
    required this.id,
    required this.name,
    required this.productCount,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final int productCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    productCount: (json['productCount'] as num?)?.toInt() ?? 0,
  );
}

class CategoryInput {
  const CategoryInput({required this.name, this.description});

  final String name;
  final String? description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description?.trim().isEmpty == true
        ? null
        : description?.trim(),
  };
}
