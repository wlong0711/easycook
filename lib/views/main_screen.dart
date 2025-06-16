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
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    CategoriesScreen(),
    MyPantryScreen(),
    MealPlannerScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        child: _pages[_selectedIndex],
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 11),
            items: [
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1 ? Icons.grid_view_rounded : Icons.grid_view_outlined),
                label: "Categories",
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2 ? Icons.kitchen_rounded : Icons.kitchen_outlined),
                label: "My Pantry",
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined),
                label: "Meal Planner",
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 4 ? Icons.person_rounded : Icons.person_outline),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
