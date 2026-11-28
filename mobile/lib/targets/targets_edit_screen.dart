import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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

  /// Checks the form, then saves.
  Future<void> _save() async {
    final draft = _draft;
    final values = draft.values;
    setState(() => _errors = draft.invalidFields);
    if (values == null) return;

    setState(() => _busy = true);
    try {
      await widget.onSave(values);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _error(AppLocalizations l10n, TargetsField field) => switch (field) {
    TargetsField.calories => l10n.errorCaloriesRange,
    TargetsField.protein => l10n.errorGramsRange('500'),
    TargetsField.carbs => l10n.errorGramsRange('1000'),
    TargetsField.fat => l10n.errorGramsRange('300'),
  };

  /// Save sits below the scrolling part, so the keyboard doesn't cover it.
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
                  if (draft.macroCalories case final calories?)
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
                    onPressed: _busy ? null : _save,
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

/// The calories the macros give.
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
