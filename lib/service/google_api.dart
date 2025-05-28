import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:health_app_v1/components/general/my_snackbar.dart';

class GoogleApi {
  final String? mimeType;
  final Uint8List? imageBytes;
  final String prompt;

  GoogleApi({
    this.mimeType,
    this.imageBytes,
    required this.prompt,
  });

  final GenerativeModel _model = GenerativeModel(
      apiKey: dotenv.env['GOOGLE_API_KEY'] ?? 'API_KEY not found',
      model: 'gemini-2.0-flash');

  List? parseAiJson(BuildContext context, String aiResponse) {
    try {
      List decodedData = List.from(jsonDecode(aiResponse));
      if (decodedData.isNotEmpty) {
        return decodedData;
      } else {
        if (context.mounted) {
          showMySnackBar(context, 'AI Generation Error: Try again!', 'Dismiss',
              () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          });
        }
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        showMySnackBar(context, e.toString(), 'Dismiss', () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
      }
      return null;
    }
  }

  Future<GenerateContentResponse> generateContentResponse() async {
    List<Content> content = [];

    if (mimeType == null || imageBytes == null) {
      content = [Content.text(prompt)];
    } else {
      content = [
        Content.text(prompt),
        Content.data(mimeType!, imageBytes!),
      ];
    }

    return await _model.generateContent(content);
  }
}
