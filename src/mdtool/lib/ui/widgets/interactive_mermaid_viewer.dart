import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive wrapper for Mermaid charts with static/interactive mode toggle
class InteractiveMermaidViewer extends StatefulWidget {
  final WebViewController controller;
  final double width;
  final double height;
  final VoidCallback? onModeToggle;
  final ValueChanged<bool>? onInteractiveChanged;

  const InteractiveMermaidViewer({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    this.onModeToggle,
    this.onInteractiveChanged,
  });

  @override
  State<InteractiveMermaidViewer> createState() => _InteractiveMermaidViewerState();
}

class _InteractiveMermaidViewerState extends State<InteractiveMermaidViewer> {
  bool _isInteractive = false;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _toggleInteractiveMode() async {
    setState(() {
      _isInteractive = !_isInteractive;
    });

    // Notify parent to coordinate scroll behavior
    widget.onInteractiveChanged?.call(_isInteractive);

    // Update JavaScript for visual feedback
    await widget.controller.runJavaScript('''
      if (window.setInteractiveMode) {
        window.setInteractiveMode($_isInteractive);
      }
    ''');

    // Reset zoom when switching to static mode
    if (!_isInteractive) {
      _transformController.value = Matrix4.identity();
    }

    widget.onModeToggle?.call();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  Widget _buildWebView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final finiteW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;
        final finiteH = widget.height.isFinite
            ? widget.height
            : (constraints.maxHeight.isFinite ? constraints.maxHeight : 400);

        return ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: finiteW.toDouble(), height: finiteH.toDouble()),
          child: IgnorePointer(
            ignoring: _isInteractive,
            child: WebViewWidget(
              controller: widget.controller,
              // Keep empty so Flutter wins the gesture arena
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always give the viewer a finite box when it's in a scrollable
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(ctx).width;
        final h = widget.height.isFinite ? widget.height : 400;

        Widget core = _isInteractive
            ? Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final m = _transformController.value.clone();
                    m.translate(-event.scrollDelta.dx, -event.scrollDelta.dy);
                    _transformController.value = m;
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  constrained: true,
                  boundaryMargin: const EdgeInsets.all(100),
                  panEnabled: true,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: false,
                  clipBehavior: Clip.hardEdge,
                  child: _buildWebView(ctx),
                ),
              )
            : _buildWebView(ctx);

        return SizedBox(
          width: w.toDouble(),
          height: h.toDouble(),
          child: _isInteractive
              ? Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    core,
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SmallFab(icon: Icons.center_focus_strong, onPressed: _resetZoom, tooltip: 'Reset Zoom'),
                          const SizedBox(width: 4),
                          _SmallFab(icon: Icons.pan_tool, onPressed: _toggleInteractiveMode, tooltip: 'Exit Interactive Mode', primary: true),
                        ],
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    core,
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _SmallFab(icon: Icons.zoom_in, onPressed: _toggleInteractiveMode, tooltip: 'Enable Interactive Mode'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SmallFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool primary;
  const _SmallFab({required this.icon, required this.onPressed, required this.tooltip, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: (primary ? Colors.blue : Colors.black).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: const EdgeInsets.all(4),
      ),
    );
  }
}

/// Extension to provide interactive mode status
extension InteractiveMermaidViewerExtension on InteractiveMermaidViewer {
  /// Creates a widget that combines this viewer with a mode toggle button
  Widget withModeToggle({
    required BuildContext context,
    VoidCallback? onModeChange,
  }) {
    return InteractiveMermaidViewer(
      controller: controller,
      width: width,
      height: height,
      onModeToggle: onModeChange,
    );
  }
}
