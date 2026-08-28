import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants.dart';
import '../core/game_page_state.dart';
import '../core/game_registry.dart';
import '../helpers/debug_log.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../widgets/readable_width.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with DisposeCleanup {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  /// The platform lookup can fail — an unimplemented channel, a stripped
  /// bundle — and a version string is not worth an error screen. The build
  /// falls back to the compiled-in constant.
  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (e) {
      errorLog('[AboutPage] Package info unavailable: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = _packageInfo;
    final version = info == null
        ? AppConstants.appVersion
        : '${info.version} (build ${info.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.videogame_asset_rounded,
              size: 72,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.aboutVersion(version),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.aboutDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.aboutGamesInstalled(GameRegistry.all.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(l10n.aboutLicense),
                    subtitle: const Text('AGPL-3.0-or-later'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.aboutThirdPartyLicenses),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: version,
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
