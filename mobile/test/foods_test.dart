import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/auth/auth_session.dart';
import 'package:ghbot/core/api_client.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/foods/food.dart';
import 'package:ghbot/foods/foods_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Food _food(String id, String? nameAr, String? nameEn) =>
    Food(id: id, nameAr: nameAr, nameEn: nameEn, per100g: Nutrients.zero);

void main() {
  test('values from the API become tenths, rounded, not truncated', () {
    final food = Food.fromJson({
      'id': 'rice',
      'name_ar': 'أرز أبيض مطبوخ',
      'name_en': null,
      'calories': 130.0,
      'protein': 2.7,
      'carbs': 28.2,
      'fat': 0.3,
    });

    expect(
      [
        food.per100g.calories,
        food.per100g.protein,
        food.per100g.carbs,
        food.per100g.fat,
      ],
      [1300, 27, 282, 3],
    );
    expect(food.name('en'), 'أرز أبيض مطبوخ');
  });

  test('searches the server for the typed text', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'dev_subject': 'alice'});
    final searched = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/dev/token') {
        return http.Response('{"access_token":"token"}', 200);
      }
      searched.add(request.url.queryParameters['q']!);
      return http.Response(
        jsonEncode([
          {
            'id': 'rice',
            'name_ar': 'أرز أبيض مطبوخ',
            'name_en': 'Cooked white rice',
            'calories': 130.0,
            'protein': 2.7,
            'carbs': 28.2,
            'fat': 0.3,
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final session = AuthSession(
      ApiClient(client: client, baseUrl: 'https://backend.test'),
    );
    await session.restoreSignIn();

    final foods = await FoodsApi(session).search('أرز & rice');

    expect(searched, ['أرز & rice']);
    expect(foods.single.name('ar'), 'أرز أبيض مطبوخ');
  });

  group('the offline filter', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      for (final food in [
        _food('rice', 'أرز أبيض مطبوخ', 'Cooked white rice'),
        _food('labneh', 'لبنة', null),
        _food('oil', null, 'Olive oil 100%'),
      ]) {
        await database.storeFood(food);
      }
    });
    tearDown(() => database.close());

    Future<List<String>> ids(String query) async => [
      for (final food in await database.searchStoredFoods(query)) food.id,
    ];

    test('finds a food that contains the text in either name', () async {
      expect(await ids('أبيض'), ['rice']);
      expect(await ids('white'), ['rice']);
      expect(await ids('لبن'), ['labneh']);
    });

    test('ignores case', () async {
      expect(await ids('RICE'), ['rice']);
    });

    test('takes % and _ as plain text', () async {
      expect(await ids('0%'), ['oil']);
      expect(await ids('%'), ['oil']);
      expect(await ids('_'), isEmpty);
    });
  });
}
