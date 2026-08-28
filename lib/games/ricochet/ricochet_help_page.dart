import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/readable_width.dart';
import 'engine/tile.dart';
import 'widgets/tile_preview.dart';

/// The in-game reference: how a turn works, what every tile does, and what the
/// four path-bending tiles actually do to a ball.
///
/// Every tile here is drawn by the game's own painter, so the reference cannot
/// go stale relative to the board.
class RicochetHelpPage extends StatelessWidget {
  const RicochetHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ricochetHelpTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Section(title: l10n.ricochetHelpBasicsTitle),
            _Bullets(
              items: [
                l10n.ricochetHelpBasicsAim,
                l10n.ricochetHelpBasicsFire,
                l10n.ricochetHelpBasicsHp,
                l10n.ricochetHelpBasicsDrop,
                l10n.ricochetHelpBasicsClear,
                l10n.ricochetHelpBasicsPickup,
                l10n.ricochetHelpBasicsCharges,
              ],
            ),
            _Section(title: l10n.ricochetHelpTilesTitle),
            Text(
              l10n.ricochetHelpTilesIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _TileRow(
              type: TileType.normal,
              name: l10n.ricochetTileBrick,
              effect: l10n.ricochetTileBrickEffect,
            ),
            _TileRow(
              type: TileType.bomb,
              name: l10n.ricochetTileBomb,
              effect: l10n.ricochetTileBombEffect,
            ),
            _TileRow(
              type: TileType.gift,
              name: l10n.ricochetTileGift,
              effect: l10n.ricochetTileGiftEffect,
            ),
            _TileRow(
              type: TileType.mult,
              name: l10n.ricochetTileMult,
              effect: l10n.ricochetTileMultEffect,
            ),
            _TileRow(
              type: TileType.pierce,
              name: l10n.ricochetTilePierce,
              effect: l10n.ricochetTilePierceEffect,
            ),
            _TileRow(
              type: TileType.blast,
              name: l10n.ricochetTileBlast,
              effect: l10n.ricochetTileBlastEffect,
            ),
            _TileRow(
              type: TileType.rampA,
              name: l10n.ricochetTileRamp,
              effect: l10n.ricochetTileRampEffect,
            ),
            _TileRow(
              type: TileType.orb,
              name: l10n.ricochetTileOrb,
              effect: l10n.ricochetTileOrbEffect,
            ),
            _TileRow(
              type: TileType.normal,
              pickup: true,
              name: l10n.ricochetTilePickup,
              effect: l10n.ricochetTilePickupEffect,
            ),
            _Section(title: l10n.ricochetHelpDeflectorsTitle),
            Text(
              l10n.ricochetHelpDeflectorsIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Wrap so the three demos sit side by side when there is room and
            // stack on a phone, without a breakpoint of their own.
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _Demo(type: TileType.rampA, caption: l10n.ricochetHelpRampA),
                _Demo(type: TileType.rampB, caption: l10n.ricochetHelpRampB),
                _Demo(type: TileType.orb, caption: l10n.ricochetHelpOrbDemo),
              ],
            ),
            _Section(title: l10n.ricochetHelpControlsTitle),
            _Bullets(
              items: [
                l10n.ricochetHelpControlsDrag,
                l10n.ricochetHelpControlsRecall,
                l10n.ricochetHelpControlsSpeed,
                l10n.ricochetHelpControlsMenu,
                l10n.ricochetHelpControlsRestart,
              ],
            ),
            _Section(title: l10n.ricochetHelpKeyboardTitle),
            _Bullets(
              items: [
                l10n.ricochetHelpKeyboardAim,
                l10n.ricochetHelpKeyboardFire,
                l10n.ricochetHelpKeyboardRecall,
                l10n.ricochetHelpKeyboardMenu,
              ],
            ),
            _Section(title: l10n.ricochetHelpLevelsTitle),
            Text(
              l10n.ricochetHelpLevelsText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            _Section(title: l10n.ricochetHelpProgressTitle),
            Text(
              l10n.ricochetHelpProgressText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;

  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodyMedium),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  final TileType type;
  final String name;
  final String effect;
  final bool pickup;

  const _TileRow({
    required this.type,
    required this.name,
    required this.effect,
    this.pickup = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pickup ? const TilePreview.pickup() : TilePreview(type: type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(effect, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Demo extends StatelessWidget {
  final TileType type;
  final String caption;

  const _Demo({required this.type, required this.caption});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeflectionDemo(type: type),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
