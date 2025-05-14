import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../recipe_details_screen.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late CollectionReference favoritesRef;

  @override
  void initState() {
    super.initState();
    favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites');
  }

  Future<void> _removeFavorite(String recipeId) async {
    await favoritesRef.doc(recipeId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recipe removed from favorites")),
    );
  }

  Future<void> _refreshFavorites() async {
    setState(() {}); // triggers rebuild
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("My Recipe Collection"),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: StreamBuilder<QuerySnapshot>(
          stream: favoritesRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            final favorites = snapshot.data!.docs;
            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("No favorites added yet.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final doc = favorites[index];
                final data = doc.data() as Map<String, dynamic>;
                final recipeId = data['id'].toString();

                return Dismissible(
                  key: Key(recipeId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("Remove Recipe"),
                        content: Text("Are you sure you want to remove this recipe from your favorites?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Remove")),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _removeFavorite(recipeId),
                  child: Card(
                    margin: EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
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
      ),
    );
  }
}
