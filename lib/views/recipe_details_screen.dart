import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  RecipeDetailsScreen({required this.recipeId});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;

  // Folder list: each with id, name, and whether recipe is saved there
  List<Map<String, dynamic>> folders = [];
  Set<String> savedFolderIds = {};

  final String apiKey = '52a3569d728c4360aeec59f495f43626';

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
    fetchFoldersAndSavedStatus();
  }

  Future<void> fetchRecipeDetails() async {
    try {
      final url = 'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          recipe = data;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          recipe = {};
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = {};
        isLoading = false;
      });
    }
  }

  Future<void> fetchFoldersAndSavedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recipeFolders')
        .orderBy('createdAt', descending: true)
        .get();

    final List<Map<String, dynamic>> fetchedFolders = [];
    final Set<String> foundFolderIds = {};

    for (var doc in snapshot.docs) {
      fetchedFolders.add({
        'id': doc.id,
        'name': doc['name'],
      });
    }

    // For each folder, check if recipe exists inside
    for (var folder in fetchedFolders) {
      final recipeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folder['id'])
          .collection('recipes')
          .doc(widget.recipeId.toString())
          .get();

      if (recipeDoc.exists) {
        foundFolderIds.add(folder['id']);
      }
    }

    setState(() {
      folders = fetchedFolders;
      savedFolderIds = foundFolderIds;
    });
  }

  Future<void> _showFolderSelectorDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Sort folders: Uncategorized on top
    List<Map<String, dynamic>> sortedFolders = [];
    final uncategorizedIndex = folders.indexWhere((f) => f['id'] == 'uncategorized');
    if (uncategorizedIndex != -1) {
      sortedFolders.add(folders[uncategorizedIndex]);
    }
    sortedFolders.addAll(folders.where((f) => f['id'] != 'uncategorized'));

    // Ensure 'uncategorized' is ticked by default
    final Set<String> tempSelectedFolders = Set<String>.from(savedFolderIds);
    if (!tempSelectedFolders.contains('uncategorized')) {
      tempSelectedFolders.add('uncategorized');
    }

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Folders to Save Recipe'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: sortedFolders.map((folder) {
                    final folderId = folder['id'];
                    final folderName = folder['name'];
                    return CheckboxListTile(
                      title: Text(folderName),
                        value: tempSelectedFolders.contains(folderId),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              tempSelectedFolders.add(folderId);
                            } else {
                              tempSelectedFolders.remove(folderId);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, tempSelectedFolders), child: Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _updateRecipeFolders(result);
    }
  }

  Future<void> _updateRecipeFolders(Set<String> selectedFolders) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || recipe == null) return;

    final recipeId = widget.recipeId.toString();

    // Remove from folders that were unselected
    for (var folderId in savedFolderIds.difference(selectedFolders)) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId)
          .collection('recipes')
          .doc(recipeId)
          .delete();
    }

    // Add to newly selected folders
    for (var folderId in selectedFolders.difference(savedFolderIds)) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId)
          .collection('recipes')
          .doc(recipeId)
          .set({
        'id': recipe!['id'],
        'title': recipe!['title'],
        'image': recipe!['image'],
      });
    }

    // Update local state
    setState(() {
      savedFolderIds = selectedFolders;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to ${selectedFolders.length} folder(s)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?['title'] ?? 'Recipe Details'),
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: recipe == null
          ? null
          : FloatingActionButton(
              onPressed: _showFolderSelectorDialog,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.favorite,
                color: savedFolderIds.isNotEmpty ? Colors.red : Colors.grey[400],
              ),
              tooltip: savedFolderIds.isNotEmpty ? 'Manage Saved Folders' : 'Save to Folders',
            ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : recipe == null || recipe!.isEmpty
              ? Center(child: Text('Failed to load recipe'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        (recipe?['image'] ?? 'https://via.placeholder.com/300')
                            .replaceAll(RegExp(r'\.+\$'), ''),
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/images/placeholder.png'),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 16),
                      Text(
                        recipe?['title'] ?? 'No Title Available',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                        (recipe?['summary'] ?? 'No description available.')
                            .replaceAll(RegExp(r'<[^>]*>'), ''),
                      ),
                      SizedBox(height: 16),
                      Text("Ingredients", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...?recipe?['extendedIngredients']?.map<Widget>((ingredient) {
                        return Text("- ${ingredient['original']}");
                      }).toList(),
                      SizedBox(height: 16),
                      Text("Instructions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      if (recipe?['analyzedInstructions'] != null &&
                          recipe!['analyzedInstructions'].isNotEmpty) ...[
                        ...List.generate(
                          recipe!['analyzedInstructions'][0]['steps'].length,
                          (index) {
                            final step = recipe!['analyzedInstructions'][0]['steps'][index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('${step['number']}. ${step['step']}'),
                            );
                          },
                        )
                      ] else ...[
                        Text("No step-by-step instructions available."),
                      ],
                    ],
                  ),
                ),
    );
  }
}
