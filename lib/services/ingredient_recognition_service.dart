import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class IngredientRecognitionService {
  static const _apiKey = 'AIzaSyBNsLX1tOB5gCLb6kvgSdW4oRi5KXh2H2I';

  static Future<List<String>> recognizeIngredientsFromImage(File imageFile) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    final bytes = await imageFile.readAsBytes();

    final content = [
      Content.multi([
        TextPart("What ingredients are shown in this image? Respond with a list."),
        DataPart('image/jpeg', bytes),
      ])
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null) return [];

    return text
        .split(RegExp(r'\n|-')) // split lines
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
