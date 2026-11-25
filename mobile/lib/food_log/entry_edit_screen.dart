import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/theme.dart';
import '../foods/food.dart';
import '../l10n/app_localizations.dart';
import 'amount_screen.dart';
import 'entry.dart';
import 'meal.dart';

/// Changes a logged entry's grams, or deletes it after asking. The totals
/// come from the entry's own values per 100 g (docs/decisions.md, 21).
/// Both write to the phone's database, then close the screen, unless Back
/// closed it meanwhile.
class EntryEditScreen extends StatefulWidget {
  const EntryEditScreen({
    super.key,
    required this.database,
    required this.logged,
  });

  final AppDatabase database;
  final LoggedFood logged;

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  FoodLogEntry get _entry => widget.logged.entry;

  late final _grams = TextEditingController(text: formatTenths(_entry.grams));

  /// Set once Save was tapped with grams the server would refuse.
  var _showError = false;
  var _saving = false;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final grams = parseGrams(_grams.text);
    if (grams == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    await widget.database.changeGrams(_entry.id, grams);
    if (mounted && ModalRoute.of(context)!.isCurrent) Navigator.pop(context);
  }

  /// Asks first, then deletes the entry and closes.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deleteEntryTitle(widget.logged.food.name(languageCode)),
        ),
        content: Text(
          l10n.deleteEntryBody(
            DiaryMeal(_entry.meal, _entry.mealName).label(l10n),
            diaryDateText(l10n, _entry.diaryDay),
            '${roundTenths(_entry.totals.calories)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: deleteButtonStyle(theme),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    setState(() => _saving = true);
    await widget.database.deleteEntry(_entry.id);
    if (mounted && ModalRoute.of(context)!.isCurrent) Navigator.pop(context);
  }

  /// Save stays off until the grams differ from the entry's. Like the
  /// amount step, Save sits below the scrolling part, so the keyboard
  /// doesn't cover it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grams = parseGrams(_grams.text);
    final changed = grams != _entry.grams;
    return Scaffold(
      appBar: AppBar(
        title: FoodHeading(food: widget.logged.food, per100g: _entry.per100g),
        actions: [
          TextButton.icon(
            style: deleteButtonStyle(Theme.of(context)),
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (_entry.refused) ...[
                    const _RefusedAlert(),
                    const SizedBox(height: 18),
                  ],
                  GramsField(
                    controller: _grams,
                    showError: _showError && grams == null,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  TotalsPreview(
                    totals: entryTotals(_entry.per100g, grams ?? 0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: changed && !_saving ? _save : null,
                  child: Text(l10n.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why a refused entry is open: the server didn't accept it, so it is only
/// on the phone until the trainee changes or deletes it.
class _RefusedAlert extends StatelessWidget {
  const _RefusedAlert();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Icon(Icons.error_outline, size: 20, color: colors.error),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.entryRefusedAlert,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
