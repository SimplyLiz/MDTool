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

class WindowLayout extends ConsumerStatefulWidget {
  final WindowLayoutConfig config;
  final Map<WindowPaneConfig, Widget> paneWidgets;

  const WindowLayout({
    super.key,
    required this.config,
    required this.paneWidgets,
  });

  @override
  ConsumerState<WindowLayout> createState() => _WindowLayoutState();
}

class _WindowLayoutState extends ConsumerState<WindowLayout> {
  late double _splitRatio;

  @override
  void initState() {
    super.initState();
    _splitRatio = widget.config.splitRatio ?? 0.5;
  }

  @override
  void didUpdateWidget(covariant WindowLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset ratio when switching between single/split
    if (oldWidget.config.mode != widget.config.mode) {
      _splitRatio = widget.config.splitRatio ?? 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.config.toolbar != null) widget.config.toolbar!,
        Expanded(
          child: widget.config.mode == LayoutMode.single
              ? _buildSinglePane()
              : _buildSplitPane(),
        ),
      ],
    );
  }

  Widget _buildSinglePane() {
    final paneConfig = widget.config.panes.first;
    final paneWidget = widget.paneWidgets[paneConfig]!;

    return WindowPane(
      config: paneConfig,
      child: paneWidget,
    );
  }

  Widget _buildSplitPane() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final dividerWidth = 6.0;
        final availableWidth = totalWidth - dividerWidth;
        final leftWidth = (availableWidth * _splitRatio).clamp(150.0, availableWidth - 150.0);
        final rightWidth = availableWidth - leftWidth;

        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: _buildPaneAtIndex(0),
            ),
            // Draggable divider
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitRatio = ((_splitRatio * availableWidth + details.delta.dx) / availableWidth)
                        .clamp(0.2, 0.8);
                  });
                },
                child: Container(
                  width: dividerWidth,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth,
              child: _buildPaneAtIndex(1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaneAtIndex(int index) {
    if (index >= widget.config.panes.length) {
      return const SizedBox.shrink();
    }

    final paneConfig = widget.config.panes[index];
    final paneWidget = widget.paneWidgets[paneConfig]!;

    return WindowPane(
      config: paneConfig,
      child: paneWidget,
    );
  }
}
