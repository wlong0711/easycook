import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';
import '../services/ingredient_recognition_service.dart';

class PantryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<PantryItem> _ingredients = [];
  Set<String> _selectedIngredients = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PantryItem> get ingredients => _ingredients;
  Set<String> get selectedIngredients => _selectedIngredients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load pantry from Firestore
  Future<void> loadPantry() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('pantries')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['ingredients'] is List) {
          final ingredientsList = List<String>.from(data['ingredients']);
          _ingredients = ingredientsList.map((name) => PantryItem(name: name)).toList();
        }
      }
    } catch (e) {
      _setError('Failed to load pantry: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add ingredient to pantry
  Future<void> addIngredient(String ingredient) async {
    if (ingredient.trim().isEmpty || _ingredients.any((item) => item.name == ingredient.trim())) {
      return;
    }

    try {
      final newItem = PantryItem(name: ingredient.trim());
      _ingredients.add(newItem);
      await _savePantry();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add ingredient: $e');
    }
  }

  // Remove ingredient from pantry
  Future<void> removeIngredient(String ingredient) async {
    try {
      _ingredients.removeWhere((item) => item.name == ingredient);
      _selectedIngredients.remove(ingredient);
      await _savePantry();
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove ingredient: $e');
    }
  }

  // Toggle ingredient selection
  void toggleSelection(String ingredient, bool? selected) {
    if (selected == true) {
      _selectedIngredients.add(ingredient);
    } else {
      _selectedIngredients.remove(ingredient);
    }
    notifyListeners();
  }

  // Add multiple ingredients (from scan)
  Future<void> addIngredients(List<String> newIngredients) async {
    try {
      final uniqueIngredients = newIngredients.where((item) => 
        !_ingredients.any((existing) => existing.name == item)
      ).toList();
      
      if (uniqueIngredients.isNotEmpty) {
        _ingredients.addAll(uniqueIngredients.map((name) => PantryItem(name: name)));
        await _savePantry();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add ingredients: $e');
    }
  }

  // Scan ingredients from image
  Future<List<String>> scanIngredientsFromImage(dynamic imageFile) async {
    _setLoading(true);
    _clearError();
    
    try {
      final results = await IngredientRecognitionService.recognizeIngredientsFromImage(imageFile);
      return results;
    } catch (e) {
      _setError('Failed to scan ingredients: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Get selected ingredients as comma-separated string
  String get selectedIngredientsString => _selectedIngredients.join(',');

  // Check if any ingredients are selected
  bool get hasSelectedIngredients => _selectedIngredients.isNotEmpty;

  // Save pantry to Firestore
  Future<void> _savePantry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ingredientsList = _ingredients.map((item) => item.name).toList();
      await _firestore
          .collection('pantries')
          .doc(user.uid)
          .set({'ingredients': ingredientsList});
    } catch (e) {
      _setError('Failed to save pantry: $e');
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