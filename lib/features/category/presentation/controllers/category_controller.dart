import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

sealed class CategoryState {
  const CategoryState();
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  const CategoryLoaded(this.categories);
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
}

class CategoryController extends Notifier<CategoryState> {
  @override
  CategoryState build() => const CategoryInitial();

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<void> load() async {
    state = const CategoryLoading();
    try {
      final categories = await _repo.getAll();
      state = CategoryLoaded(categories);
    } catch (e) {
      state = CategoryError(_parseError(e));
    }
  }

  Future<bool> create(CategoryCreateRequest request) async {
    try {
      await _repo.create(request);
      await load();
      return true;
    } catch (e) {
      state = CategoryError(_parseError(e));
      return false;
    }
  }

  Future<bool> update(String id, CategoryUpdateRequest request) async {
    try {
      await _repo.update(id, request);
      await load();
      return true;
    } catch (e) {
      state = CategoryError(_parseError(e));
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      await load();
      return true;
    } catch (e) {
      state = CategoryError(_parseError(e));
      return false;
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('404')) return 'Category not found.';
    if (msg.contains('401')) return 'Session expired. Please log in again.';
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot connect to server.';
    }
    return 'An error occurred. Please try again.';
  }
}

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);
