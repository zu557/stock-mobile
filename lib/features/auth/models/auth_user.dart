class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.image,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? image;

  bool get canManageProducts => role == 'ADMIN' || role == 'STOREKEEPER';
  bool get canDeactivateProducts => role == 'ADMIN';
  bool get canManageCategories => role == 'ADMIN' || role == 'STOREKEEPER';
  bool get canDeleteCategories => role == 'ADMIN';
  bool get canViewPurchases => role == 'ADMIN' || role == 'STOREKEEPER';
  bool get canCreatePurchases => role == 'ADMIN' || role == 'STOREKEEPER';
  bool get canViewSales => role == 'ADMIN' || role == 'SALES_STAFF';
  bool get canCreateSales => role == 'ADMIN' || role == 'SALES_STAFF';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'UNKNOWN',
    image: json['image'] as String?,
  );
}
