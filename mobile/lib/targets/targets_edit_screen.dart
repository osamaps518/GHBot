import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'choice_dialog.dart';
import 'targets.dart';

/// The form for custom targets, opened on the targets in effect. It checks
/// the numbers like the server ([TargetsDraft]), then saves through
/// [onSave], which needs internet (docs/decisions.md, 37).
class TargetsEditScreen extends StatefulWidget {
  const TargetsEditScreen({
    super.key,
    required this.targets,
    required this.onSave,
  });

  final Targets targets;
  final Future<void> Function(TargetValues values) onSave;

  @override
  State<TargetsEditScreen> createState() => _TargetsEditScreenState();
}

class _TargetsEditScreenState extends State<TargetsEditScreen> {
  late final _controllers = {
    for (final (field, value) in [
      (TargetsField.calories, widget.targets.calories),
      (TargetsField.protein, widget.targets.proteinG),
      (TargetsField.carbs, widget.targets.carbsG),
      (TargetsField.fat, widget.targets.fatG),
    ])
      field: TextEditingController(text: '$value'),
  };

  /// The fields shown as wrong: set when Save is tapped, cleared for a field
  /// when it changes.
  var _errors = <TargetsField>{};
  var _busy = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TargetsDraft get _draft => TargetsDraft.parse(
    calories: _controllers[TargetsField.calories]!.text,
    protein: _controllers[TargetsField.protein]!.text,
    carbs: _controllers[TargetsField.carbs]!.text,
    fat: _controllers[TargetsField.fat]!.text,
  );

  void _changed(TargetsField field) => setState(() => _errors.remove(field));

  /// Checks the form, asks first when the macros don't quite give the
  /// calories, then saves.
  Future<void> _save() async {
    final draft = _draft;
    final values = draft.values;
    setState(() => _errors = draft.invalidFields);
    if (values == null) return;
    if (draft.difference != 0 && !await _keepAnyway(draft)) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await widget.onSave(values);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shows how far apart the numbers are. True when the trainee keeps them.
  Future<bool> _keepAnyway(TargetsDraft draft) async {
    final keep = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return ChoiceDialog(
          title: l10n.macrosApartTitle('${draft.difference}'),
          body: l10n.macrosApartBody(
            '${draft.calories}',
            '${draft.macroCalories}',
          ),
          confirm: l10n.keepNumbers,
          cancel: l10n.fixNumbers,
        );
      },
    );
    return keep ?? false;
  }

  String _error(AppLocalizations l10n, TargetsField field) => switch (field) {
    TargetsField.calories => l10n.errorCaloriesRange,
    TargetsField.protein => l10n.errorGramsRange('500'),
    TargetsField.carbs => l10n.errorGramsRange('1000'),
    TargetsField.fat => l10n.errorGramsRange('300'),
  };

  /// Save stays off while the macros are 100 kcal or more from the
  /// calories. It sits below the scrolling part, so the keyboard doesn't
  /// cover it.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = _draft;
    final recommended = {
      TargetsField.calories: widget.targets.recommendedCalories,
      TargetsField.protein: widget.targets.recommendedProteinG,
      TargetsField.carbs: widget.targets.recommendedCarbsG,
      TargetsField.fat: widget.targets.recommendedFatG,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTargets)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final field in TargetsField.values) ...[
                    _TargetField(
                      field: field,
                      controller: _controllers[field]!,
                      helper: l10n.recommendedValue(
                        field.name,
                        '${recommended[field]}',
                      ),
                      error: _errors.contains(field)
                          ? _error(l10n, field)
                          : null,
                      onChanged: () => _changed(field),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (draft.macrosTooFar)
                    _MacrosTooFarAlert(
                      macroCalories: draft.macroCalories!,
                      difference: draft.difference!,
                    )
                  else if (draft.macroCalories case final calories?)
                    _MacroCaloriesLine(calories: calories),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(
                    l10n.saveNeedsInternet,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || draft.macrosTooFar ? null : _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One target: its name and recommended value (or its error) at the start,
/// the number field at the end.
class _TargetField extends StatelessWidget {
  const _TargetField({
    required this.field,
    required this.controller,
    required this.helper,
    required this.error,
    required this.onChanged,
  });

  final TargetsField field;
  final TextEditingController controller;
  final String helper;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                l10n.targetsFieldLabel(field.name),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: error == null ? null : colors.error,
                ),
              ),
              Text(
                error ?? helper,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: error == null ? colors.onSurfaceVariant : colors.error,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 132,
          child: TextField(
            key: ValueKey(field.name),
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              suffixText: field == TargetsField.calories
                  ? l10n.caloriesUnit
                  : l10n.gramsUnit,
              error: error == null ? null : const SizedBox.shrink(),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

/// The calories the macros give, while they're under 100 kcal from the
/// calories.
class _MacroCaloriesLine extends StatelessWidget {
  const _MacroCaloriesLine({required this.calories});

  final int calories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      spacing: 8,
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: muted),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.macroCaloriesLine('$calories'),
            style: theme.textTheme.bodyMedium!.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// Why Save is off: the macros are 100 kcal or more from the calories.
class _MacrosTooFarAlert extends StatelessWidget {
  const _MacrosTooFarAlert({
    required this.macroCalories,
    required this.difference,
  });

  final int macroCalories;
  final int difference;

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
                AppLocalizations.of(context)!
                    .macrosTooFar('$macroCalories', '$difference'),
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
