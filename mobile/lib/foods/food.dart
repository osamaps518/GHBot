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

/// [tenths] rounded half up to a whole number, for display.
int roundTenths(int tenths) => (tenths + 5) ~/ 10;

/// [tenths] with its decimal only when it has one: 375 is "37.5", 600 "60".
String formatTenths(int tenths) =>
    tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10}.${tenths % 10}';

/// A food kept on the phone or found by search.
class Food {
  const Food({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.per100g,
  });

  /// Reads a food from `GET /foods`. The API sends values with 1 decimal;
  /// `round` keeps 28.2, which is 281.99… as a double, at 282 tenths.
  factory Food.fromJson(Map<String, Object?> json) {
    int tenths(String key) => ((json[key] as num) * 10).round();
    return Food(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      per100g: Nutrients(
        calories: tenths('calories'),
        protein: tenths('protein'),
        carbs: tenths('carbs'),
        fat: tenths('fat'),
      ),
    );
  }

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

  /// The name in the app's language ([languageCode]), or the other one when
  /// the food has no name in it.
  String name(String languageCode) =>
      (languageCode == 'ar' ? nameAr ?? nameEn : nameEn ?? nameAr)!;
}
