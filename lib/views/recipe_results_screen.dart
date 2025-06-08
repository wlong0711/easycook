import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_details_screen.dart';

class RecipeResultsScreen extends StatefulWidget {
  final String? ingredients; // From pantry
  final String? filterType;  // e.g., 'cuisine'
  final String? filterValue;

  const RecipeResultsScreen({
    this.ingredients,
    this.filterType,
    this.filterValue,
    super.key,
  });

  @override
  State<RecipeResultsScreen> createState() => _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends State<RecipeResultsScreen> {
  List recipes = [];
  bool isLoading = true;
  final String apiKey = '52a3569d728c4360aeec59f495f43626';

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    String url;

    if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
      url =
          'https://api.spoonacular.com/recipes/complexSearch?includeIngredients=${widget.ingredients}&addRecipeNutrition=true&number=10&apiKey=$apiKey';
    } else if (widget.filterType != null && widget.filterValue != null) {
      url =
          'https://api.spoonacular.com/recipes/complexSearch?${widget.filterType}=${widget.filterValue}&addRecipeNutrition=true&number=10&apiKey=$apiKey';
    } else {
      url =
          'https://api.spoonacular.com/recipes/random?number=10&addRecipeNutrition=true&apiKey=$apiKey';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          recipes = data is List ? data : data['results'] ?? [];
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String getCalories(Map<String, dynamic> recipe) {
    try {
      final nutrients = recipe['nutrition']?['nutrients'];
      if (nutrients is List) {
        final cal = nutrients.firstWhere((n) => n['name'] == 'Calories', orElse: () => null);
        return cal != null ? "${cal['amount'].round()} kcal" : "– kcal";
      }
    } catch (_) {}
    return "– kcal";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text("Recipe Results"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search_off, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No recipes found.",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final imageUrl = (recipe['image'] ?? '').replaceAll(RegExp(r'\.+$'), '');

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailsScreen(recipeId: recipe['id']),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                imageUrl.isNotEmpty
                                    ? imageUrl
                                    : 'https://via.placeholder.com/150',
                                height: 130,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/placeholder.png',
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    getCalories(recipe),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
