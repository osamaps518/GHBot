import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/theme.dart';
import '../foods/food.dart';
import '../l10n/app_localizations.dart';
import 'amount_screen.dart';
import 'entry.dart';
import 'meal.dart';
import 'move_day_sheet.dart';

/// Changes a logged entry's grams or its day, or deletes it after asking.
/// The totals come from the entry's own values per 100 g (decision 21).
/// Both write to the phone's database, then close the screen, unless Back
/// closed it meanwhile.
class EntryEditScreen extends StatefulWidget {
  const EntryEditScreen({
    super.key,
    required this.database,
    required this.logged,
    required this.firstDay,
    required this.today,
  });

  final AppDatabase database;
  final LoggedFood logged;

  /// The earliest and latest days the entry can move to, `YYYY-MM-DD`.
  final String firstDay;
  final String today;

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  FoodLogEntry get _entry => widget.logged.entry;

  late final _grams = TextEditingController(text: formatTenths(_entry.grams));

  /// The day chosen in the move sheet, the entry's own until then.
  late var _day = _entry.diaryDay;

  /// Set once Save was tapped with grams the server would refuse.
  var _showError = false;
  var _saving = false;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  /// Saves the grams and the day that changed, both or neither.
  Future<void> _save() async {
    final grams = parseGrams(_grams.text);
    if (grams == null) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _saving = true);
    final database = widget.database;
    await database.transaction(() async {
      if (grams != _entry.grams) await database.changeGrams(_entry.id, grams);
      if (_day != _entry.diaryDay) await database.moveEntry(_entry.id, _day);
    });
    if (mounted && ModalRoute.of(context)!.isCurrent) Navigator.pop(context);
  }

  /// Opens the move sheet and keeps the day chosen there until Save.
  Future<void> _chooseDay() async {
    final l10n = AppLocalizations.of(context)!;
    final chosen = await showMoveDaySheet(
      context,
      day: _day,
      firstDay: widget.firstDay,
      today: widget.today,
      meal: DiaryMeal(_entry.meal, _entry.mealName).label(l10n),
    );
    if (chosen != null && mounted) setState(() => _day = chosen);
  }

  /// Asks first, then deletes the entry and closes.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _deleteDialog(context),
    );
    if (!(confirmed ?? false)) return;
    setState(() => _saving = true);
    await widget.database.deleteEntry(_entry.id);
    if (mounted && ModalRoute.of(context)!.isCurrent) Navigator.pop(context);
  }

  /// Names the food, its meal and day, and the calories that leave the
  /// day. Its text follows the dialog's own context, so it changes with the
  /// language while open.
  Widget _deleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return AlertDialog(
      title: Text(l10n.deleteEntryTitle(widget.logged.food.name(languageCode))),
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
          style: deleteButtonStyle(Theme.of(context)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }

  /// Save stays off until the grams or the day differ from the entry's.
  /// Like the amount step, Save sits below the scrolling part, so the
  /// keyboard doesn't cover it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grams = parseGrams(_grams.text);
    final changed = grams != _entry.grams || _day != _entry.diaryDay;
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
                  const SizedBox(height: 18),
                  _DayField(day: _day, onTap: _saving ? null : _chooseDay),
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

/// "Date" over the entry's [day], such as "Monday, November 23". Tapping
/// it opens the move sheet.
class _DayField extends StatelessWidget {
  const _DayField({required this.day, required this.onTap});

  /// `YYYY-MM-DD`.
  final String day;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(l10n.entryDate, style: theme.textTheme.titleSmall),
        OutlinedButton(
          style: dayFieldStyle(theme),
          onPressed: onTap,
          child: Row(
            spacing: 10,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 20),
              Expanded(child: Text(diaryDateText(l10n, day))),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
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
