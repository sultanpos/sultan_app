class ApiConstants {
  ApiConstants._();

  static String _baseUrl = 'http://localhost:8721';

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    // Strip trailing slash
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Auth
  static String get loginPath => '/api/auth';
  static String get refreshPath => '/api/auth/refresh';
  static String get logoutPath => '/api/auth';

  // Branch
  static String get branchPath => '/api/branch';

  // Category
  static String get categoryPath => '/api/category';

  // Product
  static String get productPath => '/api/product';

  // Customer
  static String get customerPath => '/api/customer';

  // Supplier
  static String get supplierPath => '/api/supplier';

  // User
  static String get userPath => '/api/user';

  // Helper to build full URL
  static Uri uri(String path, [Map<String, dynamic>? queryParams]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
  }
}
