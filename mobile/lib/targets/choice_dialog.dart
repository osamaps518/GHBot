import 'package:flutter/material.dart';

/// A question with two answers stacked under it, as in the #51 mockups:
/// [confirm] filled, [cancel] as text. It pops true for [confirm] and false
/// for [cancel]. Callers read the texts in the dialog's own builder, so they
/// follow the language while it's open.
class ChoiceDialog extends StatelessWidget {
  const ChoiceDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirm,
    required this.cancel,
  });

  final String title;
  final String body;
  final String confirm;
  final String cancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancel),
            ),
          ],
        ),
      ],
    );
  }
}
