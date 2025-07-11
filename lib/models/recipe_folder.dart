class RecipeFolder {
  final String id;
  final String name;
  final DateTime createdAt;
  final int recipeCount;

  RecipeFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.recipeCount = 0,
  });

  factory RecipeFolder.fromJson(Map<String, dynamic> json, String id) {
    return RecipeFolder(
      id: id,
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      recipeCount: json['recipeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt,
      'recipeCount': recipeCount,
    };
  }

  RecipeFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? recipeCount,
  }) {
    return RecipeFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      recipeCount: recipeCount ?? this.recipeCount,
    );
  }

  bool get isUncategorized => id == 'uncategorized';
} 