import 'package:flutter/material.dart';
import '../recipe_results_screen.dart';

class CuisinesScreen extends StatelessWidget {
  const CuisinesScreen({super.key});

  final List<String> cuisines = const [
    "Asian", "Malay", "Chinese", "Indian", "Japanese", "Korean", "Thai"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text("Cuisines"),
        centerTitle: true,
        backgroundColor: Colors.orange,      
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: cuisines.length,
        itemBuilder: (context, index) {
          final label = cuisines[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeResultsScreen(
                      filterType: 'cuisine',
                      filterValue: label.toLowerCase(),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          );
        },
      ),
    );
  }
}
