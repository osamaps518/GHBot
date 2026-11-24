/// Calories, protein, carbs and fat, each a whole number of tenths: 1234 is
/// 123.4 (docs/decisions.md, 30).
class Nutrients {
  const Nutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const zero = Nutrients(calories: 0, protein: 0, carbs: 0, fat: 0);

  /// Adds [all] exactly, in tenths.
  factory Nutrients.sum(Iterable<Nutrients> all) => all.fold(
    zero,
    (sum, next) => Nutrients(
      calories: sum.calories + next.calories,
      protein: sum.protein + next.protein,
      carbs: sum.carbs + next.carbs,
      fat: sum.fat + next.fat,
    ),
  );

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
}

/// A food kept on the phone or found by search.
class Food {
  const Food({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.per100g,
  });

  /// Builds a food from a `foods` row.
  Food.fromColumns({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required int caloriesPer100g,
    required int proteinPer100g,
    required int carbsPer100g,
    required int fatPer100g,
  }) : per100g = Nutrients(
         calories: caloriesPer100g,
         protein: proteinPer100g,
         carbs: carbsPer100g,
         fat: fatPer100g,
       );

  final String id;

  /// At least one name is set.
  final String? nameAr;
  final String? nameEn;
  final Nutrients per100g;
}
