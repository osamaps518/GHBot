import 'package:flutter/material.dart';

import '../core/database.dart';
import '../foods/food.dart';
import '../l10n/app_localizations.dart';
import 'amount_screen.dart';
import 'entry.dart';

/// Changes a logged entry's grams. The totals come from the entry's own
/// values per 100 g (docs/decisions.md, 21). Saving writes to the phone's
/// database, then closes, unless Back closed the screen while it saved.
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
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
