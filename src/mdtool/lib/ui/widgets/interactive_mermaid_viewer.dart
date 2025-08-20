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
  final ValueChanged<bool>? onInteractiveChanged; // NEW: Parent scroll coordination

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
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    
    // Detect if this is pure pan (scale unchanged) vs zoom+pan
    final scaleChanged = (scale - _lastScale).abs() > 0.001;
    final gestureType = scaleChanged ? 'ZOOM+PAN' : 'PAN-ONLY';
    
    debugPrint('Mermaid Viewer: [$gestureType] Scale: ${scale.toStringAsFixed(2)}, Translation: (${translation.x.toStringAsFixed(1)}, ${translation.y.toStringAsFixed(1)})');
    _lastScale = scale;
  }

  void _toggleInteractiveMode() async {
    debugPrint('Mermaid Viewer: Toggling interactive mode from $_isInteractive to ${!_isInteractive}');
    
    setState(() {
      _isInteractive = !_isInteractive;
    });
    
    // Notify parent to coordinate scroll behavior
    widget.onInteractiveChanged?.call(_isInteractive);
    debugPrint('Mermaid Viewer: Notified parent of interactive mode change: $_isInteractive');
    
    // Update JavaScript for visual feedback
    await widget.controller.runJavaScript('''
      console.log('Mermaid Viewer: JavaScript interactive mode set to $_isInteractive');
      
      if (window.setInteractiveMode) {
        window.setInteractiveMode($_isInteractive);
      }
    ''');
    
    // Reset zoom when switching to static mode
    if (!_isInteractive) {
      _transformController.value = Matrix4.identity();
      debugPrint('Mermaid Viewer: Reset zoom to identity matrix');
    }
    
    widget.onModeToggle?.call();
    debugPrint('Mermaid Viewer: Interactive mode toggle complete');
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
            : screen.width; // Never infinity
        final finiteH = widget.height.isFinite
            ? widget.height
            : (constraints.maxHeight.isFinite ? constraints.maxHeight : 400);

        // DEBUG: Use colored container to test panning visually
        final isDebugMode = false; // Set to false to use WebView
        
        return ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: finiteW.toDouble(), height: finiteH.toDouble()),
          child: IgnorePointer(
            ignoring: _isInteractive,
            child: Listener(
              onPointerDown: _isInteractive ? null : (event) {
                debugPrint('Mermaid Viewer: WebView received pointer down in static mode');
              },
              child: isDebugMode
                  ? Container(
                      // Make content much larger than container to show panning effect
                      width: finiteW * 2.5,
                      height: finiteH * 2.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.purple, Colors.red, Colors.orange, Colors.green, Colors.yellow],
                          stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Center content
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PAN TEST\n\nThis content is 2.5x larger than the container.\nPan around to see different colored areas!',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Corner markers to show pan range
                          const Positioned(
                            top: 20,
                            left: 20,
                            child: Text('TOP LEFT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: const Text('TOP RIGHT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: const Text('BOTTOM LEFT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: const Text('BOTTOM RIGHT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : WebViewWidget(
                      controller: widget.controller,
                      // Keep empty so Flutter wins the gesture arena
                      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                    ),
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
        final h = widget.height.isFinite ? widget.height : 400; // pick a sensible default

        Widget core = _isInteractive
            ? Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  debugPrint('Mermaid Viewer: Pointer down at ${event.localPosition} in interactive mode');
                },
                onPointerMove: (event) {
                  debugPrint('Mermaid Viewer: Pointer move to ${event.localPosition}, delta: ${event.localDelta}');
                },
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    debugPrint('Mermaid Viewer: Scroll event received: ${event.scrollDelta}');
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
                  // Allow panning within reasonable bounds
                  boundaryMargin: const EdgeInsets.all(100),
                  panEnabled: true,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: false,
                  // Let Stack handle clipping consistently
                  clipBehavior: Clip.hardEdge,
                  child: _buildWebView(ctx), // child is already finite
                ),
              )
            : _buildWebView(ctx);

        // Use ClipRect only for static mode, allow overflow in interactive mode
        return SizedBox(
          width: w.toDouble(),
          height: h.toDouble(),
          child: _isInteractive
              ? Stack(
                  clipBehavior: Clip.hardEdge, // Keep content within container bounds
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