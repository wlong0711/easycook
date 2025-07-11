import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/shopping_list_viewmodel.dart';
import '../../models/shopping_list.dart';

class RecipeShoppingDetailScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final List<Map<String, dynamic>> ingredients;

  const RecipeShoppingDetailScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.ingredients,
  });

  @override
  State<RecipeShoppingDetailScreen> createState() => _RecipeShoppingDetailScreenState();
}

class _RecipeShoppingDetailScreenState extends State<RecipeShoppingDetailScreen> {
  late List<ShoppingListItem> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = widget.ingredients.map((e) => ShoppingListItem.fromJson(e)).toList();
  }

  void _toggleCheck(int index, bool? value) {
    final viewModel = Provider.of<ShoppingListViewModel>(context, listen: false);
    viewModel.toggleItem(widget.recipeId, index, value ?? false);
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(done: value ?? false);
    });
  }

  void _deleteRecipeEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Remove Recipe"),
        content: Text("Delete all ingredients for this recipe from your shopping list?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Provider.of<ShoppingListViewModel>(context, listen: false).removeRecipe(widget.recipeId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: "Remove Recipe",
            onPressed: _deleteRecipeEntry,
          )
        ],
      ),
      body: _ingredients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No ingredients listed.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final item = _ingredients[index];
                final name = item.name;
                final done = item.done;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? Colors.grey : Colors.black87,
                      ),
                    ),
                    value: done,
                    onChanged: (val) => _toggleCheck(index, val),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.orange,
                  ),
                );
              },
            ),
    );
  }
}
