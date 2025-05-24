import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_shopping_detail_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Not logged in")));
    }

    final shoppingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList');

    return Scaffold(
      appBar: AppBar(
        title: Text("Shopping List"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: shoppingRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text("No recipes with missing ingredients."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final recipeId = doc.id;
              final title = data['name'] ?? 'Unnamed';
              final image = data['image'] ?? '';
              final ingredientsRaw = data['ingredients'] ?? [];

              // Ensure the ingredients are List<Map<String, dynamic>>
              final ingredients = List<Map<String, dynamic>>.from(ingredientsRaw);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(image, width: 60, height: 60, fit: BoxFit.cover),
                        )
                      : Icon(Icons.image, size: 60),
                  title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("${ingredients.length} missing item(s)"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeShoppingDetailScreen(
                          recipeId: recipeId,
                          title: title,
                          ingredients: ingredients,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
