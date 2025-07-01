import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import the caching library
import 'm_recipe_details_screen.dart';  // Import your RecipeDetailsScreen

class m_RecipeResultScreen extends StatefulWidget {
  const m_RecipeResultScreen({super.key});

  @override
  _m_RecipeResultScreenState createState() => _m_RecipeResultScreenState();
}

class _m_RecipeResultScreenState extends State<m_RecipeResultScreen> {
  List recipes = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('M_recipes')
          .get();

      if (!mounted) return;

      // Map Firestore data to a list of recipes
      setState(() {
        recipes = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc.get('title'),
            'calories': doc.get('calories'),
            'imageUrl': doc.get('imageUrl'),
            'prepTime': doc.get('prepTime'),
            'description': doc.get('description'),
            'ingredients': doc.get('ingredients'),
            'instructions': doc.get('instructions'),
            'cuisine': doc.get('cuisine'),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching recipes: $e';
      });
    }
  }

  String getCalories(Map<String, dynamic> recipe) {
    final calories = recipe['calories'];
    return calories != null ? "$calories kcal" : "– kcal";
  }

  String getCookingTime(Map<String, dynamic> recipe) {
    final minutes = recipe['prepTime'];
    return minutes != null ? "$minutes min" : "– min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text("Recipe Results"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading indicator
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 60, color: Colors.red),
                      SizedBox(height: 10),
                      Text(errorMessage,
                          style: TextStyle(fontSize: 16, color: Colors.red)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchRecipes, // Retry fetching recipes
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
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
                        childAspectRatio: 2.5 / 4, // Adjust vertical space as needed
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final imageUrl = recipe['imageUrl'] ?? '';  // Default to empty if no image

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => m_RecipeDetailsScreen(recipeId: recipe['id']),
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
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl.isNotEmpty
                                        ? imageUrl
                                        : 'https://via.placeholder.com/150', // Fallback image
                                    height: 130,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Image.asset(
                                      'assets/images/placeholder.png',
                                      height: 130,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          recipe['title'] ?? 'No Title',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              getCalories(recipe),
                                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.timer, size: 16, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              getCookingTime(recipe),
                                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
