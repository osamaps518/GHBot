/// Calories, protein, carbs and fat, each a whole number of tenths: 1234 is
/// 123.4 (decision 30).
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

/// A food kept on the phone or found by search: a catalog food, or one of
/// the trainee's own.
class Food {
  const Food({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.per100g,
    this.own = false,
    this.barcode,
    this.revision = 0,
    this.sentRevision = 0,
    this.refused = false,
  });

  /// Reads a food the server sent: from search, a pull or the answer to a
  /// send. It is the server's copy, so it is confirmed at its revision. The
  /// API sends values with 1 decimal; `round` keeps 28.2, which is 281.99…
  /// as a double, at 282 tenths.
  factory Food.fromJson(Map<String, Object?> json) {
    int tenths(String key) => ((json[key] as num) * 10).round();
    final revision = json['revision'] as int;
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
      own: json['own'] as bool,
      barcode: json['barcode'] as String?,
      revision: revision,
      sentRevision: revision,
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
    required this.own,
    required this.barcode,
    required this.revision,
    required this.sentRevision,
    required this.refused,
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

  /// The trainee's own food, which only they see.
  final bool own;

  /// 8 to 14 digits, or null.
  final String? barcode;

  /// 0 for a catalog food. An own food starts at 1, plus 1 on every change.
  final int revision;

  /// The last revision the server confirmed, 0 if never.
  final int sentRevision;

  /// The server refused this own food; it waits for the trainee to change
  /// it.
  final bool refused;

  /// The name in the app's language ([languageCode]), or the other one when
  /// the food has no name in it.
  String name(String languageCode) =>
      (languageCode == 'ar' ? nameAr ?? nameEn : nameEn ?? nameAr)!;
}
