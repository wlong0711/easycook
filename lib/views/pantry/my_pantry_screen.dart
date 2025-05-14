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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("My Pantry"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text("What's in your pantry?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("Select ingredients to explore matching recipes",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Add Ingredient Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Add ingredients (e.g. onion, egg)",
                      prefixIcon: Icon(Icons.food_bank_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    onSubmitted: _addIngredient,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {}, // Placeholder for camera scan
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                    backgroundColor: Colors.white,
                    elevation: 2,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.orange),
                )
              ],
            ),

            SizedBox(height: 25),

            // Ingredient Checklist
            if (_ingredients.isNotEmpty) ...[
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: ListView(
                    children: [
                      Text("Your Ingredients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Divider(),
                      ..._ingredients.map((ingredient) => CheckboxListTile(
                            value: _selectedIngredients.contains(ingredient),
                            onChanged: (val) => _toggleSelection(ingredient, val),
                            title: Text(ingredient),
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeIngredient(ingredient),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Explore Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _exploreRecipes,
                icon: Icon(Icons.restaurant_menu_outlined),
                label: Text("Explore Recipes", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
