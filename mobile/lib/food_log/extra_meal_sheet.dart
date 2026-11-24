import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'meal.dart';

/// Asks for an extra meal's name. Returns it trimmed, or null when the
/// trainee cancels.
///
/// `isScrollControlled` lets the sheet rise above the keyboard.
Future<String?> showExtraMealSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ExtraMealSheet(),
    );

class _ExtraMealSheet extends StatefulWidget {
  const _ExtraMealSheet();

  @override
  State<_ExtraMealSheet> createState() => _ExtraMealSheetState();
}

class _ExtraMealSheetState extends State<_ExtraMealSheet> {
  final _name = TextEditingController();

  /// Set once Add food was tapped with a name the server would refuse.
  var _showError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = extraMealName(_name.text);
    if (name == null) {
      setState(() => _showError = true);
    } else {
      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(l10n.addMeal, style: theme.appBarTheme.titleTextStyle),
          TextField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.extraMealName,
              helperText: l10n.extraMealHint,
              helperMaxLines: 2,
              errorText: _showError && extraMealName(_name.text) == null
                  ? l10n.errorMealName
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              FilledButton(onPressed: _submit, child: Text(l10n.addFood)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
