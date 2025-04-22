import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_details_screen.dart';

class RecipeResultsScreen extends StatefulWidget {
  final String? ingredients; // For pantry search
  final String? filterType;  // 'cuisine' or 'diet'
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
      // 🔍 Pantry ingredients search
      url =
          'https://api.spoonacular.com/recipes/findByIngredients?ingredients=${widget.ingredients}&number=10&apiKey=$apiKey';
    } else if (widget.filterType != null && widget.filterValue != null) {
      // 🍜 Category search (cuisine/diet)
      url =
          'https://api.spoonacular.com/recipes/complexSearch?${widget.filterType}=${widget.filterValue}&number=10&apiKey=$apiKey';
    } else {
      // Fallback (optional)
      url =
          'https://api.spoonacular.com/recipes/random?number=10&apiKey=$apiKey';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recipes = data is List ? data : data['results'] ?? [];
          isLoading = false;
        });
      } else {
        print('Error ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Results'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? Center(child: Text("No recipes found."))
              : ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final imageUrl = (recipe['image'] ?? '').replaceAll(RegExp(r'\.+$'), '');

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                              )
                            : Icon(Icons.image_not_supported),
                        title: Text(recipe['title'] ?? 'No Title'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailsScreen(
                                recipeId: recipe['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
