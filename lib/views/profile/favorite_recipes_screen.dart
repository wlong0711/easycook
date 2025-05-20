import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../profile/folder_recipe_list.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late CollectionReference folderRef;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      folderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipeFolders');

      _ensureUncategorizedFolderExists();
    }
  }

  Future<void> _ensureUncategorizedFolderExists() async {
    final doc = await folderRef.doc("uncategorized").get();
    if (!doc.exists) {
      await folderRef.doc("uncategorized").set({
        'name': 'Uncategorized',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createFolder() async {
    final TextEditingController _folderNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("New Folder"),
        content: TextField(
          controller: _folderNameController,
          decoration: InputDecoration(hintText: "Enter folder name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              final name = _folderNameController.text.trim();
              if (name.isNotEmpty) {
                await folderRef.add({
                  'name': name,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              Navigator.pop(ctx);
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFolder(String folderId, String currentName) async {
    if (folderId == "uncategorized") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You cannot rename the default folder.")),
      );
      return;
    }
    final controller = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Rename Folder"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Folder name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              await folderRef.doc(folderId).update({'name': controller.text});
              Navigator.pop(ctx);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(String folderId) async {
    if (folderId == "uncategorized") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You cannot delete the default folder.")),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Folder"),
        content: Text("Are you sure you want to delete this folder and all recipes inside it?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      final folder = folderRef.doc(folderId);
      final recipes = await folder.collection('recipes').get();
      for (var doc in recipes.docs) {
        await doc.reference.delete();
      }
      await folder.delete();
    }
  }

  void _openFolder(String folderId, String folderName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FolderRecipeList(folderId: folderId, folderName: folderName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Recipe Collections"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createFolder,
            tooltip: "New Folder",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: folderRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final allFolders = snapshot.data!.docs;

          final List<QueryDocumentSnapshot> folders = [];
          final uncategorized = allFolders.where((doc) => doc.id == "uncategorized").toList();
          final others = allFolders.where((doc) => doc.id != "uncategorized").toList();

          folders.addAll(uncategorized); // Always at top
          folders.addAll(others);        // Then the rest

          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No recipe folders created yet.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final doc = folders[index];
              final data = doc.data() as Map<String, dynamic>;

              final isUncategorized = doc.id == "uncategorized";

              return Card(
                color: isUncategorized ? Colors.orange[50] : null,
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  leading: Icon(
                    isUncategorized ? Icons.folder_special : Icons.folder,
                    color: isUncategorized ? Colors.deepOrange : Colors.orange,
                    size: 32,
                  ),
                  title: Text(
                    data['name'] ?? 'Untitled Folder',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isUncategorized ? Colors.deepOrange : null,
                    ),
                  ),
                  trailing: isUncategorized
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'rename') _renameFolder(doc.id, data['name']);
                            if (val == 'delete') _deleteFolder(doc.id);
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'rename', child: Text("Rename")),
                            PopupMenuItem(value: 'delete', child: Text("Delete")),
                          ],
                        ),
                  onTap: () => _openFolder(doc.id, data['name']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
