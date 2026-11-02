import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'api_failure.dart';

/// "Couldn't connect" with a Retry action. Used wherever the user submits
/// something, so what they typed stays on screen.
SnackBar connectionSnackBar(
  AppLocalizations l10n, {
  required VoidCallback onRetry,
}) => SnackBar(
  content: Row(
    spacing: 10,
    children: [
      // The snackbar colors its text but not icons.
      Builder(
        builder: (context) => Icon(
          Icons.wifi_off,
          color: DefaultTextStyle.of(context).style.color,
        ),
      ),
      Expanded(child: Text(l10n.errorConnection)),
    ],
  ),
  action: SnackBarAction(label: l10n.retry, onPressed: onRetry),
);

/// Startup failed: there's nothing cached to show, so the whole screen is
/// the error.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({required this.failure, required this.onRetry});

  final Exception failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connection = failure is ConnectionFailure;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Icon(
                connection ? Icons.wifi_off : Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Text(
                connection ? l10n.errorConnection : l10n.errorGeneral,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
