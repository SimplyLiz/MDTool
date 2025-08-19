import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive wrapper for Mermaid charts with static/interactive mode toggle
class InteractiveMermaidViewer extends StatefulWidget {
  final WebViewController controller;
  final double width;
  final double height;
  final VoidCallback? onModeToggle;

  const InteractiveMermaidViewer({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    this.onModeToggle,
  });

  @override
  State<InteractiveMermaidViewer> createState() => _InteractiveMermaidViewerState();
}

class _InteractiveMermaidViewerState extends State<InteractiveMermaidViewer> {
  bool _isInteractive = false;
  final TransformationController _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _toggleInteractiveMode() async {
    setState(() {
      _isInteractive = !_isInteractive;
    });
    
    // Update JavaScript touch handling
    await widget.controller.runJavaScript('''
      console.log('=== Interactive Mode Toggle ===');
      console.log('Target mode: $_isInteractive');
      
      try {
        if (window.setInteractiveMode) {
          window.setInteractiveMode($_isInteractive);
          console.log('Interactive mode set via helper function');
        } else {
          // Fallback method
          const pointerEvents = $_isInteractive ? 'auto' : 'none';
          document.body.style.pointerEvents = pointerEvents;
          
          const container = document.getElementById('mermaid-container');
          if (container) {
            container.style.pointerEvents = pointerEvents;
          }
          
          const svgs = document.querySelectorAll('#mermaid-graph svg');
          svgs.forEach(svg => {
            svg.style.pointerEvents = pointerEvents;
          });
        }
        console.log('=== Toggle Complete ===');
      } catch (error) {
        console.error('Error in toggle:', error);
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

  @override
  Widget build(BuildContext context) {
    final webView = SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(controller: widget.controller),
    );

    if (_isInteractive) {
      return NotificationListener<ScrollNotification>(
        // Prevent scroll events from bubbling up to parent
        onNotification: (_) => true,
        child: Stack(
          children: [
            // Handle scroll wheel events for panning
            Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // Convert scroll to pan
                  final delta = Offset(0, -pointerSignal.scrollDelta.dy);
                  final matrix = _transformController.value.clone();
                  matrix.translate(delta.dx, delta.dy);
                  _transformController.value = matrix;
                }
              },
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  constrained: true,
                  boundaryMargin: const EdgeInsets.all(200),
                  panEnabled: true,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: false,
                  child: webView,
                ),
              ),
            ),
          // Interactive mode controls
          Positioned(
              top: 8,
              left: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reset zoom button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 18),
                      onPressed: _resetZoom,
                      tooltip: 'Reset Zoom',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Mode toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.pan_tool, color: Colors.white, size: 18),
                      onPressed: _toggleInteractiveMode,
                      tooltip: 'Exit Interactive Mode',
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Stack(
        children: [
          webView,
          // Static mode toggle button
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                onPressed: _toggleInteractiveMode,
                tooltip: 'Enable Interactive Mode',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      );
    }
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