import 'package:flutter/widgets.dart';

/// Wraps the whole app so it can be started again from scratch, as if it had
/// just been opened: every cubit, repository and screen is built new. Used after
/// everything is deleted, so the app comes back as a fresh install.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  /// Starts the app again. Returns false when there is no [RestartWidget]
  /// above [context], and nothing happened.
  static bool restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_RestartWidgetState>();
    if (state == null) return false;
    state._restart();
    return true;
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
