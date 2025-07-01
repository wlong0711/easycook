import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class m_RecipeDetailsScreen extends StatefulWidget {
  final String recipeId; // Recipe ID passed from the results screen

  const m_RecipeDetailsScreen({super.key, required this.recipeId});

  @override
  _m_RecipeDetailsScreenState createState() => _m_RecipeDetailsScreenState();
}

class _m_RecipeDetailsScreenState extends State<m_RecipeDetailsScreen> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('M_recipes')
          .doc(widget.recipeId)
          .get();

      if (!mounted) return;

      if (docSnapshot.exists) {
        setState(() {
          recipe = docSnapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Recipe not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching recipe details: $e';
        isLoading = false;
      });
    }
  }

  String getCuisines() {
    final cuisines = recipe?['cuisine'];
    return cuisines ?? 'Not specified';
  }

  String getDiets() {
    final diets = recipe?['diets'];
    return diets != null && diets.isNotEmpty ? diets.join(', ') : "Not specified";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text(recipe?['title'] ?? 'Recipe Details'),
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: recipe == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "mealplan",
                  onPressed: () {},
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.calendar_month),
                  tooltip: "Add to Meal Plan",
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "shopping",
                  onPressed: () {},
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.shopping_cart),
                  tooltip: "Add missing ingredients to Shopping List",
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "favorite",
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  tooltip: 'Save to Folders',
                ),
              ],
            ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipe == null || recipe!.isEmpty
              ? Center(child: Text('Failed to load recipe'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              (recipe?['imageUrl'] ?? 'https://via.placeholder.com/300')
                                  .replaceAll(RegExp(r'\.+\$'), ''),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/placeholder.png'),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black54],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text(
                                recipe?['title'] ?? 'No Title Available',
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Chips for Cuisines and Diets
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(getCuisines()),
                            avatar: const Icon(Icons.restaurant_menu, size: 18, color: Colors.orange),
                            backgroundColor: Colors.orange.shade50,
                            labelStyle: const TextStyle(color: Colors.orange),
                          ),
                          Chip(
                            label: Text(getDiets()),
                            avatar: const Icon(Icons.eco, size: 18, color: Colors.green),
                            backgroundColor: Colors.green.shade50,
                            labelStyle: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description Section
                      Row(
                        children: const [
                          Icon(Icons.description, color: Colors.deepOrange),
                          SizedBox(width: 8),
                          Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (recipe?['description'] ?? 'No description available.'),
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      // Ingredients Section
                      Row(
                        children: const [
                          Icon(Icons.kitchen, color: Colors.teal),
                          SizedBox(width: 8),
                          Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.from(
                        (recipe?['ingredients'] ?? []).map<Widget>((ingredient) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    ingredient ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Instructions Section
                      Row(
                        children: const [
                          Icon(Icons.list_alt, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (recipe?['instructions'] != null)
                        ...List.generate(
                          recipe!['instructions'].length,
                          (index) {
                            final step = recipe!['instructions'][index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    radius: 14,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(fontSize: 15, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else
                        const Text("No instructions available."),
                    ],
                  ),
                ),
    );
  }
}
