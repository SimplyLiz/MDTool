import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'window_pane.dart';

enum LayoutMode {
  single,
  split,
}

class WindowLayoutConfig {
  final LayoutMode mode;
  final List<WindowPaneConfig> panes;
  final Widget? toolbar;
  final double? splitRatio;

  const WindowLayoutConfig({
    required this.mode,
    required this.panes,
    this.toolbar,
    this.splitRatio = 0.5,
  });
}

class WindowLayout extends ConsumerWidget {
  final WindowLayoutConfig config;
  final Map<WindowPaneConfig, Widget> paneWidgets;

  const WindowLayout({
    super.key,
    required this.config,
    required this.paneWidgets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (config.toolbar != null) config.toolbar!,
        Expanded(
          child: _buildLayout(),
        ),
      ],
    );
  }

  Widget _buildLayout() {
    if (config.mode == LayoutMode.single) {
      return _buildSinglePane();
    } else {
      return _buildSplitPane();
    }
  }

  Widget _buildSinglePane() {
    final paneConfig = config.panes.first;
    final widget = paneWidgets[paneConfig]!;
    
    return WindowPane(
      config: paneConfig,
      child: widget,
    );
  }

  Widget _buildSplitPane() {
    return Row(
      children: [
        // Left pane
        Expanded(
          flex: (config.splitRatio! * 100).round(),
          child: _buildPaneAtIndex(0, showBorder: true),
        ),
        // Right pane
        Expanded(
          flex: ((1 - config.splitRatio!) * 100).round(),
          child: _buildPaneAtIndex(1, padding: const EdgeInsets.only(left: 8)),
        ),
      ],
    );
  }

  Widget _buildPaneAtIndex(int index, {bool showBorder = false, EdgeInsets? padding}) {
    if (index >= config.panes.length) {
      return const SizedBox.shrink();
    }

    final paneConfig = config.panes[index];
    final widget = paneWidgets[paneConfig]!;
    
    return WindowPane(
      config: paneConfig,
      showBorder: showBorder,
      padding: padding,
      child: widget,
    );
  }
}