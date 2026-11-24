import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/theme.dart';
import '../foods/food.dart';
import '../l10n/app_localizations.dart';
import 'entry.dart';
import 'meal.dart';

/// The amount step: grams, the totals they give, and the meal. Adding saves
/// the entry on the phone and closes with `true`.
class AmountScreen extends StatefulWidget {
  const AmountScreen({
    super.key,
    required this.database,
    required this.food,
    required this.grams,
    required this.meal,
    required this.meals,
  });

  final AppDatabase database;
  final Food food;

  /// The grams to start with, in tenths.
  final int grams;

  /// The meal chosen at first, one of [meals].
  final DiaryMeal meal;

  /// The day's meals, in the diary's order.
  final List<DiaryMeal> meals;

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  late final _grams = TextEditingController(text: formatTenths(widget.grams));
  late var _meal = widget.meal;

  /// Set once Add was tapped with grams the server would refuse.
  var _showError = false;
  var _saving = false;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  /// Changes the grams by [tenths], or returns null when that would leave
  /// them invalid.
  VoidCallback? _step(int tenths) {
    final grams = parseGrams(_grams.text);
    if (grams == null) return null;
    final changed = grams + tenths;
    if (changed <= 0 || changed > 50000) return null;
    return () => setState(() => _grams.text = formatTenths(changed));
  }

  Future<void> _log() async {
    final grams = parseGrams(_grams.text);
    if (grams == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    await widget.database.logEntry(
      food: widget.food,
      meal: _meal,
      grams: grams,
      loggedAt: DateTime.now(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  /// The Add button sits below the scrolling part, not in
  /// `bottomNavigationBar`, so the keyboard doesn't cover it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grams = parseGrams(_grams.text);
    return Scaffold(
      appBar: AppBar(title: _FoodHeading(food: widget.food)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _GramsField(
                    controller: _grams,
                    showError: _showError && grams == null,
                    onChanged: (_) => setState(() {}),
                    onLess: _step(-100),
                    onMore: _step(100),
                  ),
                  const SizedBox(height: 18),
                  _TotalsPreview(
                    totals: entryTotals(widget.food.per100g, grams ?? 0),
                  ),
                  const SizedBox(height: 18),
                  _MealPicker(
                    meals: widget.meals,
                    chosen: _meal,
                    onChosen: (meal) => setState(() => _meal = meal),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _log,
                  child: Text(l10n.logButton(_meal.label(l10n))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The food's name and its calories per 100 g.
class _FoodHeading extends StatelessWidget {
  const _FoodHeading({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(food.name(Localizations.localeOf(context).languageCode)),
        Text(
          AppLocalizations.of(context)!
              .caloriesPer100g('${roundTenths(food.per100g.calories)}'),
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The grams field between the − and + buttons.
class _GramsField extends StatelessWidget {
  const _GramsField({
    required this.controller,
    required this.showError,
    required this.onChanged,
    required this.onLess,
    required this.onMore,
  });

  final TextEditingController controller;
  final bool showError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(l10n.amount, style: theme.textTheme.titleSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            IconButton(
              tooltip: l10n.less,
              style: stepButtonStyle(theme),
              icon: const Icon(Icons.remove),
              onPressed: onLess,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall!.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                onChanged: onChanged,
                decoration: InputDecoration(
                  suffixText: l10n.gramsUnit,
                  errorText: showError ? l10n.errorGrams : null,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.more,
              style: stepButtonStyle(theme),
              icon: const Icon(Icons.add),
              onPressed: onMore,
            ),
          ],
        ),
      ],
    );
  }
}

/// The entry's calories and macros for the grams typed, rounded to whole
/// numbers.
class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({required this.totals});

  final Nutrients totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final colors = TargetsColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          spacing: 24,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 6,
              children: [
                Text(
                  '${roundTenths(totals.calories)}',
                  style: theme.textTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.caloriesUnit,
                  style: theme.textTheme.bodyLarge!.copyWith(color: muted),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                for (final (name, tenths, color) in [
                  (l10n.protein, totals.protein, colors.protein),
                  (l10n.carbs, totals.carbs, colors.carbs),
                  (l10n.fat, totals.fat, colors.fat),
                ])
                  Expanded(
                    child: Column(
                      spacing: 4,
                      children: [
                        Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Text(
                          name,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: muted,
                          ),
                        ),
                        Text(
                          '${roundTenths(tenths)} ${l10n.gramsUnit}',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The day's meals as chips; the chosen one is filled.
class _MealPicker extends StatelessWidget {
  const _MealPicker({
    required this.meals,
    required this.chosen,
    required this.onChosen,
  });

  final List<DiaryMeal> meals;
  final DiaryMeal chosen;
  final ValueChanged<DiaryMeal> onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(l10n.meal, style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final meal in meals)
              ChoiceChip(
                label: Text(meal.label(l10n)),
                selected: meal == chosen,
                onSelected: (_) => onChosen(meal),
              ),
          ],
        ),
      ],
    );
  }
}
