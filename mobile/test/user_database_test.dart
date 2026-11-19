import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/core/database.dart';
import 'package:ghbot/profiles/profile.dart';
import 'package:ghbot/targets/targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'each user gets their own file in user_data/ under app support',
    () async {
      final support = Directory.systemTemp.createTempSync('ghbot_support_');
      final temporary = Directory.systemTemp.createTempSync('ghbot_temporary_');
      addTearDown(() {
        support.deleteSync(recursive: true);
        temporary.deleteSync(recursive: true);
      });
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        pathProvider,
        (call) async => switch (call.method) {
          'getApplicationSupportDirectory' => support.path,
          'getTemporaryDirectory' => temporary.path,
          _ => null,
        },
      );
      addTearDown(() => messenger.setMockMethodCallHandler(pathProvider, null));

      final alice = openUserDatabase('id-alice');
      await alice.storeProfileAndTargets(
        const Profile(
          birthYear: 1996,
          birthMonth: 3,
          sex: Sex.female,
          heightCm: 167.5,
          weightKg: 63.25,
          activityLevel: ActivityLevel.lightlyActive,
          goal: Goal.gain,
        ),
        const Targets(
          calories: 2210,
          proteinG: 176,
          fatG: 49,
          carbsG: 266,
          maintenanceCalories: 2760,
          atMinimum: false,
          aboveTestedAge: false,
          goal: Goal.gain,
          goalAdjustmentPercent: 10,
        ),
      );
      await alice.close();
      final bob = openUserDatabase('id-bob');
      expect(await bob.readProfileAndTargets(), isNull);
      await bob.close();
      final aliceAgain = openUserDatabase('id-alice');
      expect(await aliceAgain.readProfileAndTargets(), isNotNull);
      await aliceAgain.close();

      for (final id in ['id-alice', 'id-bob']) {
        expect(
          File('${support.path}/user_data/$id.sqlite').existsSync(),
          isTrue,
        );
      }
    },
  );
}
