import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  RecipeDetailsScreen({required this.recipeId});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;
  bool isFavorited = false;

  final String apiKey = '52a3569d728c4360aeec59f495f43626';

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
    checkIfFavorited();
  }

  Future<void> fetchRecipeDetails() async {
    try {
      final url = 'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!mounted) return; // ✅ Prevent calling setState after dispose
        setState(() {
          recipe = data;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          recipe = {};
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = {};
        isLoading = false;
      });
    }
  }


  Future<void> checkIfFavorited() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipeId.toString())
        .get();

    setState(() {
      isFavorited = doc.exists;
    });
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || recipe == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipeId.toString());

    try {
      if (isFavorited) {
        await docRef.delete();
        setState(() {
          isFavorited = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        await docRef.set({
          'id': recipe!['id'],
          'title': recipe!['title'],
          'image': recipe!['image'],
        });
        setState(() {
          isFavorited = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites')),
        );
      }
    } catch (e) {
      print("Favorite error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe?['title'] ?? 'Recipe Details')),
      floatingActionButton: recipe == null
          ? null
          : FloatingActionButton(
              onPressed: toggleFavorite,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.favorite,
                color: isFavorited ? Colors.red : Colors.grey[400],
              ),
              tooltip: isFavorited ? 'Remove from Favorites' : 'Add to Favorites',
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
                      Image.network(
                        (recipe?['image'] ?? 'https://via.placeholder.com/300').replaceAll(RegExp(r'\.+\$'), ''),
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/images/placeholder.png'),
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
