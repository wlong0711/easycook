import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../recipe_results_screen.dart';
import 'ingredient_scan_screen.dart';
import '../../viewmodels/pantry_viewmodel.dart';

class MyPantryScreen extends StatefulWidget {
  const MyPantryScreen({super.key});

  @override
  State<MyPantryScreen> createState() => _MyPantryScreenState();
}

class _MyPantryScreenState extends State<MyPantryScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load pantry data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PantryViewModel>(context, listen: false).loadPantry();
    });
  }

  void _addIngredient(String ingredient) {
    Provider.of<PantryViewModel>(context, listen: false).addIngredient(ingredient);
    _controller.clear();
  }

  void _removeIngredient(String ingredient) {
    Provider.of<PantryViewModel>(context, listen: false).removeIngredient(ingredient);
  }

  void _toggleSelection(String ingredient, bool? selected) {
    Provider.of<PantryViewModel>(context, listen: false).toggleSelection(ingredient, selected);
  }

  void _exploreRecipes() {
    final pantryViewModel = Provider.of<PantryViewModel>(context, listen: false);
    if (pantryViewModel.hasSelectedIngredients) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeResultsScreen(ingredients: pantryViewModel.selectedIngredientsString),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PantryViewModel>(
      builder: (context, pantryViewModel, child) {
        return Scaffold(
          backgroundColor: Colors.orange[50],
          appBar: AppBar(
            title: const Text("My Pantry"),
            backgroundColor: Colors.orange,
            centerTitle: true,
          ),
          body: pantryViewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Text("What's in your pantry?",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("Select ingredients to explore matching recipes",
                                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Add Ingredient Field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Add ingredients (e.g. onion, egg)",
                                prefixIcon: const Icon(Icons.food_bank_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              ),
                              onSubmitted: _addIngredient,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const IngredientScanScreen()),
                              );

                              if (result is List<String>) {
                                pantryViewModel.addIngredients(result);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              backgroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.orange),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Ingredient Checklist
                      if (pantryViewModel.ingredients.isNotEmpty) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView(
                              children: [
                                const Text("Your Ingredients",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Divider(),
                                ...pantryViewModel.ingredients.map((ingredient) => CheckboxListTile(
                                      value: pantryViewModel.selectedIngredients.contains(ingredient.name),
                                      onChanged: (val) => _toggleSelection(ingredient.name, val),
                                      title: Text(ingredient.name),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      secondary: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _removeIngredient(ingredient.name),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Explore Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _exploreRecipes,
                            icon: const Icon(Icons.restaurant_menu_outlined),
                            label: const Text("Explore Recipes", style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Empty state
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.kitchen, size: 60, color: Colors.grey),
                                SizedBox(height: 12),
                                Text("Your pantry is empty",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                SizedBox(height: 8),
                                Text("Add some ingredients to get started",
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
