import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/shopping_list_viewmodel.dart';
import 'recipe_shopping_detail_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to shopping list updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShoppingListViewModel>(context, listen: false).listenToShoppingList();
      Provider.of<ShoppingListViewModel>(context, listen: false).loadShoppingList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(
            backgroundColor: Colors.orange[50],
            appBar: AppBar(
              title: Text("Shopping List"),
              centerTitle: true,
              backgroundColor: Colors.orange,
              elevation: 3,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final recipes = viewModel.recipes;

        return Scaffold(
          backgroundColor: Colors.orange[50],
          appBar: AppBar(
            title: Text("Shopping List"),
            centerTitle: true,
            backgroundColor: Colors.orange,
            elevation: 3,
          ),
          body: recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("No recipes with missing ingredients.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: recipe.image.isNotEmpty
                              ? Image.network(
                                  recipe.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50),
                                )
                              : Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                        title: Text(recipe.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Row(
                          children: [
                            Icon(Icons.list_alt, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text("${recipe.ingredients.length} missing item${recipe.ingredients.length > 1 ? 's' : ''}",
                                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeShoppingDetailScreen(
                                recipeId: recipe.recipeId,
                                title: recipe.name,
                                ingredients: recipe.ingredients.map((e) => e.toJson()).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
