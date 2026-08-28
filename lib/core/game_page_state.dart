import 'package:flutter/widgets.dart';

/// Collects teardown callbacks so a page never overrides `dispose()` by hand
/// and can register cleanup right next to the thing that needs it.
mixin DisposeCleanup<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _disposeHooks = [];

  void onDispose(VoidCallback fn) => _disposeHooks.add(fn);

  @override
  void dispose() {
    for (final fn in _disposeHooks) {
      fn();
    }
    super.dispose();
  }
}
