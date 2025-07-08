import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/recipe_viewmodel.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  RecipeDetailsScreen({required this.recipeId});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load recipe details when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeViewModel>(context, listen: false).fetchRecipeDetails(widget.recipeId);
    });
  }

  Future<void> _showFolderSelectorDialog() async {
    final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
    final sortedFolders = recipeViewModel.getSortedFoldersWithUncategorizedFirst();
    final Set<String> tempSelectedFolders = Set<String>.from(recipeViewModel.savedFolderIds);
    if (!tempSelectedFolders.contains('uncategorized')) {
      tempSelectedFolders.add('uncategorized');
    }
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Folders to Save Recipe'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: sortedFolders.map((folder) {
                    final folderId = folder['id'];
                    final folderName = folder['name'];
                    return CheckboxListTile(
                      title: Text(folderName),
                      value: tempSelectedFolders.contains(folderId),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelectedFolders.add(folderId);
                          } else {
                            tempSelectedFolders.remove(folderId);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, tempSelectedFolders), child: Text('Save')),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      await recipeViewModel.saveRecipeToFolders(result, widget.recipeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${result.length} folder(s)')),
      );
    }
  }

  Future<void> addMissingIngredientsToShoppingList() async {
    final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
    final ingredientsData = await recipeViewModel.getAvailableAndMissingIngredients();
    final available = ingredientsData['available'] ?? [];
    final missing = ingredientsData['missing'] ?? [];
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All ingredients are already in your pantry.")),
      );
      return;
    }
    Set<String> selected = Set.from(missing); // All checked by default
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Add Missing Ingredients"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("✅ Available in Pantry:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...available.map((e) => Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 4),
                        child: Text("- $e", style: TextStyle(color: Colors.grey[700])),
                      )),
                  SizedBox(height: 12),
                  Text("🛒 Missing Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...missing.map((item) {
                    return CheckboxListTile(
                      title: Text(item),
                      value: selected.contains(item),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(item);
                          } else {
                            selected.remove(item);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selected),
                child: Text("Add to Shopping List"),
              ),
            ],
          );
        });
      },
    ).then((selectedSet) async {
      if (selectedSet == null || selectedSet.isEmpty) return;
      await recipeViewModel.addMissingIngredientsToShoppingList(selectedSet.toList(), widget.recipeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${selectedSet.length} item(s) added to shopping list.")),
      );
    });
  }

  Future<void> addToMealPlan() async {
    final recipeViewModel = Provider.of<RecipeViewModel>(context, listen: false);
    DateTime selectedDate = DateTime.now();
    String selectedMeal = 'breakfast';
    List<String> mealTypes = ['breakfast', 'lunch', 'dinner'];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add to Meal Plan"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Select Date"),
                    subtitle: Text("${selectedDate.toLocal()}".split(' ')[0]),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedMeal,
                    onChanged: (value) => setState(() => selectedMeal = value!),
                    items: mealTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type.capitalize())))
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true) {
      await recipeViewModel.addToMealPlan(selectedDate, selectedMeal, widget.recipeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added to $selectedMeal on ${DateFormat('MMM d').format(selectedDate)}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeViewModel>(
      builder: (context, recipeViewModel, child) {
        final recipe = recipeViewModel.currentRecipe;
        
        return Scaffold(
          backgroundColor: Colors.orange[50],
          appBar: AppBar(
            title: Text(recipe?.title ?? 'Recipe Details'),
            backgroundColor: Colors.orange,
          ),
          floatingActionButton: recipe == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "mealplan",
                      onPressed: addToMealPlan,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.calendar_month),
                      tooltip: "Add to Meal Plan",
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: "shopping",
                      onPressed: addMissingIngredientsToShoppingList,
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.shopping_cart),
                      tooltip: "Add missing ingredients to Shopping List",
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: "favorite",
                      onPressed: _showFolderSelectorDialog,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.favorite,
                        color: recipeViewModel.savedFolderIds.isNotEmpty ? Colors.red : Colors.grey[400],
                      ),
                      tooltip: recipeViewModel.savedFolderIds.isNotEmpty ? 'Manage Saved Folders' : 'Save to Folders',
                    ),
                  ],
                ),
          body: recipeViewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : recipe == null
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
                                  (recipe.image ?? 'https://via.placeholder.com/300')
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
                                    recipe.title,
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

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(recipe.cuisinesString),
                                avatar: const Icon(Icons.restaurant_menu, size: 18, color: Colors.orange),
                                backgroundColor: Colors.orange.shade50,
                                labelStyle: const TextStyle(color: Colors.orange),
                              ),
                              Chip(
                                label: Text(recipe.dietsString),
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
                            (recipe.summary ?? 'No description available.')
                                .replaceAll(RegExp(r'<[^>]*>'), ''),
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
                            recipe.extendedIngredients.map<Widget>((ingredient) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("• ", style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        ingredient['original'] ?? '',
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

                          if (recipe.instructions != null && recipe.instructions!.isNotEmpty)
                            Text(
                              recipe.instructions!,
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            )
                          else
                            const Text("No step-by-step instructions available."),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

extension CapitalizeExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
