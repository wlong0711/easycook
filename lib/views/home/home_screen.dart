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
  TextEditingController _searchController = TextEditingController();

  // 🔗 Replace this with your actual Firebase Storage logo URL
  final String logoUrl = 'https://firebasestorage.googleapis.com/v0/b/easycook-ca3d5.firebasestorage.app/o/EasyCook(logo).png?alt=media&token=4f03c781-15fa-43ef-b640-3d56367e541c';

  @override
  void initState() {
    super.initState();
    fetchRandomRecipes();
  }

  Future<void> fetchRandomRecipes() async {
    try {
      var data = await _spoonacularService.getRandomRecipes();
      setState(() {
        recipes = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching recipes: $e');
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
      setState(() {
        recipes = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ App Logo
            Center(
              child: Image.network(
                logoUrl,
                height: 100,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported, size: 80),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ App Title
            Center(
              child: Text(
                "EasyCook",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Search Field
            TextField(
              controller: _searchController,
              onSubmitted: (value) => searchRecipes(),
              decoration: InputDecoration(
                hintText: "Type your recipe name or keywords",
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Recipe Grid
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : recipes.isEmpty
                      ? Center(child: Text("No recipes found. Try different keywords."))
                      : GridView.builder(
                          itemCount: recipes.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            String imageUrl = (recipe['image'] ?? '').replaceAll(RegExp(r'\.+\$'), '');

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailsScreen(recipeId: recipe['id']),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imageUrl.isNotEmpty
                                          ? imageUrl
                                          : 'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.asset('assets/images/placeholder.png'),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Text(
                                      recipe['title'] ?? '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        backgroundColor: Colors.black45,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Icon(Icons.favorite_border, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
