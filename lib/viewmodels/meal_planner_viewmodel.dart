import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealPlannerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isWeekly = true;
  Map<String, Map<String, List<Map<String, dynamic>>>> _mealPlans = {};
  Map<String, Set<String>> _expandedMeals = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isWeekly => _isWeekly;
  Map<String, Map<String, List<Map<String, dynamic>>>> get mealPlans => _mealPlans;
  Map<String, Set<String>> get expandedMeals => _expandedMeals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime get startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  String get formattedWeekRange {
    final formatter = DateFormat('MMMM d');
    return "${formatter.format(startOfWeek)} - ${formatter.format(startOfWeek.add(Duration(days: 6)))}";
  }

  // Toggle between weekly and daily view
  void toggleView() {
    _isWeekly = !_isWeekly;
    loadMealPlans();
  }

  // Load meal plans
  Future<void> loadMealPlans() async {
    _setLoading(true);
    _clearError();
    
    try {
      Map<String, Map<String, List<Map<String, dynamic>>>> newPlans = {};
      
      if (_isWeekly) {
        for (int i = 0; i < 7; i++) {
          final dateStr = _formatDate(startOfWeek.add(Duration(days: i)));
          newPlans[dateStr] = await _fetchMealPlanForDate(dateStr);
        }
      } else {
        final todayStr = _formatDate(DateTime.now());
        newPlans[todayStr] = await _fetchMealPlanForDate(todayStr);
      }
      
      _mealPlans = newPlans;
      _expandedMeals = {};
      notifyListeners();
    } catch (e) {
      _setError('Failed to load meal plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle meal expansion
  void toggleMealExpansion(String date, String meal) {
    _expandedMeals[date] ??= {};
    if (_expandedMeals[date]!.contains(meal)) {
      _expandedMeals[date]!.remove(meal);
    } else {
      _expandedMeals[date]!.add(meal);
    }
    notifyListeners();
  }

  // Remove meal from plan
  Future<void> removeMeal(String date, String meal, int recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlans')
          .doc(date);

      final doc = await docRef.get();
      if (!doc.exists) return;

      List existing = doc.data()?[meal] ?? [];
      existing.removeWhere((item) => item['id'] == recipeId);
      await docRef.set({meal: existing}, SetOptions(merge: true));
      
      await loadMealPlans(); // Refresh the data
    } catch (e) {
      _setError('Failed to remove meal: $e');
    }
  }

  // Add recipe to meal plan
  Future<void> addRecipeToMealPlan(String date, String mealType, Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlans')
          .doc(date);

      final doc = await docRef.get();
      Map<String, dynamic> data = doc.exists ? doc.data()! : {};

      List existing = data[mealType] ?? [];
      existing.add({
        'id': recipe['id'],
        'title': recipe['title'],
        'image': recipe['image'],
      });

      await docRef.set({mealType: existing}, SetOptions(merge: true));
      await loadMealPlans(); // Refresh the data
    } catch (e) {
      _setError('Failed to add recipe to meal plan: $e');
    }
  }

  // Get days for current view
  List<String> getDays() {
    final now = DateTime.now();
    return _isWeekly 
        ? List.generate(7, (i) => _formatDate(startOfWeek.add(Duration(days: i)))) 
        : [_formatDate(now)];
  }

  // Get meal icons
  Map<String, String> get mealIcons => {
    'breakfast': '🍳', 
    'lunch': '🍱', 
    'dinner': '🌙'
  };

  // Private helper methods
  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMealPlanForDate(String date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mealPlans')
          .doc(date)
          .get();

      if (!doc.exists || doc.data() == null) return {};
      
      final data = doc.data()!;
      Map<String, List<Map<String, dynamic>>> mealData = {};
      
      for (var meal in ['breakfast', 'lunch', 'dinner']) {
        mealData[meal] = data[meal] is List
            ? List<Map<String, dynamic>>.from(data[meal])
            : [];
      }
      
      return mealData;
    } catch (e) {
      _setError('Failed to fetch meal plan for date: $e');
      return {};
    }
  }

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