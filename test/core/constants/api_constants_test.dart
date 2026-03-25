import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/core/constants/api_constants.dart';

void main() {
  setUp(() => ApiConstants.setBaseUrl('http://localhost:8721'));

  group('ApiConstants', () {
    test('default baseUrl is localhost:8721', () {
      expect(ApiConstants.baseUrl, 'http://localhost:8721');
    });

    test('setBaseUrl updates the base URL', () {
      ApiConstants.setBaseUrl('http://192.168.1.100:8721');
      expect(ApiConstants.baseUrl, 'http://192.168.1.100:8721');
    });

    test('setBaseUrl strips trailing slash', () {
      ApiConstants.setBaseUrl('http://192.168.1.100:8721/');
      expect(ApiConstants.baseUrl, 'http://192.168.1.100:8721');
    });

    test('uri builds full URL from path', () {
      expect(
        ApiConstants.uri('/api/auth').toString(),
        'http://localhost:8721/api/auth',
      );
    });

    test('uri appends query parameters', () {
      final uri = ApiConstants.uri('/api/user', {'page': '1', 'limit': '10'});
      expect(uri.queryParameters['page'], '1');
      expect(uri.queryParameters['limit'], '10');
    });

    test('all API paths return correct values', () {
      expect(ApiConstants.loginPath, '/api/auth');
      expect(ApiConstants.refreshPath, '/api/auth/refresh');
      expect(ApiConstants.logoutPath, '/api/auth');
      expect(ApiConstants.branchPath, '/api/branch');
      expect(ApiConstants.categoryPath, '/api/category');
      expect(ApiConstants.productPath, '/api/product');
      expect(ApiConstants.customerPath, '/api/customer');
      expect(ApiConstants.supplierPath, '/api/supplier');
      expect(ApiConstants.userPath, '/api/user');
    });
  });
}
