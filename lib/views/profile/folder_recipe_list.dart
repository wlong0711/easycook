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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: Column(
          children: [
            Text(widget.folderName, style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: recipeRef.snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Text(
                  "$count recipe${count == 1 ? '' : 's'}",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                );
              },
            ),
          ],
        ),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                child: Container(
                  margin: EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(14),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: data['image'] != null
                          ? Image.network(
                              data['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 40),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, size: 40),
                            ),
                    ),
                    title: Text(
                      data['title'] ?? 'No Title',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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
