import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_failure.dart';
import '../core/database.dart';
import '../l10n/app_localizations.dart';
import 'food.dart';
import 'foods_api.dart';

/// What a search found for [query]. [offline] when the server couldn't be
/// reached and [foods] come from the phone; [failed] for any other failure.
typedef _Results = ({
  String query,
  List<Food> foods,
  bool offline,
  bool failed,
});

/// Finds a food to log. Before typing, it shows the recently logged foods.
/// Online, it searches the server about 300 ms after typing stops; without
/// a connection, it filters the foods kept on the phone. The last results
/// stay until the next ones arrive.
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.title,
    required this.database,
    required this.foodsApi,
    required this.onChosen,
  });

  final String title;
  final AppDatabase database;
  final FoodsApi foodsApi;

  /// Called with the chosen food and the grams (in tenths) to start with:
  /// the grams last logged for a recent food, otherwise 100 g.
  final void Function(Food food, int grams) onChosen;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _text = TextEditingController();
  late final _recentFoods = widget.database.watchRecentFoods();
  Timer? _waitForTyping;
  _Results? _results;

  /// Each change of the text takes a number. Only the answer for the latest
  /// number is shown, so an older search that answers late is dropped.
  int _latest = 0;

  @override
  void dispose() {
    _waitForTyping?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _waitForTyping?.cancel();
    final number = ++_latest;
    final query = text.trim();
    if (query.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() {});
    _waitForTyping = Timer(
      const Duration(milliseconds: 300),
      () => _search(query, number),
    );
  }

  Future<void> _search(String query, int number) async {
    var offline = false;
    var failed = false;
    var foods = const <Food>[];
    try {
      foods = await widget.foodsApi.search(query);
    } on ConnectionFailure {
      offline = true;
      foods = await widget.database.searchStoredFoods(query);
    } on ApiFailure {
      failed = true;
    }
    if (!mounted || number != _latest) return;
    setState(
      () => _results = (
        query: query,
        foods: foods,
        offline: offline,
        failed: failed,
      ),
    );
  }

  void _clear() {
    _text.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final typed = _text.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (results != null && results.offline) const _OfflineNote(),
          _SearchField(
            controller: _text,
            onChanged: _onChanged,
            onClear: _clear,
          ),
          const SizedBox(height: 12),
          if (!typed)
            _RecentFoods(foods: _recentFoods, onChosen: widget.onChosen)
          else if (results == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (results.failed)
            const _SearchFailed()
          else if (results.foods.isEmpty)
            _NoResults(query: results.query)
          else
            _FoundFoods(foods: results.foods, onChosen: widget.onChosen),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// The server takes queries of up to 100 characters.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.clearSearch,
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
      ),
    );
  }
}

/// Says the results come from the phone, and that other foods need a
/// connection (decision 20).
class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            spacing: 10,
            children: [
              Icon(Icons.wifi_off, color: muted),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.searchOffline,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The foods logged most recently, each with the amount it was last logged
/// with. Nothing shows before the first entry.
class _RecentFoods extends StatelessWidget {
  const _RecentFoods({required this.foods, required this.onChosen});

  final Stream<List<({Food food, int grams, int calories})>> foods;
  final void Function(Food food, int grams) onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: foods,
      builder: (context, snapshot) {
        final recent = snapshot.data ?? const [];
        if (recent.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              l10n.recentlyLogged,
              style: theme.textTheme.titleSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            _FoodList(
              tiles: [
                for (final (:food, :grams, :calories) in recent)
                  _FoodTile(
                    food: food,
                    detail: '${formatTenths(grams)} ${l10n.gramsUnit}',
                    calories: calories,
                    onTap: () => onChosen(food, grams),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The search results, with their calories per 100 g.
class _FoundFoods extends StatelessWidget {
  const _FoundFoods({required this.foods, required this.onChosen});

  final List<Food> foods;
  final void Function(Food food, int grams) onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _FoodList(
      tiles: [
        for (final food in foods)
          _FoodTile(
            food: food,
            detail: l10n.per100g,
            calories: food.per100g.calories,
            onTap: () => onChosen(food, 1000),
          ),
      ],
    );
  }
}

class _FoodList extends StatelessWidget {
  const _FoodList({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: tiles),
      ),
    );
  }
}

/// A food's name, a detail line, and calories in tenths.
class _FoodTile extends StatelessWidget {
  const _FoodTile({
    required this.food,
    required this.detail,
    required this.calories,
    required this.onTap,
  });

  final Food food;
  final String detail;
  final int calories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListTile(
      title: Text(food.name(Localizations.localeOf(context).languageCode)),
      subtitle: Text(detail),
      trailing: Text.rich(
        TextSpan(
          text: '${roundTenths(calories)}',
          style: theme.textTheme.titleSmall,
          children: [
            TextSpan(
              text: ' ${l10n.caloriesUnit}',
              style: theme.textTheme.bodySmall!.copyWith(color: muted),
            ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        spacing: 12,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(Icons.search_off, size: 32, color: muted),
          ),
          Text(
            l10n.noResultsTitle(query),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          Text(
            l10n.noResultsBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge!.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _SearchFailed extends StatelessWidget {
  const _SearchFailed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        AppLocalizations.of(context)!.errorGeneral,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
