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
      final categories = await _repo.getAll();
      state = CategoryLoaded(categories);
    } on ApiException catch (e) {
      state = CategoryError(_messageForApiException(e));
    } on SocketException {
      state = const CategoryError('Cannot connect to server.');
    } catch (_) {
      state = const CategoryError('An error occurred. Please try again.');
    }
  }

  Future<bool> create(CategoryCreateRequest request) async {
    try {
      await _repo.create(request);
      await load();
      return true;
    } on ApiException catch (e) {
      state = CategoryError(_messageForApiException(e));
      return false;
    } on SocketException {
      state = const CategoryError('Cannot connect to server.');
      return false;
    } catch (_) {
      state = const CategoryError('An error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> update(String id, CategoryUpdateRequest request) async {
    try {
      await _repo.update(id, request);
      await load();
      return true;
    } on ApiException catch (e) {
      state = CategoryError(_messageForApiException(e));
      return false;
    } on SocketException {
      state = const CategoryError('Cannot connect to server.');
      return false;
    } catch (_) {
      state = const CategoryError('An error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      await load();
      return true;
    } on ApiException catch (e) {
      state = CategoryError(_messageForApiException(e));
      return false;
    } on SocketException {
      state = const CategoryError('Cannot connect to server.');
      return false;
    } catch (_) {
      state = const CategoryError('An error occurred. Please try again.');
      return false;
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
