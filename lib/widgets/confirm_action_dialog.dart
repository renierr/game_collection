import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Yes/no confirmation for a destructive action. Returns true when confirmed.
class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final bool destructive;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.destructive = true,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.commonConfirm),
        ),
      ],
    );
  }
}
