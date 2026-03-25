import 'package:sultan/core/constants/api_constants.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/features/category/domain/models/category.dart';

class CategoryRepository {
  final ApiClient _client;

  CategoryRepository({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient.instance;

  Future<List<Category>> getAll() async {
    final list = await _client.getList(ApiConstants.categoryPath);
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> getById(String id) async {
    final json = await _client.get('${ApiConstants.categoryPath}/$id');
    return Category.fromJson(json);
  }

  Future<String> create(CategoryCreateRequest request) async {
    final json = await _client.post(
      ApiConstants.categoryPath,
      body: request.toJson(),
    );
    return json['id'] as String;
  }

  Future<void> update(String id, CategoryUpdateRequest request) async {
    await _client.put(
      '${ApiConstants.categoryPath}/$id',
      body: request.toJson(),
    );
  }

  Future<void> delete(String id) async {
    await _client.delete('${ApiConstants.categoryPath}/$id');
  }
}
