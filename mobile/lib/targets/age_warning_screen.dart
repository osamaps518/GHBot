import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shown before the targets to users older than the calorie formula was
/// tested for.
class AgeWarningScreen extends StatelessWidget {
  const AgeWarningScreen({super.key, required this.onUnderstood});

  final VoidCallback onUnderstood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Scrolls when the phone's text size is large.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              spacing: 20,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                Text(
                  l10n.ageWarning,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: FilledButton(
            onPressed: onUnderstood,
            child: Text(l10n.understandButton),
          ),
        ),
      ),
    );
  }
}
