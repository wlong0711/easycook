import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../services/spoonacular_service.dart';

class RecipeViewModel extends ChangeNotifier {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Recipe? _currentRecipe;
  bool _isLoading = false;
  List<Map<String, dynamic>> _folders = [];
  Set<String> _savedFolderIds = {};
  String? _error;

  // Getters
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get folders => _folders;
  Set<String> get savedFolderIds => _savedFolderIds;
  String? get error => _error;

  // Fetch recipe details from API
  Future<void> fetchRecipeDetails(int recipeId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final data = await _spoonacularService.getRecipeDetails(recipeId);
      _currentRecipe = Recipe.fromJson(data);
      await fetchFoldersAndSavedStatus(recipeId);
    } catch (e) {
      _setError('Failed to load recipe details: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user's recipe folders and check if recipe is saved
  Future<void> fetchFoldersAndSavedStatus(int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipeFolders')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> fetchedFolders = [];
      final Set<String> foundFolderIds = {};

      for (var doc in snapshot.docs) {
        fetchedFolders.add({'id': doc.id, 'name': doc['name']});
      }

      for (var folder in fetchedFolders) {
        final recipeDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('recipeFolders')
            .doc(folder['id'])
            .collection('recipes')
            .doc(recipeId.toString())
            .get();

        if (recipeDoc.exists) {
          foundFolderIds.add(folder['id']);
        }
      }

      _folders = fetchedFolders;
      _savedFolderIds = foundFolderIds;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load folders: $e');
    }
  }

  // Update recipe folders (save/unsave)
  Future<void> updateRecipeFolders(Set<String> selectedFolders, int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentRecipe == null) return;

    try {
      final recipeIdStr = recipeId.toString();

      // Remove from unselected folders
      for (var folderId in _savedFolderIds.difference(selectedFolders)) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('recipeFolders')
            .doc(folderId)
            .collection('recipes')
            .doc(recipeIdStr)
            .delete();
      }

      // Add to newly selected folders
      for (var folderId in selectedFolders.difference(_savedFolderIds)) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('recipeFolders')
            .doc(folderId)
            .collection('recipes')
            .doc(recipeIdStr)
            .set({
          'id': _currentRecipe!.id,
          'title': _currentRecipe!.title,
          'image': _currentRecipe!.image,
        });
      }

      _savedFolderIds = selectedFolders;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update folders: $e');
    }
  }

  // Add missing ingredients to shopping list
  Future<Map<String, List<String>>> getMissingIngredients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentRecipe == null) {
      return {'available': [], 'missing': []};
    }

    try {
      final pantryDoc = await _firestore
          .collection('pantries')
          .doc(user.uid)
          .get();

      List pantryItems = pantryDoc.exists && pantryDoc.data()?['ingredients'] is List
          ? List<String>.from(pantryDoc.data()!['ingredients'])
          : [];

      final List<dynamic> recipeIngredients = _currentRecipe!.extendedIngredients;
      List<String> available = [];
      List<String> missing = [];

      for (var ingredient in recipeIngredients) {
        final name = ingredient['original'].toString().toLowerCase().trim();
        final keyword = name.split(" ").last;
        if (pantryItems.any((item) => item.toLowerCase().contains(keyword))) {
          available.add(name);
        } else {
          missing.add(name);
        }
      }

      return {'available': available, 'missing': missing};
    } catch (e) {
      _setError('Failed to check ingredients: $e');
      return {'available': [], 'missing': []};
    }
  }

  // Add ingredients to shopping list
  Future<void> addToShoppingList(List<String> ingredients, int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentRecipe == null || ingredients.isEmpty) return;

    try {
      final shoppingDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .doc(recipeId.toString());

      await shoppingDoc.set({
        'name': _currentRecipe!.title,
        'image': _currentRecipe!.image,
        'ingredients': ingredients.map((item) => {'name': item, 'done': false}).toList(),
      });
    } catch (e) {
      _setError('Failed to add to shopping list: $e');
    }
  }

  // Add recipe to meal plan
  Future<void> addToMealPlan(DateTime date, String mealType, int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentRecipe == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlans')
          .doc('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');

      final doc = await docRef.get();
      Map<String, dynamic> data = doc.exists ? doc.data()! : {};

      List existing = data[mealType] ?? [];
      existing.add({
        'id': _currentRecipe!.id,
        'title': _currentRecipe!.title,
        'image': _currentRecipe!.image,
      });

      await docRef.set({mealType: existing}, SetOptions(merge: true));
    } catch (e) {
      _setError('Failed to add to meal plan: $e');
    }
  }

  /// Returns folders with 'uncategorized' first, then others
  List<Map<String, dynamic>> getSortedFoldersWithUncategorizedFirst() {
    List<Map<String, dynamic>> sortedFolders = [];
    final uncategorizedIndex = _folders.indexWhere((f) => f['id'] == 'uncategorized');
    if (uncategorizedIndex != -1) {
      sortedFolders.add(_folders[uncategorizedIndex]);
    }
    sortedFolders.addAll(_folders.where((f) => f['id'] != 'uncategorized'));
    return sortedFolders;
  }

  /// Save recipe to selected folders
  Future<void> saveRecipeToFolders(Set<String> folderIds, int recipeId) async {
    await updateRecipeFolders(folderIds, recipeId);
  }

  /// Get available and missing ingredients for the current recipe
  Future<Map<String, List<String>>> getAvailableAndMissingIngredients() async {
    return await getMissingIngredients();
  }

  /// Add missing ingredients to shopping list
  Future<void> addMissingIngredientsToShoppingList(List<String> ingredients, int recipeId) async {
    await addToShoppingList(ingredients, recipeId);
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