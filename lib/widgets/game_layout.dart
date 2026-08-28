import 'package:flutter/material.dart';

import 'floating_back_button.dart';

/// The shell every game page sits in.
///
/// A game is normally [fullscreen]: no app bar, the board owns the whole safe
/// area, and the back button plus any [actions] float above it as round
/// buttons. Set `fullscreen: false` for a game that wants ordinary chrome.
class GameLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool fullscreen;
  final List<Widget>? actions;
  final bool showFloatingBackButton;
  final Color? backgroundColor;

  const GameLayout({
    super.key,
    required this.title,
    required this.child,
    this.fullscreen = true,
    this.actions,
    this.showFloatingBackButton = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isShort = MediaQuery.sizeOf(context).height < 600;
    final appBarHeight = isShort ? 40.0 : 56.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: fullscreen
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(appBarHeight),
              child: AppBar(
                toolbarHeight: appBarHeight,
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: isShort ? 16 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: actions,
              ),
            ),
      body: SafeArea(
        child: Stack(
          children: [
            child,
            if (fullscreen && showFloatingBackButton)
              const Positioned(left: 12, top: 12, child: FloatingBackButton()),
            if (fullscreen && actions != null)
              Positioned(
                left: showFloatingBackButton && Navigator.of(context).canPop()
                    ? 64
                    : 12,
                right: 12,
                top: 12,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actions!
                        .map(
                          (action) => Material(
                            color: theme.colorScheme.surface.withAlpha(200),
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
