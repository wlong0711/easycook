import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ingredient_recognition_service.dart';

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
    Navigator.pop(context, _selected.toList()); // Return to pantry screen
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
        title: Text("Scan Ingredients"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: Icon(Icons.image_search),
              label: Text("Pick or Take a Photo"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 20),
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
                  children: [
                    Text("Select ingredients to add:",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Expanded(
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
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _addSelectedToPantry,
                      icon: Icon(Icons.add),
                      label: Text("Add to Pantry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
