import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe_folder.dart';

class FavoriteRecipesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<RecipeFolder> _folders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<RecipeFolder> get folders => _folders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize and ensure uncategorized folder exists
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _ensureUncategorizedFolderExists();
      await loadFolders();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all recipe folders
  Future<void> loadFolders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .orderBy('createdAt', descending: true)
          .snapshots();

      snapshot.listen((querySnapshot) {
        _folders = querySnapshot.docs.map((doc) {
          return RecipeFolder.fromJson(doc.data(), doc.id);
        }).toList();
        notifyListeners();
      });
    } catch (e) {
      _setError('Failed to load folders: $e');
    }
  }

  // Create new folder
  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .add({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _setError('Failed to create folder: $e');
    }
  }

  // Rename folder
  Future<void> renameFolder(String folderId, String newName) async {
    if (folderId == "uncategorized") {
      _setError("You cannot rename the default folder.");
      return;
    }

    if (newName.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId)
          .update({'name': newName.trim()});
    } catch (e) {
      _setError('Failed to rename folder: $e');
    }
  }

  // Delete folder and all recipes inside
  Future<void> deleteFolder(String folderId) async {
    if (folderId == "uncategorized") {
      _setError("You cannot delete the default folder.");
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final folderRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId);

      // Delete all recipes in the folder
      final recipes = await folderRef.collection('recipes').get();
      for (var doc in recipes.docs) {
        await doc.reference.delete();
      }

      // Delete the folder
      await folderRef.delete();
    } catch (e) {
      _setError('Failed to delete folder: $e');
    }
  }

  // Get recipes in a folder
  Future<List<Map<String, dynamic>>> getRecipesInFolder(String folderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId)
          .collection('recipes')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _setError('Failed to load recipes: $e');
      return [];
    }
  }

  // Remove recipe from folder
  Future<void> removeRecipeFromFolder(String folderId, String recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc(folderId)
          .collection('recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      _setError('Failed to remove recipe: $e');
    }
  }

  // Ensure uncategorized folder exists
  Future<void> _ensureUncategorizedFolderExists() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .doc("uncategorized")
          .get();

      if (!doc.exists) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('recipeFolders')
            .doc("uncategorized")
            .set({
          'name': 'Uncategorized',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _setError('Failed to ensure uncategorized folder: $e');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 