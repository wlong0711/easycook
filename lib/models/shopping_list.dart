class ShoppingListItem {
  final String name;
  final bool done;
  final DateTime? addedDate;

  ShoppingListItem({
    required this.name,
    this.done = false,
    this.addedDate,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      name: json['name'] ?? '',
      done: json['done'] ?? false,
      addedDate: json['addedDate'] != null
          ? DateTime.tryParse(json['addedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'done': done,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  ShoppingListItem copyWith({
    String? name,
    bool? done,
    DateTime? addedDate,
  }) {
    return ShoppingListItem(
      name: name ?? this.name,
      done: done ?? this.done,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class ShoppingListRecipe {
  final String recipeId;
  final String name;
  final String image;
  final List<ShoppingListItem> ingredients;

  ShoppingListRecipe({
    required this.recipeId,
    required this.name,
    required this.image,
    required this.ingredients,
  });

  factory ShoppingListRecipe.fromJson(Map<String, dynamic> json, String id) {
    return ShoppingListRecipe(
      recipeId: id,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((item) => ShoppingListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
    };
  }

  ShoppingListRecipe copyWith({
    String? recipeId,
    String? name,
    String? image,
    List<ShoppingListItem>? ingredients,
  }) {
    return ShoppingListRecipe(
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      image: image ?? this.image,
      ingredients: ingredients ?? this.ingredients,
    );
  }
} 