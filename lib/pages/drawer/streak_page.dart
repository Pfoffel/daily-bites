import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_app_v1/components/general/my_snackbar.dart';
import 'package:health_app_v1/service/google_api.dart';
import 'package:image_picker/image_picker.dart';

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  bool isLoading = false;
  String ingredientsText = 'No Analisys Yet';
  List? ingredients;

  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = ImagePicker();

    Future<void> pickAndProcessImage() async {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          isLoading = true;
        });
        File imageFile = File(pickedFile.path);
        final imageBytes = await imageFile.readAsBytes();

        String mimeType = '';
        if (pickedFile.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (pickedFile.path.toLowerCase().endsWith('.jpg') ||
            pickedFile.path.toLowerCase().endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else {
          if (context.mounted) {
            showMySnackBar(context, 'Unsupported Image format', 'Dismiss', () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            });
          }
          return;
        }

        GoogleApi gemini = GoogleApi(
            prompt:
                'Analize the picture attached and give me an output in json format of the basic ingredients you have identified as a json list. Only respond with the actual json text no formatting, only the start brackets till the end brackets, in the following json format: [list of ingredients].',
            imageBytes: imageBytes,
            mimeType: mimeType);

        final response = await gemini.generateContentResponse();
        if (context.mounted && response.text != null) {
          List ingredients = gemini.parseAiJson(context, response.text!) ?? [];
          if (ingredients.isNotEmpty) {
            setState(() {
              ingredientsText = ingredients.toString();
              isLoading = false;
            });
            return;
          }
          if (context.mounted) {
            showMySnackBar(context, 'Ingredients not found', 'Dismiss', () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            });
          }
        }
        return;
      } else {
        if (context.mounted) {
          showMySnackBar(context, 'No Image Selected', 'Dismiss', () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          });
        }
        return;
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Streak", style: Theme.of(context).textTheme.labelLarge),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      ingredientsText = 'No Analisys Yet';
                    });
                    pickAndProcessImage();
                  },
                  child: Text("Upload Photo")),
              SizedBox(
                height: 30,
              ),
              isLoading
                  ? CircularProgressIndicator()
                  : Text(
                      ingredientsText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            ],
          ),
        ));
  }
}
