import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../recipe_details_screen.dart';
import '../home/home_screen.dart'; 
import '../categories/categories_screen.dart';
import '../pantry/my_pantry_screen.dart';
import '../profile/favorite_recipes_screen.dart';
import '../../viewmodels/meal_planner_viewmodel.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  @override
  void initState() {
    super.initState();
    // Load meal plans when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealPlannerViewModel>(context, listen: false).loadMealPlans();
    });
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(Icons.home, "Browse Home", HomeScreen()),
            _buildOption(Icons.category, "Browse by Category", CategoriesScreen()),
            _buildOption(Icons.kitchen, "Use My Pantry", MyPantryScreen()),
            _buildOption(Icons.favorite, "Favorite Recipes", FavoriteRecipesScreen()),
          ],
        ),
      ),
    );
  }

  ListTile _buildOption(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  Widget _buildMealsForDate(String date, Map<String, List<Map<String, dynamic>>> meals, MealPlannerViewModel viewModel) {
    final dayLabel = viewModel.isWeekly
        ? DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(date))
        : 'Today';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ExpansionTile(
        key: PageStorageKey(date),
        initiallyExpanded: true,
        title: Text("$dayLabel • $date", style: TextStyle(fontWeight: FontWeight.bold)),
        children: ['breakfast', 'lunch', 'dinner'].map((meal) {
          final recipes = meals[meal] ?? [];
          return ExpansionTile(
            key: PageStorageKey('$date-$meal'),
            initiallyExpanded: viewModel.expandedMeals[date]?.contains(meal) ?? false,
            title: Text("${viewModel.mealIcons[meal]} ${meal[0].toUpperCase()}${meal.substring(1)}"),
            onExpansionChanged: (expanded) => viewModel.toggleMealExpansion(date, meal),
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
                        onPressed: () => viewModel.removeMeal(date, meal, recipe['id']),
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
    return Consumer<MealPlannerViewModel>(
      builder: (context, mealPlannerViewModel, child) {
        final days = mealPlannerViewModel.getDays();

        return Scaffold(
          backgroundColor: Colors.orange[50],
          appBar: AppBar(
            title: Text("Meal Planner"),
            centerTitle: true,
            backgroundColor: Colors.orange,
            actions: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _showAddOptions,
                tooltip: "Add Recipe from...",
              )
            ],
          ),
          body: mealPlannerViewModel.isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabButton("Today", !mealPlannerViewModel.isWeekly, () {
                          mealPlannerViewModel.toggleView();
                        }),
                        _buildTabButton("This Week", mealPlannerViewModel.isWeekly, () {
                          mealPlannerViewModel.toggleView();
                        }),
                      ],
                    ),
                    if (mealPlannerViewModel.isWeekly)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(mealPlannerViewModel.formattedWeekRange,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
                      ),
                    Expanded(
                      child: mealPlannerViewModel.mealPlans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text("No meal plans found.",
                                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: days.length,
                              itemBuilder: (context, index) {
                                final date = days[index];
                                return _buildMealsForDate(date, mealPlannerViewModel.mealPlans[date] ?? {}, mealPlannerViewModel);
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
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
