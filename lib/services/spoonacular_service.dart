import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularService {
  final String apiKey = '52a3569d728c4360aeec59f495f43626';
  final String baseUrl = 'https://api.spoonacular.com';

  // ✅ Fetch Random Recipes (with nutrition)
  Future<List> getRandomRecipes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipes/random?number=10&includeNutrition=true&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['recipes'];
    } else {
      throw Exception('Failed to load recipes');
    }
  }


  // ✅ Search Recipes by Name (basic search only)
  Future<List> searchRecipes(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipes/complexSearch?query=$query&addRecipeNutrition=true&number=10&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to search recipes');
    }
  }

  // ✅ Get Recipe Details by ID
  Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recipes/$recipeId/information?apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recipe details');
    }
  }
}
