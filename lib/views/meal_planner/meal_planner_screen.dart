import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipe_details_screen.dart';
import '../home/home_screen.dart'; 
import '../categories/categories_screen.dart';
import '../pantry/my_pantry_screen.dart';
import '../profile/favorite_recipes_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  bool isWeekly = true;
  Map<String, Map<String, List<Map<String, dynamic>>>> _mealPlans = {};
  Map<String, Set<String>> _expandedMeals = {};

  DateTime get _startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  String get _formattedWeekRange {
    final formatter = DateFormat('MMMM d, yyyy');
    return "${formatter.format(_startOfWeek)} - ${formatter.format(_startOfWeek.add(Duration(days: 6)))}";
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMealPlanForDate(String date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final doc = await FirebaseFirestore.instance
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
  }

  Future<void> _loadMealPlans() async {
    Map<String, Map<String, List<Map<String, dynamic>>>> newPlans = {};
    if (isWeekly) {
      for (int i = 0; i < 7; i++) {
        final dateStr = _formatDate(_startOfWeek.add(Duration(days: i)));
        newPlans[dateStr] = await _fetchMealPlanForDate(dateStr);
      }
    } else {
      final todayStr = _formatDate(DateTime.now());
      newPlans[todayStr] = await _fetchMealPlanForDate(todayStr);
    }
    setState(() {
      _mealPlans = newPlans;
      _expandedMeals = {};
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  void _toggleMealExpansion(String date, String meal) {
    setState(() {
      _expandedMeals[date] ??= {};
      if (_expandedMeals[date]!.contains(meal)) {
        _expandedMeals[date]!.remove(meal);
      } else {
        _expandedMeals[date]!.add(meal);
      }
    });
  }

  Future<void> _removeMeal(String date, String meal, int recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealPlans')
        .doc(date);

    final doc = await docRef.get();
    if (!doc.exists) return;

    List existing = doc.data()?[meal] ?? [];
    existing.removeWhere((item) => item['id'] == recipeId);
    await docRef.set({meal: existing}, SetOptions(merge: true));
    await _loadMealPlans();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Browse Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text("Browse by Category"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.kitchen),
            title: Text("Use My Pantry"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => MyPantryScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text("Favorite Recipes"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => FavoriteRecipesScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealsForDate(String date, Map<String, List<Map<String, dynamic>>> meals) {
    final dayLabel = isWeekly
        ? DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(date))
        : 'Today';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ExpansionTile(
        key: PageStorageKey(date),
        initiallyExpanded: true,
        title: Text("$dayLabel - $date", style: TextStyle(fontWeight: FontWeight.bold)),
        children: ['breakfast', 'lunch', 'dinner'].map((meal) {
          final recipes = meals[meal] ?? [];
          return ExpansionTile(
            key: PageStorageKey('$date-$meal'),
            initiallyExpanded: _expandedMeals[date]?.contains(meal) ?? false,
            title: Text(meal[0].toUpperCase() + meal.substring(1)),
            onExpansionChanged: (expanded) => _toggleMealExpansion(date, meal),
            children: recipes.isEmpty
                ? [ListTile(title: Text("No $meal planned."))]
                : recipes.map((recipe) {
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: recipe['image'] != null
                            ? Image.network(recipe['image'], width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                      ),
                      title: Text(recipe['title'] ?? 'No Title'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeMeal(date, meal, recipe['id']),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailsScreen(recipeId: recipe['id']),
                          ),
                        );
                      },
                    );
                  }).toList(),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = isWeekly ? List.generate(7, (i) => _formatDate(_startOfWeek.add(Duration(days: i)))) : [_formatDate(now)];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Meal Planner"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddOptions,
            tooltip: "Add Recipe from...",
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Today", !isWeekly, () {
                setState(() {
                  isWeekly = false;
                  _loadMealPlans();
                });
              }),
              _buildTabButton("This Week", isWeekly, () {
                setState(() {
                  isWeekly = true;
                  _loadMealPlans();
                });
              }),
            ],
          ),
          if (isWeekly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(_formattedWeekRange,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          Expanded(
            child: _mealPlans.isEmpty
                ? Center(child: Text("No meal plans found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final date = days[index];
                      return _buildMealsForDate(date, _mealPlans[date] ?? {});
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected ? [BoxShadow(color: Colors.teal.shade100, blurRadius: 5)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
