import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ingredient_recognition_service.dart';
import '../recipe_results_screen.dart';

class IngredientScanScreen extends StatefulWidget {
  const IngredientScanScreen({super.key});

  @override
  State<IngredientScanScreen> createState() => _IngredientScanScreenState();
}

class _IngredientScanScreenState extends State<IngredientScanScreen> {
  File? _image;
  List<String> _ingredients = [];
  final Set<String> _selected = {};
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _ingredients = [];
      _selected.clear();
    });

    await _processImage(_image!);
  }

  Future<void> _processImage(File image) async {
    setState(() => _loading = true);
    final results = await IngredientRecognitionService.recognizeIngredientsFromImage(image);
    if (!mounted) return;
    setState(() {
      _ingredients = results;
      _selected.addAll(results);
      _loading = false;
    });
  }

  Future<void> _addSelectedToPantry() async {
    if (_selected.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('pantries').doc(uid);
    final snapshot = await docRef.get();

    List<String> existing = [];
    if (snapshot.exists && snapshot.data()?['ingredients'] is List) {
      existing = List<String>.from(snapshot.data()!['ingredients']);
    }

    final updated = {...existing, ..._selected}.toList();
    await docRef.set({'ingredients': updated});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added to pantry successfully!")),
    );
    Navigator.pop(context, _selected.toList());
  }

  void _exploreWithSelectedIngredients() {
    if (_selected.isEmpty) return;
    final query = _selected.join(',');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeResultsScreen(ingredients: query),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Choose Image Source", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.orange),
              title: Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.orange),
              title: Text("Upload from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Ingredients"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.image_search),
              label: const Text("Pick or Take a Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 30),

            if (_image == null && !_loading && _ingredients.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.photo_camera_back, size: 90, color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        "Start by picking or taking a photo\nof ingredients you want to scan.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200),
              ),

            const SizedBox(height: 20),

            if (_loading)
              const CircularProgressIndicator()
            else if (_ingredients.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select ingredients to add:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: _ingredients.length,
                          itemBuilder: (context, index) {
                            final item = _ingredients[index];
                            return CheckboxListTile(
                              value: _selected.contains(item),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(item);
                                  } else {
                                    _selected.remove(item);
                                  }
                                });
                              },
                              title: Text(item),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selected.isEmpty ? null : _addSelectedToPantry,
                          icon: const Icon(Icons.add),
                          label: const Text("Add to Pantry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _selected.isEmpty ? null : _exploreWithSelectedIngredients,
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text("Explore Recipes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (_image != null)
              Expanded(
                child: Column(
                  children: const [
                    SizedBox(height: 50),
                    Icon(Icons.sentiment_dissatisfied_outlined,
                        size: 60, color: Colors.redAccent),
                    SizedBox(height: 12),
                    Text(
                      "No ingredients found in the image.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
