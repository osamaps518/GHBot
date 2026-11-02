import 'package:flutter/material.dart';

import '../core/api_failure.dart';
import '../core/error_views.dart';
import '../l10n/app_localizations.dart';

/// Dev sign-in: the name is the account. Replaced when a real provider comes.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.onSubmit});

  final Future<void> Function(String name) onSubmit;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _name = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_name.text.trim());
    } on ApiFailure catch (failure) {
      messenger.showSnackBar(
        failure is ConnectionFailure
            ? connectionSnackBar(l10n, onRetry: _submit)
            : SnackBar(content: Text(l10n.errorGeneral)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final canSubmit = !_busy && _name.text.trim().isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          children: [
            Text(l10n.signInTitle, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              l10n.signInBody,
              style: text.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.signInName, style: text.titleSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => canSubmit ? _submit() : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Text(l10n.continueButton),
          ),
        ),
      ),
    );
  }
}
