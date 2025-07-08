import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_list.dart';

class ShoppingListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ShoppingListRecipe> _recipes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ShoppingListRecipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load shopping list from Firestore
  Future<void> loadShoppingList() async {
    _setLoading(true);
    _clearError();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .get();
      _recipes = snapshot.docs
          .map((doc) => ShoppingListRecipe.fromJson(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load shopping list: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle item checked/unchecked
  Future<void> toggleItem(String recipeId, int itemIndex, bool done) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final recipeIndex = _recipes.indexWhere((r) => r.recipeId == recipeId);
      if (recipeIndex == -1) return;
      final recipe = _recipes[recipeIndex];
      final updatedIngredients = List<ShoppingListItem>.from(recipe.ingredients);
      updatedIngredients[itemIndex] = updatedIngredients[itemIndex].copyWith(done: done);
      final updatedRecipe = recipe.copyWith(ingredients: updatedIngredients);
      _recipes[recipeIndex] = updatedRecipe;
      notifyListeners();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .doc(recipeId)
          .update({'ingredients': updatedIngredients.map((e) => e.toJson()).toList()});
    } catch (e) {
      _setError('Failed to update item: $e');
    }
  }

  // Remove recipe from shopping list
  Future<void> removeRecipe(String recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _recipes.removeWhere((r) => r.recipeId == recipeId);
      notifyListeners();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .doc(recipeId)
          .delete();
    } catch (e) {
      _setError('Failed to remove recipe: $e');
    }
  }

  // Add or update a recipe in the shopping list
  Future<void> addOrUpdateRecipe(ShoppingListRecipe recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final index = _recipes.indexWhere((r) => r.recipeId == recipe.recipeId);
      if (index == -1) {
        _recipes.add(recipe);
      } else {
        _recipes[index] = recipe;
      }
      notifyListeners();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .doc(recipe.recipeId)
          .set(recipe.toJson());
    } catch (e) {
      _setError('Failed to add/update recipe: $e');
    }
  }

  // Listen to real-time updates
  void listenToShoppingList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .snapshots()
        .listen((snapshot) {
      _recipes = snapshot.docs
          .map((doc) => ShoppingListRecipe.fromJson(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  // Helpers
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