import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/category/data/repositories/category_repository.dart';
import 'package:sultan/features/category/domain/models/category.dart';
import 'package:sultan/features/category/presentation/category_page.dart';
import 'package:sultan/features/category/presentation/controllers/category_controller.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(CategoryCreateRequest(name: ''));
    registerFallbackValue(CategoryUpdateRequest(name: ''));
  });

  setUp(() {
    mockRepo = MockCategoryRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [categoryRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: CategoryPage()),
    );
  }

  testWidgets('shows loading indicator while loading', (tester) async {
    final completer = Completer<List<Category>>();
    when(() => mockRepo.getAll()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildApp());
    await tester.pump(); // allow microtask to trigger load()

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty state when no categories', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No categories yet'), findsOneWidget);
    expect(find.text('Add Category'), findsOneWidget);
  });

  testWidgets('shows list of categories when loaded', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [
        const Category(id: '1', name: 'Electronics', children: []),
        const Category(id: '2', name: 'Clothing', children: []),
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Clothing'), findsOneWidget);
  });

  testWidgets('shows category description when present', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [
        const Category(
          id: '1',
          name: 'Electronics',
          description: 'Electronic devices',
          children: [],
        ),
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Electronic devices'), findsOneWidget);
  });

  testWidgets('shows children inside expansion tile', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [
        Category(
          id: '1',
          name: 'Electronics',
          children: [const CategoryChild(id: '2', name: 'Phones')],
        ),
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();

    expect(find.text('Phones'), findsOneWidget);
  });

  testWidgets('shows child description inside expansion tile', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [
        Category(
          id: '1',
          name: 'Electronics',
          children: [
            const CategoryChild(
              id: '2',
              name: 'Phones',
              description: 'Mobile phones',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile phones'), findsOneWidget);
  });

  testWidgets('shows no subcategories placeholder in empty expansion tile', (
    tester,
  ) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electronics'));
    await tester.pumpAndSettle();

    expect(find.text('No subcategories'), findsOneWidget);
  });

  testWidgets('shows error message and retry button on error', (tester) async {
    when(
      () => mockRepo.getAll(),
    ).thenThrow(const SocketException('Connection refused'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Cannot connect to server.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry button calls load again', (tester) async {
    var callCount = 0;
    when(() => mockRepo.getAll()).thenAnswer((_) async {
      callCount++;
      throw const SocketException('Connection refused');
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(callCount, greaterThan(1));
  });

  testWidgets('FAB is present and tapping it opens create dialog', (
    tester,
  ) async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Category'), findsWidgets);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('AppBar title is Categories', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
  });

  testWidgets('tapping edit icon opens edit dialog', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Category'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping add child icon opens create dialog with parent name', (
    tester,
  ) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('Add Category'), findsWidgets);
    expect(find.text('Under: Electronics'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping delete icon shows confirmation dialog', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Category'), findsOneWidget);
    expect(find.text('Delete "Electronics"?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('cancel in delete dialog does not call delete', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => mockRepo.delete(any()));
  });

  testWidgets('confirming delete calls delete and reloads', (tester) async {
    when(() => mockRepo.getAll()).thenAnswer(
      (_) async => [const Category(id: '1', name: 'Electronics', children: [])],
    );
    when(() => mockRepo.delete('1')).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.delete('1')).called(1);
  });

  testWidgets(
    'delete dialog shows subcategory warning when category has children',
    (tester) async {
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => [
          Category(
            id: '1',
            name: 'Electronics',
            children: [const CategoryChild(id: '2', name: 'Phones')],
          ),
        ],
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This category has subcategories.'),
        findsOneWidget,
      );
    },
  );
}
