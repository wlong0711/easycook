import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipe_results_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPantryScreen extends StatefulWidget {
  const MyPantryScreen({super.key});

  @override
  State<MyPantryScreen> createState() => _MyPantryScreenState();
}

class _MyPantryScreenState extends State<MyPantryScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _ingredients = [];
  final Set<String> _selectedIngredients = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPantry();
  }

  void _addIngredient(String ingredient) async {
    if (ingredient.trim().isEmpty || _ingredients.contains(ingredient.trim())) return;
    setState(() {
      _ingredients.add(ingredient.trim());
      _controller.clear();
    });
    await _savePantry();
  }

  void _removeIngredient(String ingredient) async {
    setState(() {
      _ingredients.remove(ingredient);
      _selectedIngredients.remove(ingredient);
    });
    await _savePantry();
  }

  void _toggleSelection(String ingredient, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIngredients.add(ingredient);
      } else {
        _selectedIngredients.remove(ingredient);
      }
    });
  }

  Future<void> _savePantry() async {
    await _firestore.collection('pantries').doc(FirebaseAuth.instance.currentUser!.uid).set({
      'ingredients': _ingredients,
    });
  }

  Future<void> _loadPantry() async {
    final doc = await _firestore.collection('pantries').doc(FirebaseAuth.instance.currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['ingredients'] is List) {
        setState(() {
          _ingredients.addAll(List<String>.from(data['ingredients']));
        });
      }
    }
  }

  void _exploreRecipes() {
    final selectedList = _selectedIngredients.toList();
    if (selectedList.isNotEmpty) {
      final ingredientsParam = selectedList.join(',');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeResultsScreen(ingredients: ingredientsParam),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Ingredients", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 6),
            Center(
              child: Text("Explore Recipes with Available Ingredients",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ),
            SizedBox(height: 20),

            // Add ingredient field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Add Your Ingredients Here",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: _addIngredient,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {}, // Camera scan feature placeholder
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.black),
                )
              ],
            ),
            SizedBox(height: 20),

            // Ingredient checklist
            if (_ingredients.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What's in my pantry", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ..._ingredients.map((ingredient) => Row(
                          children: [
                            Checkbox(
                              value: _selectedIngredients.contains(ingredient),
                              onChanged: (val) => _toggleSelection(ingredient, val),
                            ),
                            Expanded(child: Text(ingredient)),
                            IconButton(
                              icon: Icon(Icons.delete, size: 18),
                              onPressed: () => _removeIngredient(ingredient),
                            )
                          ],
                        ))
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],

            // Explore Recipes button
            Center(
              child: ElevatedButton(
                onPressed: _exploreRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: Text("Explore Recipes", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
