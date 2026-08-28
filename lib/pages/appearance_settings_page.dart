import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../widgets/readable_width.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearanceTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.brightness_6_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsTheme),
                    trailing: DropdownButton<ThemeMode>(
                      value: appState.themeMode,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(l10n.settingsThemeSystem),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(l10n.settingsThemeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l10n.settingsThemeDark),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) appState.setThemeMode(mode);
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.translate_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsLanguage),
                    trailing: DropdownButton<String>(
                      value: appState.locale?.languageCode ?? '',
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.settingsLanguageSystem),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.settingsLanguageEnglish),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Text(l10n.settingsLanguageGerman),
                        ),
                      ],
                      onChanged: (code) {
                        if (code == null) return;
                        appState.setLocale(code.isEmpty ? null : Locale(code));
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: Text(l10n.settingsCompactView),
                    subtitle: Text(l10n.settingsCompactViewSubtitle),
                    value: appState.compactMode,
                    onChanged: (_) => appState.toggleCompactMode(),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: Text(l10n.settingsSortBy),
                    trailing: DropdownButton<String>(
                      value: appState.sortBy,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'recent',
                          child: Text(l10n.settingsSortRecent),
                        ),
                        DropdownMenuItem(
                          value: 'order',
                          child: Text(l10n.settingsSortDefaultOrder),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text(l10n.settingsSortName),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) appState.setSortBy(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
