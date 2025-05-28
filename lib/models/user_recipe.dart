import 'package:cloud_firestore/cloud_firestore.dart';

class UserRecipe {
  final String? id; // Document ID from Firestore
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final String userId;
  final Timestamp createdAt;

  UserRecipe({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    required this.userId,
    required this.createdAt,
  });

  // Method to convert a UserRecipe object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  // Factory constructor to create a UserRecipe object from a Firestore document snapshot
  factory UserRecipe.fromMap(Map<String, dynamic> map, String documentId) {
    return UserRecipe(
      id: documentId,
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String?,
      userId: map['userId'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  // Helper to create UserRecipe from a DocumentSnapshot
  factory UserRecipe.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserRecipe.fromMap(doc.data()!, doc.id);
  }
}
