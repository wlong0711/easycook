import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipe_details_screen.dart';

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

  DateTime get _endOfWeek => _startOfWeek.add(const Duration(days: 6));

  String get _formattedWeekRange {
    final formatter = DateFormat('MMMM d, yyyy');
    return "${formatter.format(_startOfWeek)} - ${formatter.format(_endOfWeek)}";
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
    ['breakfast', 'lunch', 'dinner'].forEach((meal) {
      if (data[meal] is List) {
        mealData[meal] = List<Map<String, dynamic>>.from(data[meal]);
      } else {
        mealData[meal] = [];
      }
    });

    return mealData;
  }

  Future<void> _loadMealPlans() async {
    Map<String, Map<String, List<Map<String, dynamic>>>> newPlans = {};

    if (isWeekly) {
      for (int i = 0; i < 7; i++) {
        final date = _startOfWeek.add(Duration(days: i));
        final dateStr = _formatDate(date);
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

  @override
  void didUpdateWidget(covariant MealPlannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  Future<void> _deleteRecipeFromMealPlan(String date, String meal, String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mealPlans')
        .doc(date);

    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return;

    Map<String, dynamic> data = doc.data()!;
    List existing = data[meal] ?? [];

    existing.removeWhere((r) => r['id'].toString() == recipeId);

    await docRef.set({meal: existing}, SetOptions(merge: true));

    await _loadMealPlans();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recipe removed from $meal on $date")),
    );
  }

  Widget _buildMealsForDate(String date, Map<String, List<Map<String, dynamic>>> meals) {
    final dateObj = DateFormat('yyyy-MM-dd').parse(date);
    final dayLabel = isWeekly ? DateFormat('EEEE').format(dateObj) : 'Today';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ExpansionTile(
        key: PageStorageKey(date),
        initiallyExpanded: true,
        title: Text(
          "$dayLabel - $date",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: ['breakfast', 'lunch', 'dinner'].map((meal) {
          final isExpanded = _expandedMeals[date]?.contains(meal) ?? false;
          final mealRecipes = meals[meal] ?? [];

          return ExpansionTile(
            key: PageStorageKey('$date-$meal'),
            title: Text(
              meal[0].toUpperCase() + meal.substring(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) => _toggleMealExpansion(date, meal),
            children: mealRecipes.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "No $meal planned.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  ]
                : mealRecipes.map((recipe) {
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: recipe['image'] != null
                            ? Image.network(recipe['image'], width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                      ),
                      title: Text(recipe['title'] ?? 'No Title'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Recipe'),
                              content: Text('Are you sure you want to remove this recipe from $meal on $dayLabel?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await _deleteRecipeFromMealPlan(date, meal, recipe['id'].toString());
                          }
                        },
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Meal Planner"),
        centerTitle: true,
        backgroundColor: Colors.orange,
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

          const SizedBox(height: 10),

          if (isWeekly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Text(
                  _formattedWeekRange,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          const SizedBox(height: 10),

          const Divider(),

          Expanded(
            child: _mealPlans.isEmpty
                ? Center(child: Text("No meal plans found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: isWeekly ? 7 : 1,
                    itemBuilder: (context, index) {
                      final date = isWeekly
                          ? _formatDate(_startOfWeek.add(Duration(days: index)))
                          : _formatDate(DateTime.now());
                      final mealsForDate = _mealPlans[date] ?? {};
                      return _buildMealsForDate(date, mealsForDate);
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (selected) BoxShadow(color: Colors.teal.shade100, blurRadius: 5),
          ],
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
