import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghbot/l10n/app_localizations.dart';

import 'fake_backend.dart';

final english = lookupAppLocalizations(const Locale('en'));

/// The custom targets from the #51 mockup: 2400 kcal, whose macros give
/// 4 × 160 + 4 × 296 + 9 × 64 = 2400 kcal, over [exampleTargets] as the
/// recommended ones.
final customTargets = {
  ...exampleTargets,
  'calories': 2400,
  'protein_g': 160,
  'fat_g': 64,
  'carbs_g': 296,
  'custom': true,
};

void main() {
  testWidgets('custom targets show as custom, with the recommended calories '
      'and how those were calculated', (tester) async {
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..targets = customTargets;

    await pumpApp(tester, backend, storedName: 'alice');
    await openTargets(tester);

    expect(find.text('2400'), findsOneWidget);
    expect(find.text(english.customBadge), findsOneWidget);
    expect(find.text(english.customTargetsNote('2210')), findsOneWidget);
    expect(find.text(english.howWeCalculatedRecommended), findsOneWidget);
    expect(find.text(english.howWeCalculated), findsNothing);
  });

  testWidgets('custom targets raised to the minimum say their macros were '
      'adjusted, not that the recommended ones were raised', (tester) async {
    final backend = FakeBackend()
      ..profile = savedProfile()
      ..targets = {
        ...customTargets,
        'calories': 1500,
        'protein_g': 128,
        'fat_g': 34,
        'carbs_g': 164,
        'at_minimum': true,
        'macros_adjusted': true,
      };

    await pumpApp(tester, backend, storedName: 'alice');
    await openTargets(tester);

    expect(find.text(english.macrosAdjustedNote), findsOneWidget);
    expect(find.text(english.minimumNote), findsNothing);
    expect(find.text(english.raisedToMinimum), findsNothing);
  });
}
