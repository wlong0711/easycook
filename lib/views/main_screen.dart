import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'categories/categories_screen.dart';
import 'pantry/my_pantry_screen.dart';
import 'meal_planner/meal_planner_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;  // ✅ HomeScreen is the default tab

  final List<Widget> _pages = [
    HomeScreen(),         // 🏠 Home Page
    CategoriesScreen(),   // 🔲 Categories
    MyPantryScreen(),     // 🏪 My Pantry
    MealPlannerScreen(),  // 📅 Meal Planner
    ProfileScreen(),      // 👤 Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],  // Show selected screen

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;  // Change selected tab
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: "My Pantry"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Meal Planner"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
