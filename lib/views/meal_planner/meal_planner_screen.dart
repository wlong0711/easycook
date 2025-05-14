import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  bool isWeekly = true;

  DateTime get _startOfWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _endOfWeek => _startOfWeek.add(const Duration(days: 6));

  String get _formattedWeekRange {
    final formatter = DateFormat('MMMM d, yyyy');
    return "${formatter.format(_startOfWeek)} - ${formatter.format(_endOfWeek)}";
  }

  final List<String> _weekdays = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

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

          // Toggle: Today vs This Week
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton("Today", !isWeekly, () {
                setState(() {
                  isWeekly = false;
                });
              }),
              _buildTabButton("This Week", isWeekly, () {
                setState(() {
                  isWeekly = true;
                });
              }),
            ],
          ),

          const SizedBox(height: 10),

          // Date range
          if (isWeekly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: isWeekly ? 7 : 1,
              itemBuilder: (context, index) {
                final label = isWeekly ? _weekdays[index] : DateFormat('EEEE').format(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        // Open meal editor per day
                      },
                    ),
                  ),
                );
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
