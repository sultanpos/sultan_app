class CategoryChild {
  final String id;
  final String name;
  final String? description;

  const CategoryChild({required this.id, required this.name, this.description});

  factory CategoryChild.fromJson(Map<String, dynamic> json) => CategoryChild(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
  );
}

class Category {
  final String id;
  final String name;
  final String? description;
  final List<CategoryChild> children;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    children: (json['children'] as List<dynamic>? ?? [])
        .map((e) => CategoryChild.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class CategoryCreateRequest {
  final String name;
  final String? description;
  final String? parentId;

  const CategoryCreateRequest({
    required this.name,
    this.description,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (parentId != null) 'parent_id': parentId,
  };
}

class CategoryUpdateRequest {
  final String name;
  final String? description;
  final String? parentId;

  const CategoryUpdateRequest({
    required this.name,
    this.description,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (parentId != null) 'parent_id': parentId,
  };
}
