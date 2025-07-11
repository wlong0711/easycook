import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile/folder_recipe_list.dart';
import '../../viewmodels/favorite_recipes_viewmodel.dart';

class FavoriteRecipesScreen extends StatefulWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  State<FavoriteRecipesScreen> createState() => _FavoriteRecipesScreenState();
}

class _FavoriteRecipesScreenState extends State<FavoriteRecipesScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the ViewModel when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteRecipesViewModel>(context, listen: false).initialize();
    });
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
                await Provider.of<FavoriteRecipesViewModel>(context, listen: false)
                    .createFolder(name);
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
              await Provider.of<FavoriteRecipesViewModel>(context, listen: false)
                  .renameFolder(folderId, controller.text);
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
      await Provider.of<FavoriteRecipesViewModel>(context, listen: false)
          .deleteFolder(folderId);
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
    return Consumer<FavoriteRecipesViewModel>(
      builder: (context, favoriteRecipesViewModel, child) {
        return Scaffold(
          backgroundColor: Colors.orange[50],
          appBar: AppBar(
            title: Text("My Recipe Collections"),
            centerTitle: true,
            backgroundColor: Colors.orange,
            actions: [
              IconButton(
                icon: Icon(Icons.create_new_folder_rounded),
                tooltip: "Create New Folder",
                onPressed: _createFolder,
              ),
            ],
          ),
          body: favoriteRecipesViewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : favoriteRecipesViewModel.folders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("No folders yet.",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteRecipesViewModel.folders.length,
                      itemBuilder: (context, index) {
                        final folder = favoriteRecipesViewModel.folders[index];
                        final isUncategorized = folder.isUncategorized;

                        return InkWell(
                          onTap: () => _openFolder(folder.id, folder.name),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            margin: EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isUncategorized ? Icons.folder_special_rounded : Icons.folder_rounded,
                                  color: isUncategorized ? Colors.deepOrange : Colors.orange,
                                  size: 34,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    folder.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isUncategorized ? Colors.deepOrange : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (!isUncategorized)
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 20),
                                    onSelected: (val) {
                                      if (val == 'rename') _renameFolder(folder.id, folder.name);
                                      if (val == 'delete') _deleteFolder(folder.id);
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(value: 'rename', child: Text("Rename")),
                                      PopupMenuItem(value: 'delete', child: Text("Delete")),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
