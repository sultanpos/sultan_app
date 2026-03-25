import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/core/services/api_client.dart';
import 'package:sultan/features/category/data/repositories/category_repository.dart';
import 'package:sultan/features/category/domain/models/category.dart';

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
      state = CategoryLoaded(await _repo.getAll());
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> create(CategoryCreateRequest request) => _guard(() async {
    await _repo.create(request);
    await load();
  });

  Future<bool> update(String id, CategoryUpdateRequest request) =>
      _guard(() async {
        await _repo.update(id, request);
        await load();
      });

  Future<bool> delete(String id) => _guard(() async {
    await _repo.delete(id);
    await load();
  });

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  void _handleError(Object e) {
    if (e is ApiException) {
      state = CategoryError(_messageForApiException(e));
    } else if (e is SocketException) {
      state = const CategoryError('Cannot connect to server.');
    } else {
      state = const CategoryError('An error occurred. Please try again.');
    }
  }

  String _messageForApiException(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Session expired. Please log in again.';
      case 404:
        return 'Category not found.';
      default:
        return e.message;
    }
  }
}

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);
