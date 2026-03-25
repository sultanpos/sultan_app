import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/features/category/data/repositories/category_repository.dart';
import 'package:sultan/features/category/domain/models/category.dart';
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

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [categoryRepositoryProvider.overrideWithValue(mockRepo)],
  );

  final tCategories = [
    const Category(id: '1', name: 'Electronics', children: []),
    Category(
      id: '2',
      name: 'Clothing',
      children: [const CategoryChild(id: '3', name: 'Shirts')],
    ),
  ];

  group('CategoryController initial state', () {
    test('starts as CategoryInitial', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(
        container.read(categoryControllerProvider),
        isA<CategoryInitial>(),
      );
    });
  });

  group('CategoryController.load', () {
    test('transitions Initial → Loading → CategoryLoaded on success', () async {
      when(() => mockRepo.getAll()).thenAnswer((_) async => tCategories);

      final container = buildContainer();
      addTearDown(container.dispose);

      final states = <CategoryState>[];
      container.listen(
        categoryControllerProvider,
        (_, next) => states.add(next),
      );

      await container.read(categoryControllerProvider.notifier).load();

      expect(states[0], isA<CategoryLoading>());
      expect(states[1], isA<CategoryLoaded>());
      expect((states[1] as CategoryLoaded).categories, hasLength(2));
    });

    test('transitions to CategoryError on failure', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('Connection refused'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(categoryControllerProvider.notifier).load();

      expect(container.read(categoryControllerProvider), isA<CategoryError>());
    });

    test('error message for SocketException', () async {
      when(
        () => mockRepo.getAll(),
      ).thenThrow(Exception('SocketException: Connection refused'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(categoryControllerProvider.notifier).load();

      final state = container.read(categoryControllerProvider) as CategoryError;
      expect(state.message, contains('Cannot connect'));
    });

    test('error message for 404', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('404'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(categoryControllerProvider.notifier).load();

      final state = container.read(categoryControllerProvider) as CategoryError;
      expect(state.message, contains('not found'));
    });

    test('error message for 401', () async {
      when(() => mockRepo.getAll()).thenThrow(Exception('401'));

      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(categoryControllerProvider.notifier).load();

      final state = container.read(categoryControllerProvider) as CategoryError;
      expect(state.message, contains('Session expired'));
    });
  });

  group('CategoryController.create', () {
    test('returns true and reloads on success', () async {
      final request = CategoryCreateRequest(name: 'New');
      when(() => mockRepo.create(request)).thenAnswer((_) async => '99');
      when(() => mockRepo.getAll()).thenAnswer((_) async => tCategories);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .create(request);

      expect(result, isTrue);
      expect(container.read(categoryControllerProvider), isA<CategoryLoaded>());
    });

    test('returns false and sets error on failure', () async {
      final request = CategoryCreateRequest(name: 'Bad');
      when(() => mockRepo.create(request)).thenThrow(Exception('Server error'));

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .create(request);

      expect(result, isFalse);
      expect(container.read(categoryControllerProvider), isA<CategoryError>());
    });
  });

  group('CategoryController.update', () {
    test('returns true and reloads on success', () async {
      final request = CategoryUpdateRequest(name: 'Updated');
      when(() => mockRepo.update('1', request)).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => tCategories);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .update('1', request);

      expect(result, isTrue);
    });

    test('returns false and sets error on failure', () async {
      final request = CategoryUpdateRequest(name: 'X');
      when(
        () => mockRepo.update('99', request),
      ).thenThrow(Exception('Not found 404'));

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .update('99', request);

      expect(result, isFalse);
      final state = container.read(categoryControllerProvider) as CategoryError;
      expect(state.message, contains('not found'));
    });
  });

  group('CategoryController.delete', () {
    test('returns true and reloads on success', () async {
      when(() => mockRepo.delete('1')).thenAnswer((_) async {});
      when(() => mockRepo.getAll()).thenAnswer((_) async => tCategories);

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .delete('1');

      expect(result, isTrue);
    });

    test('returns false and sets error on failure', () async {
      when(
        () => mockRepo.delete('99'),
      ).thenThrow(Exception('Connection refused SocketException'));

      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(categoryControllerProvider.notifier)
          .delete('99');

      expect(result, isFalse);
      final state = container.read(categoryControllerProvider) as CategoryError;
      expect(state.message, contains('Cannot connect'));
    });
  });
}
