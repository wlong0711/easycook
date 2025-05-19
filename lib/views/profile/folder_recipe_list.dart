import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../recipe_details_screen.dart';

class FolderRecipeList extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderRecipeList({
    required this.folderId,
    required this.folderName,
    super.key,
  });

  @override
  State<FolderRecipeList> createState() => _FolderRecipeListState();
}

class _FolderRecipeListState extends State<FolderRecipeList> {
  final user = FirebaseAuth.instance.currentUser;

  CollectionReference get recipeRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('recipeFolders')
      .doc(widget.folderId)
      .collection('recipes');

  Future<void> _removeRecipe(String recipeId) async {
    await recipeRef.doc(recipeId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recipe removed from folder")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: recipeRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final recipes = snapshot.data!.docs;
          if (recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No recipes in this folder.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final doc = recipes[index];
              final data = doc.data() as Map<String, dynamic>;
              final recipeId = data['id'].toString();

              return Dismissible(
                key: Key(recipeId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Remove Recipe"),
                      content: Text("Remove this recipe from the folder?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Remove")),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => _removeRecipe(recipeId),
                child: Card(
                  margin: EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: data['image'] != null
                          ? Image.network(data['image'], width: 60, height: 60, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 50),
                    ),
                    title: Text(
                      data['title'] ?? 'No Title',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailsScreen(recipeId: int.parse(recipeId)),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
