class Recipe {
  final int id;
  final String title;
  final String? image;
  final List<String> cuisines;
  final List<String> diets;
  final int? readyInMinutes;
  final List<Map<String, dynamic>> extendedIngredients;
  final Map<String, dynamic>? nutrition;
  final String? instructions;
  final List<String>? dishTypes;
  final String? summary;

  Recipe({
    required this.id,
    required this.title,
    this.image,
    this.cuisines = const [],
    this.diets = const [],
    this.readyInMinutes,
    this.extendedIngredients = const [],
    this.nutrition,
    this.instructions,
    this.dishTypes,
    this.summary,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'],
      cuisines: List<String>.from(json['cuisines'] ?? []),
      diets: List<String>.from(json['diets'] ?? []),
      readyInMinutes: json['readyInMinutes'],
      extendedIngredients: List<Map<String, dynamic>>.from(json['extendedIngredients'] ?? []),
      nutrition: json['nutrition'],
      instructions: json['instructions'],
      dishTypes: json['dishTypes'] != null ? List<String>.from(json['dishTypes']) : null,
      summary: json['summary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'cuisines': cuisines,
      'diets': diets,
      'readyInMinutes': readyInMinutes,
      'extendedIngredients': extendedIngredients,
      'nutrition': nutrition,
      'instructions': instructions,
      'dishTypes': dishTypes,
      'summary': summary,
    };
  }

  String get cuisinesString => cuisines.isNotEmpty ? cuisines.join(', ') : "Not specified";
  String get dietsString => diets.isNotEmpty ? diets.join(', ') : "Not specified";
  String get readyTimeString => readyInMinutes != null ? "$readyInMinutes mins" : "– mins";
  
  String get caloriesString {
    try {
      final nutrients = nutrition?['nutrients'];
      if (nutrients is List) {
        final cal = nutrients.firstWhere(
          (n) => n['name'] == 'Calories',
          orElse: () => null,
        );
        return cal != null ? "${cal['amount'].round()} kcal" : "– kcal";
      }
    } catch (_) {}
    return "– kcal";
  }
} 