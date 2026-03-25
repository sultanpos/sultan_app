import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/features/category/domain/models/category.dart';

void main() {
  group('CategoryChild.fromJson', () {
    test('parses all fields', () {
      final child = CategoryChild.fromJson({
        'id': '2',
        'name': 'Phones',
        'description': 'Mobile phones',
      });

      expect(child.id, '2');
      expect(child.name, 'Phones');
      expect(child.description, 'Mobile phones');
    });

    test('parses without description', () {
      final child = CategoryChild.fromJson({'id': '3', 'name': 'Tablets'});

      expect(child.id, '3');
      expect(child.name, 'Tablets');
      expect(child.description, isNull);
    });
  });

  group('Category.fromJson', () {
    test('parses all fields with children', () {
      final category = Category.fromJson({
        'id': '1',
        'name': 'Electronics',
        'description': 'Electronic devices',
        'children': [
          {'id': '2', 'name': 'Phones', 'description': 'Mobile phones'},
        ],
      });

      expect(category.id, '1');
      expect(category.name, 'Electronics');
      expect(category.description, 'Electronic devices');
      expect(category.children, hasLength(1));
      expect(category.children.first.name, 'Phones');
    });

    test('parses without description and empty children list', () {
      final category = Category.fromJson({
        'id': '1',
        'name': 'Electronics',
        'children': [],
      });

      expect(category.description, isNull);
      expect(category.children, isEmpty);
    });

    test('parses with null children field', () {
      final category = Category.fromJson({'id': '1', 'name': 'Electronics'});

      expect(category.children, isEmpty);
    });

    test('parses multiple children', () {
      final category = Category.fromJson({
        'id': '1',
        'name': 'Electronics',
        'children': [
          {'id': '2', 'name': 'Phones'},
          {'id': '3', 'name': 'Laptops'},
        ],
      });

      expect(category.children, hasLength(2));
      expect(category.children[1].name, 'Laptops');
    });
  });

  group('CategoryCreateRequest.toJson', () {
    test('includes all fields when set', () {
      final req = CategoryCreateRequest(
        name: 'Electronics',
        description: 'Electronic devices',
        parentId: '10',
      );

      expect(req.toJson(), {
        'name': 'Electronics',
        'description': 'Electronic devices',
        'parent_id': '10',
      });
    });

    test('omits optional fields when null', () {
      final req = CategoryCreateRequest(name: 'Electronics');

      expect(req.toJson(), {'name': 'Electronics'});
      expect(req.toJson().containsKey('description'), isFalse);
      expect(req.toJson().containsKey('parent_id'), isFalse);
    });

    test('includes description without parentId', () {
      final req = CategoryCreateRequest(
        name: 'Electronics',
        description: 'Devices',
      );

      final json = req.toJson();
      expect(json['description'], 'Devices');
      expect(json.containsKey('parent_id'), isFalse);
    });
  });

  group('CategoryUpdateRequest.toJson', () {
    test('includes all fields when set', () {
      final req = CategoryUpdateRequest(
        name: 'Updated',
        description: 'Updated desc',
        parentId: '5',
      );

      expect(req.toJson(), {
        'name': 'Updated',
        'description': 'Updated desc',
        'parent_id': '5',
      });
    });

    test('omits optional fields when null', () {
      final req = CategoryUpdateRequest(name: 'Updated');

      expect(req.toJson(), {'name': 'Updated'});
    });

    test('includes only description without parentId', () {
      final req = CategoryUpdateRequest(name: 'X', description: 'Desc only');

      final json = req.toJson();
      expect(json['description'], 'Desc only');
      expect(json.containsKey('parent_id'), isFalse);
    });
  });
}
