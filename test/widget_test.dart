import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/workout.dart';
import 'package:flutter_application_1/features/products/models/product.dart';
import 'package:flutter_application_1/features/auth/models/auth_user.dart';
import 'package:flutter_application_1/features/auth/providers/auth_provider.dart';

void main() {
  testWidgets('Stock-Flow dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(FakeAuthNotifier.new)],
        child: const StockFlowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory at a glance'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  test('Workout model metrics calculation test', () {
    final workout = Workout(
      id: '1',
      exerciseName: 'Bench Press',
      category: 'Chest',
      sets: [
        WorkoutSet(setNumber: 1, reps: 10, weight: 60),
        WorkoutSet(setNumber: 2, reps: 8, weight: 70),
        WorkoutSet(setNumber: 3, reps: 6, weight: 80),
      ],
      date: DateTime.now(),
    );

    expect(workout.totalSets, equals(3));
    expect(workout.totalReps, equals(24));
    expect(workout.totalVolume, equals(600 + 560 + 480)); // 1640.0
    expect(workout.maxWeight, equals(80.0));
  });

  test('Product model accepts list and create response numeric formats', () {
    final listProduct = Product.fromJson({
      'id': 'product-1',
      'code': 'P-1',
      'name': 'Paper',
      'unit': 'BOX',
      'reorderLevel': 4.5,
      'currentStock': 3,
      'stockStatus': 'LOW',
      'category': {'id': 'category-1', 'name': 'Office'},
    });
    final createdProduct = Product.fromJson({
      'id': 'product-2',
      'code': 'P-2',
      'name': 'Ink',
      'unit': 'LITER',
      'reorderLevel': '2.500',
      'quantityOnHand': '0.000',
      'categoryId': 'category-1',
    });

    expect(listProduct.currentStock, 3);
    expect(listProduct.stockStatus, StockStatus.low);
    expect(listProduct.categoryName, 'Office');
    expect(createdProduct.reorderLevel, 2.5);
    expect(createdProduct.currentStock, 0);
    expect(createdProduct.stockStatus, StockStatus.outOfStock);
    expect(createdProduct.categoryId, 'category-1');
  });
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => const AuthUser(
    id: 'test-user',
    name: 'Test User',
    email: 'test@example.com',
    role: 'ADMIN',
  );
}
