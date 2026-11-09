import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import 'targets.dart';

/// The daily calorie and macro targets.
class TargetsScreen extends StatelessWidget {
  const TargetsScreen({super.key, required this.targets, required this.onEdit});

  final Targets targets;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
          children: [
            _CaloriesHero(
              calories: targets.calories,
              aboveTestedAge: targets.aboveTestedAge,
            ),
            const SizedBox(height: 12),
            if (targets.atMinimum) ...[
              const _MinimumNote(),
              const SizedBox(height: 12),
            ],
            _MacroCards(targets),
            const SizedBox(height: 12),
            _HowWeCalculated(targets: targets),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: OutlinedButton(
            onPressed: onEdit,
            child: Text(AppLocalizations.of(context)!.editMyInfo),
          ),
        ),
      ),
    );
  }
}

/// The day's calories, large, on the colored card at the top.
class _CaloriesHero extends StatelessWidget {
  const _CaloriesHero({required this.calories, required this.aboveTestedAge});

  final int calories;
  final bool aboveTestedAge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = TargetsColors.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 24, 22, 26),
      decoration: BoxDecoration(
        color: colors.heroBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.targetsTitle,
            style: text.titleMedium!.copyWith(color: colors.heroMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '$calories',
                    style: text.displayLarge!.copyWith(
                      color: colors.heroNumber,
                    ),
                  ),
                ),
              ),
              if (aboveTestedAge)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Tooltip(
                    message: l10n.ageWarning,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: colors.heroNumber,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            l10n.caloriesPerDay,
            style: text.titleMedium!.copyWith(color: colors.onHero),
          ),
        ],
      ),
    );
  }
}

/// Says the target was raised to the safe minimum.
class _MinimumNote extends StatelessWidget {
  const _MinimumNote();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Expanded(child: Text(AppLocalizations.of(context)!.minimumNote)),
          ],
        ),
      ),
    );
  }
}

/// Protein, carbs and fat side by side.
class _MacroCards extends StatelessWidget {
  const _MacroCards(this.targets);

  final Targets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = TargetsColors.of(context);
    return Row(
      spacing: 8,
      children: [
        for (final (name, grams, caloriesPerGram, color) in [
          (l10n.protein, targets.proteinG, 4, colors.protein),
          (l10n.carbs, targets.carbsG, 4, colors.carbs),
          (l10n.fat, targets.fatG, 9, colors.fat),
        ])
          Expanded(
            child: _MacroCard(
              name: name,
              grams: grams,
              share: grams * caloriesPerGram / targets.calories,
              color: color,
            ),
          ),
      ],
    );
  }
}

/// The "How we calculated this" panel: maintenance calories and the goal's
/// adjustment.
class _HowWeCalculated extends StatelessWidget {
  const _HowWeCalculated({required this.targets});

  final Targets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(l10n.howWeCalculated),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        children: [
          _Row(
            label: l10n.maintenanceCalories,
            value: '${targets.maintenanceCalories}',
          ),
          const SizedBox(height: 8),
          _Row(
            label: l10n.goalRow(targets.goal.name),
            value: l10n.goalAdjustment(
              targets.goal.name,
              '${targets.goalAdjustmentPercent.abs()}',
            ),
          ),
          if (targets.atMinimum) ...[
            const SizedBox(height: 8),
            _Row(label: l10n.raisedToMinimum, value: '${targets.calories}'),
          ],
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.name,
    required this.grams,
    required this.share,
    required this.color,
  });

  final String name;
  final int grams;

  /// The macro's share of the day's calories, 0 to 1.
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              name,
              style: theme.textTheme.bodyMedium!.copyWith(color: muted),
            ),
            Text.rich(
              TextSpan(
                text: '$grams',
                style: theme.textTheme.headlineSmall,
                children: [
                  TextSpan(
                    text: ' ${l10n.gramsUnit}',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: share, color: color),
            Text(
              l10n.shareOfCalories('${(share * 100).round()}'),
              style: theme.textTheme.bodySmall!.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: targetsRowValueStyle(theme)),
      ],
    );
  }
}
