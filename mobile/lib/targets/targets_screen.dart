import 'package:flutter/material.dart';

import '../core/api_failure.dart';
import '../core/error_views.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import 'choice_dialog.dart';
import 'targets.dart';

/// The daily calorie and macro targets, opened from the diary. [onEdit]
/// opens Edit my info, [onEditTargets] the targets form, and [onReset]
/// goes back from custom targets to the recommended ones.
///
/// The screen has its own snackbars, so a failed reset's Retry goes when it
/// closes.
class TargetsScreen extends StatelessWidget {
  const TargetsScreen({
    super.key,
    required this.targets,
    required this.onEdit,
    required this.onEditTargets,
    required this.onReset,
  });

  final Targets targets;
  final VoidCallback onEdit;
  final VoidCallback onEditTargets;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.targetsTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _CaloriesHero(targets: targets, onEditTargets: onEditTargets),
              const SizedBox(height: 12),
              if (targets.atMinimum) ...[
                _MinimumNote(macrosAdjusted: targets.macrosAdjusted),
                const SizedBox(height: 12),
              ],
              _MacroCards(targets),
              const SizedBox(height: 12),
              if (targets.custom) ...[
                _CustomNote(targets: targets, onReset: onReset),
                const SizedBox(height: 12),
              ],
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
      ),
    );
  }
}

/// The day's calories, large, on the colored card at the top, marked when
/// they are custom, with the link to change them.
class _CaloriesHero extends StatelessWidget {
  const _CaloriesHero({required this.targets, required this.onEditTargets});

  final Targets targets;
  final VoidCallback onEditTargets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = TargetsColors.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 22, 22, 8),
      decoration: BoxDecoration(
        color: colors.heroBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${targets.calories}',
                          style: text.displayLarge!.copyWith(
                            color: colors.heroNumber,
                          ),
                        ),
                      ),
                    ),
                    if (targets.aboveTestedAge)
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
              ),
              if (targets.custom) const _CustomBadge(),
            ],
          ),
          Text(
            l10n.caloriesPerDay,
            style: text.titleMedium!.copyWith(color: colors.onHero),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            style: heroLinkStyle(colors),
            onPressed: onEditTargets,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.editTargets),
          ),
        ],
      ),
    );
  }
}

/// The "Custom" pill beside the calories.
class _CustomBadge extends StatelessWidget {
  const _CustomBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.colorScheme.primary,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Text(
          AppLocalizations.of(context)!.customBadge,
          style: theme.textTheme.labelLarge!.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Says the target was raised to the safe minimum. For custom targets the
/// server adjusted the macros too ([macrosAdjusted]).
class _MinimumNote extends StatelessWidget {
  const _MinimumNote({required this.macrosAdjusted});

  final bool macrosAdjusted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Expanded(
              child: Text(
                macrosAdjusted ? l10n.macrosAdjustedNote : l10n.minimumNote,
              ),
            ),
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

/// Says the trainee set these targets, which stay when the profile changes,
/// and what the recommended calories are now, with the way back to them.
class _CustomNote extends StatefulWidget {
  const _CustomNote({required this.targets, required this.onReset});

  final Targets targets;
  final Future<void> Function() onReset;

  @override
  State<_CustomNote> createState() => _CustomNoteState();
}

class _CustomNoteState extends State<_CustomNote> {
  var _busy = false;

  /// Asks first, then goes back to the recommended targets.
  Future<void> _confirmReset() async {
    final targets = widget.targets;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return ChoiceDialog(
          title: l10n.resetTitle,
          body: l10n.resetBody(
            '${targets.recommendedCalories}',
            '${targets.recommendedProteinG}',
            '${targets.recommendedCarbsG}',
            '${targets.recommendedFatG}',
          ),
          confirm: l10n.backToRecommended,
          cancel: l10n.cancel,
        );
      },
    );
    if ((confirmed ?? false) && mounted) await _reset();
  }

  /// Resets on the server. Once it's done, this card goes with the custom
  /// targets. Offline, nothing changes and Retry tries again without asking,
  /// unless a refresh took the custom targets away meanwhile.
  Future<void> _reset() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    setState(() => _busy = true);
    try {
      await widget.onReset();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      messenger.showSnackBar(
        failure is ConnectionFailure
            ? connectionSnackBar(l10n, onRetry: _reset)
            : SnackBar(content: Text(l10n.errorGeneral)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              l10n.customTargetsNote('${widget.targets.recommendedCalories}'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _confirmReset,
              child: Text(l10n.backToRecommended),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "How we calculated this" panel: maintenance calories and the goal's
/// adjustment, for the recommended targets. The raise to the minimum shows
/// only when the recommended targets are in effect: for custom ones,
/// [Targets.atMinimum] is about the custom calories.
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
        title: Text(
          targets.custom
              ? l10n.howWeCalculatedRecommended
              : l10n.howWeCalculated,
        ),
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
          if (targets.atMinimum && !targets.custom) ...[
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
