import 'package:flutter/material.dart';

import '../profiles/profile.dart';
import 'targets.dart';
import '../l10n/app_localizations.dart';
import '../core/theme.dart';

/// The daily calorie and macro targets. [profile] gives the goal for the
/// "How we calculated this" panel.
class TargetsScreen extends StatelessWidget {
  const TargetsScreen({
    super.key,
    required this.profile,
    required this.targets,
    required this.onEdit,
  });

  final Profile profile;
  final Targets targets;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = TargetsColors.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
          children: [
            Container(
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
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: colors.heroMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${targets.calories}',
                    style: theme.textTheme.displayLarge!.copyWith(
                      color: colors.heroNumber,
                    ),
                  ),
                  Text(
                    l10n.caloriesPerDay,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: colors.onHero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (targets.atMinimum) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Icon(Icons.info_outline, color: muted),
                      Expanded(child: Text(l10n.minimumNote)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
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
            ),
            const SizedBox(height: 12),
            Card(
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
                    label: l10n.goalRow(profile.goal.name),
                    value: l10n.goalAdjustment(profile.goal.name),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: OutlinedButton(
            onPressed: onEdit,
            child: Text(l10n.editMyInfo),
          ),
        ),
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
        Text(
          value,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
