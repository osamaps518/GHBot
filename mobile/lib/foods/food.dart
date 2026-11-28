import '../core/typed_number.dart';

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

/// A typed value per 100 g in tenths, or null unless it is from 0 to [max]
/// tenths with at most 1 decimal.
int? parsePer100g(String typed, int max) {
  final match = RegExp(r'^(\d{1,4})(?:\.(\d)?0*)?$')
      .firstMatch(westernNumberText(typed));
  if (match == null) return null;
  final tenths = int.parse(match[1]!) * 10 + int.parse(match[2] ?? '0');
  return tenths <= max ? tenths : null;
}

/// The most calories per 100 g, and the most of each macro and of the
/// three together, in tenths (decision 38).
const maxCaloriesPer100g = 9000;
const maxMacroPer100g = 1000;

/// Whether the server would accept an own food with these values (decision
/// 38): at least one name; each name given 1 to 80 characters, counted as
/// the server counts them (code points), not only spaces, with no NUL;
/// calories 0–900 and each macro 0–100 g per 100 g, the macros at most
/// 100 g together; a barcode of 8 to 14 digits, or none. Values are in
/// tenths. The phone checks before every save.
bool passesOwnFoodChecks({
  required String? nameAr,
  required String? nameEn,
  required Nutrients per100g,
  required String? barcode,
}) {
  bool inRange(int value, int max) => value >= 0 && value <= max;
  return (nameAr != null || nameEn != null) &&
      ownFoodNameFits(nameAr) &&
      ownFoodNameFits(nameEn) &&
      inRange(per100g.calories, maxCaloriesPer100g) &&
      inRange(per100g.protein, maxMacroPer100g) &&
      inRange(per100g.carbs, maxMacroPer100g) &&
      inRange(per100g.fat, maxMacroPer100g) &&
      per100g.protein + per100g.carbs + per100g.fat <= maxMacroPer100g &&
      ownFoodBarcodeFits(barcode);
}

/// Whether [name] is none, or an own food name the server takes.
bool ownFoodNameFits(String? name) =>
    name == null ||
    (name.runes.length <= 80 &&
        !_blank.hasMatch(name) &&
        !name.contains('\u0000'));

/// Whether [barcode] is none, or 8 to 14 digits.
bool ownFoodBarcodeFits(String? barcode) =>
    barcode == null || RegExp(r'^[0-9]{8,14}$').hasMatch(barcode);

/// Empty, or only characters that are spaces to Dart or to the server's
/// Python (`str.isspace`), so the phone never takes a name the server
/// calls blank.
final _blank = RegExp(r'^[\s\x1c-\x1f\x85]*$');

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
