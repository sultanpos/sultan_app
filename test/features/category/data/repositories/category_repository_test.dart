import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/features/category/data/repositories/category_repository.dart';
import 'package:sultan/features/category/domain/models/category.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late CategoryRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = CategoryRepository(apiClient: mockClient);
  });

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('CategoryRepository.getAll', () {
    test('returns list of categories', () async {
      when(() => mockClient.getList(ApiConstants.categoryPath)).thenAnswer(
        (_) async => [
          {
            'id': '1',
            'name': 'Electronics',
            'description': 'Devices',
            'children': [],
          },
          {
            'id': '2',
            'name': 'Clothing',
            'children': [
              {'id': '3', 'name': 'Shirts'},
            ],
          },
        ],
      );

      final result = await repo.getAll();

      expect(result, hasLength(2));
      expect(result.first.name, 'Electronics');
      expect(result[1].children.first.name, 'Shirts');
    });

    test('throws ApiException on error', () async {
      when(
        () => mockClient.getList(ApiConstants.categoryPath),
      ).thenThrow(ApiException(statusCode: 500, message: 'Server error'));

      expect(() => repo.getAll(), throwsA(isA<ApiException>()));
    });
  });

  group('CategoryRepository.getById', () {
    test('returns category by id', () async {
      when(() => mockClient.get('${ApiConstants.categoryPath}/1')).thenAnswer(
        (_) async => {'id': '1', 'name': 'Electronics', 'children': []},
      );

      final result = await repo.getById('1');

      expect(result.id, '1');
      expect(result.name, 'Electronics');
    });

    test('throws ApiException on 404', () async {
      when(
        () => mockClient.get('${ApiConstants.categoryPath}/99'),
      ).thenThrow(ApiException(statusCode: 404, message: 'Not found'));

      expect(() => repo.getById('99'), throwsA(isA<ApiException>()));
    });
  });

  group('CategoryRepository.create', () {
    test('returns new id on success', () async {
      final request = CategoryCreateRequest(name: 'Electronics');
      when(
        () =>
            mockClient.post(ApiConstants.categoryPath, body: request.toJson()),
      ).thenAnswer((_) async => {'id': '42'});

      final id = await repo.create(request);

      expect(id, '42');
    });

    test('passes description and parentId in body', () async {
      final request = CategoryCreateRequest(
        name: 'Phones',
        description: 'Mobile phones',
        parentId: '1',
      );
      when(
        () =>
            mockClient.post(ApiConstants.categoryPath, body: request.toJson()),
      ).thenAnswer((_) async => {'id': '7'});

      final id = await repo.create(request);

      expect(id, '7');
      verify(
        () => mockClient.post(
          ApiConstants.categoryPath,
          body: {
            'name': 'Phones',
            'description': 'Mobile phones',
            'parent_id': '1',
          },
        ),
      ).called(1);
    });

    test('throws ApiException on error', () async {
      final request = CategoryCreateRequest(name: 'Fail');
      when(
        () => mockClient.post(
          ApiConstants.categoryPath,
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException(statusCode: 400, message: 'Bad request'));

      expect(() => repo.create(request), throwsA(isA<ApiException>()));
    });
  });

  group('CategoryRepository.update', () {
    test('calls put with correct path and body', () async {
      final request = CategoryUpdateRequest(
        name: 'Updated',
        description: 'New',
      );
      when(
        () => mockClient.put(
          '${ApiConstants.categoryPath}/1',
          body: request.toJson(),
        ),
      ).thenAnswer((_) async => {});

      await repo.update('1', request);

      verify(
        () => mockClient.put(
          '${ApiConstants.categoryPath}/1',
          body: {'name': 'Updated', 'description': 'New'},
        ),
      ).called(1);
    });

    test('throws ApiException on error', () async {
      final request = CategoryUpdateRequest(name: 'X');
      when(
        () => mockClient.put(
          '${ApiConstants.categoryPath}/99',
          body: any(named: 'body'),
        ),
      ).thenThrow(ApiException(statusCode: 404, message: 'Not found'));

      expect(() => repo.update('99', request), throwsA(isA<ApiException>()));
    });
  });

  group('CategoryRepository.delete', () {
    test('calls delete with correct path', () async {
      when(
        () => mockClient.delete('${ApiConstants.categoryPath}/1'),
      ).thenAnswer((_) async => {});

      await repo.delete('1');

      verify(
        () => mockClient.delete('${ApiConstants.categoryPath}/1'),
      ).called(1);
    });

    test('throws ApiException on error', () async {
      when(
        () => mockClient.delete('${ApiConstants.categoryPath}/99'),
      ).thenThrow(ApiException(statusCode: 404, message: 'Not found'));

      expect(() => repo.delete('99'), throwsA(isA<ApiException>()));
    });
  });
}
