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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text("Shopping List"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 3,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: shoppingRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No recipes with missing ingredients.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final recipeId = doc.id;
              final title = data['name'] ?? 'Unnamed';
              final image = data['image'] ?? '';
              final ingredientsRaw = data['ingredients'] ?? [];

              final ingredients = List<Map<String, dynamic>>.from(ingredientsRaw);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50),
                          )
                        : Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                  title: Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Row(
                    children: [
                      Icon(Icons.list_alt, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text("${ingredients.length} missing item${ingredients.length > 1 ? 's' : ''}",
                          style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
