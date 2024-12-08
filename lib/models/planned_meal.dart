import 'recipe.dart';

class PlannedMeal {
  final Recipe recipe;
  final String mealType;
  final DateTime date;

  PlannedMeal({
    required this.recipe,
    required this.mealType,
    required this.date,
  });
} 