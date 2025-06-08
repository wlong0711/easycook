import 'package:flutter/material.dart';
import '../../services/spoonacular_service.dart';
import '../recipe_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  List recipes = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final String logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/easycook-ca3d5.firebasestorage.app/o/EasyCook(logo).png?alt=media&token=4f03c781-15fa-43ef-b640-3d56367e541c';

  @override
  void initState() {
    super.initState();
    fetchRandomRecipes();
  }

  Future<void> fetchRandomRecipes() async {
    try {
      var data = await _spoonacularService.getRandomRecipes();
      if (!mounted) return;
      setState(() {
        recipes = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching recipes: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> searchRecipes() async {
    if (_searchController.text.isEmpty) return;
    setState(() => isLoading = true);

    try {
      var data = await _spoonacularService.searchRecipes(_searchController.text);
      if (!mounted) return;
      setState(() {
        recipes = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Logo + Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    logoUrl,
                    height: 60,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 60),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "EasyCook",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => searchRecipes(),
                  decoration: InputDecoration(
                    hintText: "Search for recipes...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                fetchRandomRecipes();
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Recipe Grid
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : recipes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text("No recipes found. Try a different search.",
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : GridView.builder(
                            itemCount: recipes.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 3 / 4,
                            ),
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];
                              final imageUrl = (recipe['image'] ?? '').replaceAll(RegExp(r'\.+\$'), '');

                              String getCalories(Map<String, dynamic> recipe) {
                                try {
                                  final nutrients = recipe['nutrition']?['nutrients'];
                                  if (nutrients is List) {
                                    final cal = nutrients.firstWhere(
                                      (n) => n['name'] == 'Calories',
                                      orElse: () => null,
                                    );
                                    return cal != null ? "${cal['amount'].round()} kcal" : "– kcal";
                                  }
                                } catch (e) {
                                  print("Calorie parse error: $e");
                                }
                                return "– kcal";
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailsScreen(recipeId: recipe['id']),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          imageUrl.isNotEmpty
                                              ? imageUrl
                                              : 'https://via.placeholder.com/150',
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset('assets/images/placeholder.png', height: 120, fit: BoxFit.cover),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe['title'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              getCalories(recipe),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
