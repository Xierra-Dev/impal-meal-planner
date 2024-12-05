import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import 'dart:io' show File;
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Existing methods...

  Future<void> saveUserPersonalization(Map<String, dynamic> data) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .set(data, SetOptions(merge: true));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user personalization: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserPersonalization() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        return doc.data() as Map<String, dynamic>?;
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting user personalization: $e');
      rethrow;
    }
  }

  Future<void> saveUserGoals(List<String> goals) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'goals': goals});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user goals: $e');
      rethrow;
    }
  }

  Future<void> saveUserAllergies(List<String> allergies) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'allergies': allergies});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user allergies: $e');
      rethrow;
    }
  }

  // New methods for recipe saving functionality

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving recipe: $e');
      rethrow;
    }
  }

  Future<void> unsaveRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .delete();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error removing saved recipe: $e');
      rethrow;
    }
  }

  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      print('Error checking if recipe is saved: $e');
      return false;
    }
  }

  Future<bool> isRecipePlanned(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      print('Error checking if recipe is planned: $e');
      return false;
    }
  }

  Future<List<Recipe>> getSavedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .orderBy('savedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo
                .generateRandom(), // We'll regenerate this since it's not stored
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting saved recipes: $e');
      return [];
    }
  }

  Future<List<Recipe>> getPlannedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .orderBy('plannedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo
                .generateRandom(), // We'll regenerate this since it's not stored
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting planned recipes: $e');
      return [];
    }
  }

  Future<void> addToRecentlyViewed(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'category': recipe.category,
          'area': recipe.area,
          'image': recipe.image,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'viewedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error adding to recently viewed: $e');
      rethrow;
    }
  }

  Future<void> addToMealPlan(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('meal_plan')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'addedAt': FieldValue.serverTimestamp(),
        });
        print('Recipe added to meal plan: ${recipe.title}');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error adding recipe to meal plan: $e');
      rethrow;
    }
  }

  Future<List<Recipe>> getRecentlyViewedRecipes({int limit = 10}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .orderBy('viewedAt', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            ingredients: [], // These fields are not stored in recently viewed
            measurements: [], // for simplicity, but you can add them if needed
            instructions: '',
            instructionSteps: [],
            nutritionInfo: NutritionInfo.generateRandom(),
          );
        }).toList();
      } else {
        print('No authenticated user found');
        return [];
      }
    } catch (e) {
      print('Error getting recently viewed recipes: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permission denied. Please check Firebase security rules.');
      }
      return [];
    }
  }
  // Tambahkan metode ini di dalam kelas FirestoreService

  Future<String?> getCurrentUserUsername() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        // Periksa apakah dokumen ada dan memiliki field username
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('username')) {
          return userData['username'];
        }

        return null;
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> removePlannedRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Menghapus dokumen dengan ID tertentu dari koleksi planned_recipes
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .delete();
        print('Planned recipe removed: $recipeId');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error removing planned recipe: $e');
      rethrow;
    }
  }

  Future<bool> isPlannerRecipe(String recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('plannedMeals')
          .doc(recipeId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking planner status: $e');
      return false;
    }
  }

  Future<void> planRecipe(Recipe recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('plannedMeals')
          .doc(recipe.id)
          .set({
        'id': recipe.id,
        'title': recipe.title,
        'image': recipe.image,
        'area': recipe.area,
        'preparationTime': recipe.preparationTime,
        'healthScore': recipe.healthScore,
        // Add any other relevant fields from the Recipe class
        'plannedAt': FieldValue.serverTimestamp(), // Optional: add timestamp
      });
    } catch (e) {
      print('Error planning recipe: $e');
      throw e;
    }
  }

  Future<void> unplanRecipe(String recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('plannedMeals')
          .doc(recipeId)
          .delete();
    } catch (e) {
      print('Error unplanning recipe: $e');
      throw e;
    }
  }

  Future<void> addPlannedRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Menambahkan dokumen baru ke koleksi planned_recipes
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'plannedAt': FieldValue.serverTimestamp(),
        });
        print('Planned recipe added: ${recipe.title}');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error adding planned recipe: $e');
      rethrow;
    }
  }

  Future<void> removeFromSavedRecipes(Recipe recipe) async {
    try {
      // Assuming you're using Firebase Authentication and have the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Reference to the Firestore collection of saved recipes for this user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('saved_recipes')
          .doc(recipe.id) // Assuming the recipe has a unique ID
          .delete();
    } catch (e) {
      print('Error removing recipe from saved: $e');
      rethrow;
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      final imageUrl =
          await _storageService.uploadProfilePicture(imageFile, userId);
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': imageUrl,
      });
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update(data);
    }
  }

  Future<List<String>> getUserGoals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['goals'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user goals: $e');
      return [];
    }
  }

  Future<List<String>> getUserAllergies() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['allergies'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user allergies: $e');
      return [];
    }
  }
}
