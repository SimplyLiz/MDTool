import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A pool of reusable WebView controllers for better performance
class WebViewPool {
  static final WebViewPool _instance = WebViewPool._internal();
  factory WebViewPool() => _instance;
  WebViewPool._internal();

  final List<WebViewController> _availableControllers = [];
  final Set<WebViewController> _usedControllers = {};
  final int _maxPoolSize = 3; // Reasonable limit for memory usage

  /// Get a WebView controller from the pool or create a new one
  Future<WebViewController> getController() async {
    WebViewController controller;
    
    if (_availableControllers.isNotEmpty) {
      controller = _availableControllers.removeLast();
    } else {
      controller = WebViewController();
      await _initializeController(controller);
    }
    
    _usedControllers.add(controller);
    return controller;
  }

  /// Return a controller to the pool for reuse
  void returnController(WebViewController controller) {
    if (_usedControllers.remove(controller)) {
      if (_availableControllers.length < _maxPoolSize) {
        // Reset the controller and add it back to the pool
        _resetController(controller);
        _availableControllers.add(controller);
      }
      // If pool is full, let the controller be garbage collected
    }
  }

  /// Initialize a new controller with standard settings
  Future<void> _initializeController(WebViewController controller) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    // Don't add HeightChannel here - let individual charts manage their own channels
  }

  /// Reset a controller for reuse
  void _resetController(WebViewController controller) {
    // Clear any previous content but keep it simple to avoid conflicts
    controller.loadHtmlString('''
      <!DOCTYPE html>
      <html>
        <head><title>Ready</title></head>
        <body><div style="padding:20px;">Ready for next chart...</div></body>
      </html>
    ''');
    
    // Note: We can't easily remove JavaScript channels, so we'll handle 
    // channel conflicts in the renderer
  }

  /// Generate mermaid HTML with proper theme configuration
  static Future<String> getMermaidHTML(String theme, {String? backgroundColorCss}) async {
    return await _generateMermaidHTML(theme, backgroundColorCss ?? 'transparent');
  }

  static Future<String> _generateMermaidHTML(String theme, String bgColor) async {
    // This will load the mermaid.js content once and cache it
    String mermaidJS;
    try {
      mermaidJS = await rootBundle.loadString('assets/js/mermaid.min.js');
    } catch (e) {
      debugPrint('Failed to load local mermaid.js, using CDN fallback: $e');
      mermaidJS = '';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            margin: 0;
            padding: 16px;
            background: $bgColor;
            color: ${theme == 'dark' ? '#ffffff' : '#000000'};
            overflow: hidden;
            min-height: 100px;
            height: auto;
        }
        
        #mermaid-container {
            width: 100%;
            max-width: 100vw;
            overflow-x: auto;
            overflow-y: hidden;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            padding: 0;
        }
        
        #mermaid-graph {
            width: auto;
            min-width: 100%;
            height: auto;
        }
        
        /* Responsive scaling with dynamic width adjustment */
        #mermaid-graph svg {
            display: block;
            height: auto !important;
            margin: 0 auto;
        }
        
        /* Ensure text remains readable */
        #mermaid-graph svg text {
            font-size: 14px !important;
        }
        
        /* Custom styling for better integration */
        .node rect,
        .node circle,
        .node ellipse,
        .node polygon {
            stroke-width: 2px;
        }
        
        .edgePath .path {
            stroke-width: 2px;
        }
        
        .error-message {
            color: #ef4444;
            background: ${theme == 'dark' ? '#1f1f1f' : '#fef2f2'};
            border: 1px solid #ef4444;
            border-radius: 8px;
            padding: 16px;
            margin: 16px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div id="mermaid-container">
        <div id="mermaid-graph">
            Loading diagram...
        </div>
    </div>
    
    ${mermaidJS.isNotEmpty ? '<script>$mermaidJS</script>' : '<script src="https://unpkg.com/mermaid@10.9.1/dist/mermaid.min.js"></script>'}
    <script>
        // Global mermaid configuration - only initialize once
        if (!window.mermaidInitialized) {
            const mermaidConfig = {
                startOnLoad: false,
                theme: 'base',
                securityLevel: 'loose',
                suppressErrorRendering: true,
                maxEdges: 500,
                themeVariables: ${theme == 'dark' ? '''{
                    primaryColor: '#bb86fc',
                    primaryTextColor: '#ffffff',
                    primaryBorderColor: '#03dac6',
                    lineColor: '#ffffff',
                    secondaryColor: '#03dac6',
                    tertiaryColor: '#1f1f1f',
                    background: '$bgColor',
                    mainBkg: '$bgColor',
                    secondBkg: '$bgColor',
                    tertiaryBkg: '$bgColor',
                    edgeLabelBackground: '$bgColor',
                }''' : '''{
                    primaryColor: '#6366f1',
                    primaryTextColor: '#ffffff',
                    primaryBorderColor: '#4f46e5',
                    lineColor: '#374151',
                    secondaryColor: '#10b981',
                    tertiaryColor: '#f3f4f6',
                    background: '$bgColor',
                    mainBkg: '$bgColor',
                    secondBkg: '$bgColor',
                    tertiaryBkg: '$bgColor',
                    edgeLabelBackground: '$bgColor',
                }'''},
                flowchart: {
                    htmlLabels: true,
                    useMaxWidth: true,
                    curve: 'linear',
                },
                sequence: {
                    diagramMarginX: 50,
                    diagramMarginY: 10,
                    actorMargin: 50,
                    width: 150,
                    height: 65,
                    boxMargin: 10,
                    boxTextMargin: 5,
                    noteMargin: 10,
                    messageMargin: 35,
                    mirrorActors: true,
                    bottomMarginAdj: 1,
                    useMaxWidth: true,
                },
                gantt: {
                    useMaxWidth: true,
                },
            };

            function initializeMermaid() {
                try {
                    if (typeof mermaid === 'undefined') {
                        showError('Mermaid library failed to load');
                        return;
                    }
                    
                    mermaid.initialize(mermaidConfig);
                    window.mermaidInitialized = true;
                } catch (error) {
                    showError('Failed to initialize Mermaid: ' + error.message);
                }
            }

            // Initialize immediately when available
            if (typeof mermaid !== 'undefined') {
                initializeMermaid();
            } else {
                // Use proper event listener instead of timeout
                document.addEventListener('DOMContentLoaded', initializeMermaid);
            }
        }
        
        async function renderMermaid(content) {
            try {
                const container = document.getElementById('mermaid-graph');
                
                // Use the modern mermaid.render API for better control
                const { svg } = await mermaid.render('mermaid-diagram-' + Date.now(), content);
                container.innerHTML = svg;
                
                // Apply responsive fixes immediately after render
                requestAnimationFrame(() => {
                    const svgElement = container.querySelector('svg');
                    if (svgElement) {
                        // Get natural dimensions for aspect ratio calculation
                        const bbox = svgElement.getBBox();
                        const naturalWidth = bbox.width || parseFloat(svgElement.getAttribute('width')) || 300;
                        const naturalHeight = bbox.height || parseFloat(svgElement.getAttribute('height')) || 200;
                        
                        // Calculate aspect ratio
                        const aspectRatio = naturalWidth / naturalHeight;
                        
                        // Remove fixed dimensions
                        svgElement.removeAttribute('width');
                        svgElement.removeAttribute('height');
                        svgElement.style.height = 'auto';
                        
                        // Apply smart scaling for tall charts
                        if (aspectRatio < 1.0) { // Tall chart
                            const targetMaxHeight = 400;
                            const optimalWidth = Math.min(600, targetMaxHeight * aspectRatio);
                            svgElement.style.maxWidth = optimalWidth + 'px';
                            svgElement.style.width = 'auto';
                        } else { // Wide or square chart
                            svgElement.style.width = '100%';
                            svgElement.style.maxWidth = 'none';
                        }
                        
                        // Calculate and send height to Flutter
                        setTimeout(() => {
                            const svgBounds = svgElement.getBoundingClientRect();
                            // Add padding (16px top + 16px bottom) + small buffer
                            const contentHeight = svgBounds.height + 40;
                            // Reduced minimum height for better auto-sizing
                            const minHeight = Math.max(100, contentHeight);
                            
                            if (window.currentHeightChannel && window[window.currentHeightChannel]) {
                                window[window.currentHeightChannel].postMessage(minHeight.toString());
                            }
                        }, 50);
                    }
                });
            } catch (error) {
                showError('Failed to render diagram: ' + error.message);
            }
        }
        
        function showError(message) {
            const container = document.getElementById('mermaid-graph');
            container.innerHTML = '<div class="error-message">' + message + '</div>';
        }
        
        // Make renderMermaid available globally for WebView
        window.renderMermaid = renderMermaid;
    </script>
</body>
</html>''';
  }

  /// Clear the entire pool (useful for memory management)
  void clearPool() {
    _availableControllers.clear();
    _usedControllers.clear();
  }

  /// Get pool statistics for debugging
  Map<String, int> getStats() {
    return {
      'available': _availableControllers.length,
      'used': _usedControllers.length,
      'total': _availableControllers.length + _usedControllers.length,
    };
  }
}