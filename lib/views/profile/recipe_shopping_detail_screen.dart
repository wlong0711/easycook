import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late List<Map<String, dynamic>> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List<Map<String, dynamic>>.from(widget.ingredients);
  }

  Future<void> _toggleCheck(int index, bool? value) async {
    setState(() {
      _ingredients[index]['done'] = value ?? false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .doc(widget.recipeId)
        .update({'ingredients': _ingredients});
  }

  Future<void> _deleteRecipeEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .doc(widget.recipeId)
        .delete();

    if (mounted) Navigator.pop(context);
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
            onPressed: () async {
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

              if (confirmed == true) await _deleteRecipeEntry();
            },
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
                final name = item['name'] ?? '';
                final done = item['done'] ?? false;

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
