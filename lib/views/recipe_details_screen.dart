import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  RecipeDetailsScreen({required this.recipeId});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;
  final String apiKey = '52a3569d728c4360aeec59f495f43626';

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    try {
      final url = 'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey';
      print("Calling: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Recipe loaded: ${data['title']}");
        setState(() {
          recipe = data;
          isLoading = false;
        });
      } else {
        print("Failed to load. Status: ${response.statusCode}");
        setState(() {
          isLoading = false;
          recipe = {}; // avoid null error
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        isLoading = false;
        recipe = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe?['title'] ?? 'Recipe Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipe == null || recipe!.isEmpty
              ? Center(child: Text('Failed to load recipe'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        (recipe?['image'] ?? 'https://via.placeholder.com/300').replaceAll(RegExp(r'\.+\$'), ''),
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/images/placeholder.png');
                        },
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 16),
                      Text(
                        recipe?['title'] ?? 'No Title Available',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                        (recipe?['summary'] ?? 'No description available.')
                            .replaceAll(RegExp(r'<[^>]*>'), ''),
                      ),
                      SizedBox(height: 16),
                      Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...?recipe?['extendedIngredients']?.map<Widget>((ingredient) {
                        return Text("- ${ingredient['original']}");
                      }).toList(),
                      SizedBox(height: 16),
                      Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (recipe?['analyzedInstructions'] != null &&
                          recipe!['analyzedInstructions'].isNotEmpty) ...[
                        ...List.generate(
                          recipe!['analyzedInstructions'][0]['steps'].length,
                          (index) {
                            final step = recipe!['analyzedInstructions'][0]['steps'][index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('${step['number']}. ${step['step']}'),
                            );
                          },
                        )
                      ] else ...[
                        Text("No step-by-step instructions available."),
                      ],
                    ],
                  ),
                ),
    );
  }
}
