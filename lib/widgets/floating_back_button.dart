import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Back affordance for fullscreen game pages, which have no app bar to host
/// one. Renders nothing when there is nothing to pop, so a game launched as the
/// root route does not show a dead button.
class FloatingBackButton extends StatelessWidget {
  const FloatingBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withAlpha(200),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context).commonBack,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
