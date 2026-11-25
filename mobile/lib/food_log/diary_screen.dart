import 'dart:async';

import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/theme.dart';
import '../foods/food.dart';
import '../foods/food_search_screen.dart';
import '../foods/foods_api.dart';
import '../l10n/app_localizations.dart';
import '../targets/targets.dart';
import 'amount_screen.dart';
import 'entry.dart';
import 'entry_edit_screen.dart';
import 'extra_meal_sheet.dart';
import 'meal.dart';

/// The home screen: today's entries under their meals, and the day's
/// calories and macros next to the targets. It reads only from the phone's
/// database and updates whenever an entry is saved (docs/decisions.md, 32).
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({
    super.key,
    required this.database,
    required this.foodsApi,
    required this.targets,
    required this.onOpenTargets,
  });

  final AppDatabase database;
  final FoodsApi foodsApi;
  final Targets targets;
  final VoidCallback onOpenTargets;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late String _day;
  late Stream<List<LoggedFood>> _entries;

  /// How many entries, on any day, wait to be sent.
  late final _unsentCount = widget.database.watchUnsentCount();

  /// Extra meals named on this screen today. They show until the screen
  /// closes; one stays on the day only through its entries.
  final _newMealNames = <String>[];

  /// Moves the diary to the next day when it starts, if the app is open then.
  Timer? _nextDay;

  @override
  void initState() {
    super.initState();
    _showToday();
  }

  @override
  void dispose() {
    _nextDay?.cancel();
    super.dispose();
  }

  void _showToday() {
    final now = DateTime.now();
    _day = diaryDayOf(now);
    _newMealNames.clear();
    _entries = widget.database.watchDiaryDay(_day);
    _nextDay = Timer(
      nextDayStart(now).difference(now),
      () => setState(_showToday),
    );
  }

  /// Opens search for [meal], then the amount step for the chosen food.
  /// After the entry is saved, both close and the diary shows it.
  void _addFood(DiaryMeal meal, List<DiaryMeal> meals) {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => FoodSearchScreen(
          title: l10n.searchTitle(meal.label(l10n)),
          database: widget.database,
          foodsApi: widget.foodsApi,
          onChosen: (food, grams) async {
            final logged = await navigator.push<bool>(
              MaterialPageRoute(
                builder: (_) => AmountScreen(
                  database: widget.database,
                  food: food,
                  grams: grams,
                  meal: meal,
                  meals: meals,
                ),
              ),
            );
            if (logged ?? false) navigator.pop();
          },
        ),
      ),
    );
  }

  /// Opens [logged] to change or delete it.
  void _openEntry(LoggedFood logged) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EntryEditScreen(database: widget.database, logged: logged),
      ),
    );
  }

  /// Asks for an extra meal's name, shows the meal, and opens search for it.
  /// [entries] are the day's, to list the meals the amount step offers.
  Future<void> _addMeal(List<LoggedFood> entries) async {
    final name = await showExtraMealSheet(context);
    if (name == null || !mounted) return;
    setState(() {
      if (!_newMealNames.contains(name)) _newMealNames.add(name);
    });
    final meals = groupByMeal(entries, newMealNames: _newMealNames);
    _addFood(DiaryMeal(Meal.extra, name), [
      for (final group in meals) group.meal,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: _entries,
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const [];
            final meals = groupByMeal(entries, newMealNames: _newMealNames);
            final dayTotals = Nutrients.sum(
              entries.map((logged) => logged.entry.totals),
            );
            final mealKeys = [for (final group in meals) group.meal];
            final refused = entries
                .where((logged) => logged.entry.refused)
                .length;
            final colors = Theme.of(context).colorScheme;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                _DayHeader(day: _day),
                _WaitingNote(count: _unsentCount),
                if (refused > 0)
                  _Note(
                    icon: Icons.error_outline,
                    text: l10n.refusedNote(refused),
                    background: colors.errorContainer,
                    foreground: colors.error,
                  ),
                const SizedBox(height: 12),
                _CaloriesCard(
                  eaten: roundTenths(dayTotals.calories),
                  target: widget.targets.calories,
                  onOpenTargets: widget.onOpenTargets,
                ),
                const SizedBox(height: 12),
                _MacroCards(totals: dayTotals, targets: widget.targets),
                for (final group in meals) ...[
                  const SizedBox(height: 12),
                  _MealCard(
                    group: group,
                    onAddFood: () => _addFood(group.meal, mealKeys),
                    onOpen: _openEntry,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _addMeal(entries),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addMeal),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Today" and the date, such as "Monday, November 23".
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  /// `YYYY-MM-DD`.
  final String day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(l10n.today, style: theme.appBarTheme.titleTextStyle),
        Text(
          diaryDateText(l10n, day),
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "3 entries are waiting to sync", while [count] is above 0.
class _WaitingNote extends StatelessWidget {
  const _WaitingNote({required this.count});

  final Stream<int> count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: count,
      builder: (context, snapshot) {
        final waiting = snapshot.data ?? 0;
        if (waiting == 0) return const SizedBox.shrink();
        return _Note(
          icon: Icons.schedule,
          text: AppLocalizations.of(context)!.waitingToSync(waiting),
          background: colors.surfaceContainer,
          foreground: colors.onSurfaceVariant,
        );
      },
    );
  }
}

/// A sentence about the diary's state, with its icon, in a rounded box
/// under the day.
class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            spacing: 10,
            children: [
              Icon(icon, size: 20, color: foreground),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ring of calories left today, then what was eaten of the target and
/// the way to the targets screen.
class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.eaten,
    required this.target,
    required this.onOpenTargets,
  });

  final int eaten;
  final int target;
  final VoidCallback onOpenTargets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 22, 10, 8),
        child: Column(
          spacing: 12,
          children: [
            _CaloriesRing(eaten: eaten, target: target),
            Divider(
              color: theme.colorScheme.surfaceContainerHighest,
              endIndent: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: _EatenOfTarget(eaten: eaten, target: target),
                ),
                TextButton(
                  onPressed: onOpenTargets,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.targetsButton),
                      const Icon(Icons.chevron_right),
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

/// Fills as calories are eaten, from the top, in the reading direction. In
/// the middle: the calories left, or how far over the target the day is.
class _CaloriesRing extends StatelessWidget {
  const _CaloriesRing({required this.eaten, required this.target});

  final int eaten;
  final int target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final left = target - eaten;
    return SizedBox.square(
      dimension: 208,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: CircularProgressIndicator(
                value: (eaten / target).clamp(0, 1),
                strokeWidth: 16,
                strokeCap: StrokeCap.round,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${left.abs()}',
                style: theme.textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                left < 0 ? l10n.caloriesOver : l10n.caloriesLeft,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "You've eaten 1156 of 2210 kcal", with the eaten number in bold.
///
/// The sentence comes whole from the translations, so the number is found by
/// building it once with a marker in its place.
class _EatenOfTarget extends StatelessWidget {
  const _EatenOfTarget({required this.eaten, required this.target});

  final int eaten;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final [before, after] = AppLocalizations.of(context)!
        .eatenOfTarget('\u0000', '$target')
        .split('\u0000');
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: '$eaten',
            style: targetsRowValueStyle(theme)
                .copyWith(fontSize: theme.textTheme.bodyMedium!.fontSize),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

/// Protein, carbs and fat eaten today, each next to its target.
class _MacroCards extends StatelessWidget {
  const _MacroCards({required this.totals, required this.targets});

  final Nutrients totals;
  final Targets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = TargetsColors.of(context);
    return Row(
      spacing: 8,
      children: [
        for (final (name, eaten, target, color) in [
          (l10n.protein, totals.protein, targets.proteinG, colors.protein),
          (l10n.carbs, totals.carbs, targets.carbsG, colors.carbs),
          (l10n.fat, totals.fat, targets.fatG, colors.fat),
        ])
          Expanded(
            child: _MacroCard(
              name: name,
              eaten: roundTenths(eaten),
              target: target,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.name,
    required this.eaten,
    required this.target,
    required this.color,
  });

  final String name;
  final int eaten;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              name,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text('$eaten', style: theme.textTheme.headlineSmall),
            Text(l10n.macroOfTarget('$target'), style: muted),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (eaten / target).clamp(0, 1),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// A meal's name and calories, its entries, and Add food. Tapping an entry
/// opens it.
class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.group,
    required this.onAddFood,
    required this.onOpen,
  });

  final MealGroup group;
  final VoidCallback onAddFood;
  final ValueChanged<LoggedFood> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.meal.label(l10n),
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (group.entries.isNotEmpty)
                    Text(
                      '${roundTenths(group.totals.calories)} '
                      '${l10n.caloriesUnit}',
                      style: theme.textTheme.bodyMedium!.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            for (final logged in group.entries)
              _EntryTile(logged: logged, onTap: () => onOpen(logged)),
            if (group.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: Text(
                  l10n.noEntries,
                  style: theme.textTheme.bodyMedium!.copyWith(color: muted),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: onAddFood,
                icon: const Icon(Icons.add),
                label: Text(l10n.addFood),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An entry's food, grams and calories. One waiting to sync has a clock by
/// its calories. One the server refused is tinted and says so in place of
/// its grams, with an error mark.
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.logged, required this.onTap});

  final LoggedFood logged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entry = logged.entry;
    final languageCode = Localizations.localeOf(context).languageCode;
    final tile = ListTile(
      onTap: onTap,
      tileColor: entry.refused ? colors.errorContainer : null,
      shape: entry.refused
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
          : null,
      contentPadding: entry.refused
          ? const EdgeInsets.symmetric(horizontal: 10)
          : null,
      title: Text(logged.food.name(languageCode)),
      subtitle: entry.refused
          ? Text(
              l10n.entryRefused,
              style: theme.textTheme.bodyMedium!.copyWith(color: colors.error),
            )
          : Text('${formatTenths(entry.grams)} ${l10n.gramsUnit}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (entry.refused)
            Icon(Icons.error_outline, size: 18, color: colors.error)
          else if (entry.unsent)
            Icon(
              Icons.schedule,
              size: 16,
              color: colors.onSurfaceVariant,
              semanticLabel: l10n.waitingToSyncEntry,
            ),
          Text(
            '${roundTenths(entry.totals.calories)}',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
    return entry.refused
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: tile,
          )
        : tile;
  }
}
