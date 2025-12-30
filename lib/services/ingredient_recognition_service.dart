import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class IngredientRecognitionService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<List<String>> recognizeIngredientsFromImage(File imageFile) async {
    
    if (_apiKey.isEmpty) {
      print("Error: API Key not found in .env file");
      return [];
    }
    
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    final bytes = await imageFile.readAsBytes();

    final content = [
      Content.multi([
        TextPart(
          "You are an AI food assistant. Based on the photo provided, "
          "identify only edible cooking ingredients (e.g., vegetables, fruits, spices, or meats). "
          "For each ingredient, try to include its form if recognizable (e.g., diced tomato, sliced onion, raw egg, liquid egg, whole garlic). "
          "Respond with a bullet-point list in this format:\n"
          "* Diced Tomato\n* Liquid Egg\n* Sliced Onion\n\n"
          "If no recognizable ingredient is present, respond exactly with: 'No ingredients found.'"
        ),
        DataPart('image/jpeg', bytes),
      ])
    ];


    final response = await model.generateContent(content);
    final rawText = response.text;

    if (rawText == null || rawText.trim().toLowerCase().contains("no ingredients found")) {
      return [];
    }

    return rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) =>
            line.isNotEmpty &&
            (line.startsWith("*") || line.startsWith("-")) &&
            line.length > 2)
        .map((line) => line.replaceAll(RegExp(r'^[-*]\s*'), '')) // remove "* " or "- "
        .toList();
  }
}
