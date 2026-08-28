import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/readable_width.dart';

/// Settings that affect how games behave rather than how the app looks: audio,
/// the screen wake lock, haptics, and the destructive full data reset.
class GameplaySettingsPage extends StatelessWidget {
  const GameplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameplayTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      appState.soundEnabled
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsSound),
                    subtitle: Text(l10n.settingsSoundSubtitle),
                    value: appState.soundEnabled,
                    onChanged: appState.setSoundEnabled,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.graphic_eq,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsVolume),
                    subtitle: Slider(
                      value: appState.masterVolume,
                      // The slider stays live while muted so the level can be
                      // set before unmuting, rather than needing two trips.
                      onChanged: appState.setMasterVolume,
                      divisions: 20,
                      label: '${(appState.masterVolume * 100).round()}%',
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.screen_lock_portrait_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsKeepScreenAwake),
                    subtitle: Text(l10n.settingsKeepScreenAwakeSubtitle),
                    value: appState.keepScreenAwake,
                    onChanged: appState.setKeepScreenAwake,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.vibration,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsHaptics),
                    subtitle: Text(l10n.settingsHapticsSubtitle),
                    value: appState.hapticsEnabled,
                    onChanged: appState.setHapticsEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(l10n.settingsResetData),
                subtitle: Text(l10n.settingsResetDataSubtitle),
                onTap: () => _confirmReset(context, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: l10n.settingsResetData,
      message: l10n.settingsResetDataConfirm,
      confirmLabel: l10n.commonReset,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AppState>().resetAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsResetDataDone)));
  }
}
