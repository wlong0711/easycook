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
        .update({
      'ingredients': _ingredients,
    });
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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Remove Recipe"),
                  content: Text("Delete all ingredients for this recipe from your shopping list?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                  ],
                ),
              );

              if (confirmed == true) {
                await _deleteRecipeEntry();
              }
            },
          )
        ],
      ),
      body: _ingredients.isEmpty
          ? Center(child: Text("No ingredients listed for this recipe."))
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _ingredients.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final item = _ingredients[index];
                final name = item['name'] ?? '';
                final done = item['done'] ?? false;

                return CheckboxListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? Colors.grey : null,
                    ),
                  ),
                  value: done,
                  onChanged: (val) => _toggleCheck(index, val),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
    );
  }
}
