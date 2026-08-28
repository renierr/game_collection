import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// The overview's settings entry point. Each row leads to a full page rather
/// than nesting controls in a sheet, so the same screens work on a phone and in
/// a desktop window.
class OverviewSettingsDialog extends StatelessWidget {
  const OverviewSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const OverviewSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.settingsDialogTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.appearanceTitle),
                subtitle: Text(l10n.settingsDialogAppearanceSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/appearance-settings');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sports_esports_outlined),
                title: Text(l10n.gameplayTitle),
                subtitle: Text(l10n.settingsDialogGameplaySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/gameplay-settings');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutTitle),
                subtitle: Text(l10n.settingsDialogAboutSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/about');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
