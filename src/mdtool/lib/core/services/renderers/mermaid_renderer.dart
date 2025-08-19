import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../graph_renderer.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Mermaid graph renderer using WebView
class MermaidRenderer extends GraphRenderer {
  @override
  String get type => 'mermaid';
  
  @override
  String get displayName => 'Mermaid Diagrams';
  
  @override
  List<String> get supportedSyntaxes => [
    'mermaid',
    'flowchart',
    'sequencediagram',
    'classdiagram',
    'statediagram',
    'erdiagram',
    'gantt',
    'pie',
    'gitgraph',
    'journey',
    'requirement',
    'mindmap',
    'quadrantchart',
    'xychart',
    'timeline',
  ];
  
  @override
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    return _MermaidWebView(
      content: content,
      theme: options?.theme ?? 
          (Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light'),
      options: options,
    );
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    final lines = content.trim().split('\n');
    String? title;
    String? description;
    final attributes = <String, String>{};
    
    // Look for title in various formats
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Title directive
      if (trimmed.startsWith('title:')) {
        title = trimmed.substring(6).trim();
        continue;
      }
      
      // YAML-style metadata
      if (trimmed.startsWith('---')) continue;
      if (trimmed.contains(':') && !trimmed.contains('-->')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (key == 'title') title = value;
          if (key == 'description') description = value;
          attributes[key] = value;
        }
      }
    }
    
    return GraphMetadata(
      title: title,
      description: description,
      attributes: attributes,
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (content.trim().isEmpty) {
      errors.add('Mermaid content cannot be empty');
      return GraphValidationResult.invalid(errors);
    }
    
    // Basic syntax validation
    final lines = content.trim().split('\n');
    bool hasGraphType = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('%%')) continue;
      
      // Check for graph type declarations
      if (RegExp(r'^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|gitgraph|journey|requirementDiagram|mindmap|quadrantChart|xychart|timeline)').hasMatch(trimmed)) {
        hasGraphType = true;
        break;
      }
    }
    
    if (!hasGraphType) {
      warnings.add('No explicit graph type found, assuming flowchart');
    }
    
    return warnings.isNotEmpty 
        ? GraphValidationResult.withWarnings(warnings)
        : GraphValidationResult.valid();
  }
  
  String _generateMermaidHTML(String content, String theme, GraphRenderOptions? options) {
    final bgColor = options?.backgroundColorCss ?? 'transparent';
    
    final mermaidConfig = {
      'startOnLoad': false,
      'theme': 'base',
      'themeVariables': theme == 'dark' ? {
        'primaryColor': '#bb86fc',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#03dac6',
        'lineColor': '#ffffff',
        'secondaryColor': '#03dac6',
        'tertiaryColor': '#1f1f1f',
        'background': bgColor,
        'mainBkg': bgColor,
        'secondBkg': bgColor,
        'tertiaryBkg': bgColor,
        'edgeLabelBackground': bgColor,
      } : {
        'primaryColor': '#6366f1',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#4f46e5',
        'lineColor': '#374151',
        'secondaryColor': '#10b981',
        'tertiaryColor': '#f3f4f6',
        'background': bgColor,
        'mainBkg': bgColor,
        'secondBkg': bgColor,
        'tertiaryBkg': bgColor,
        'edgeLabelBackground': bgColor,
      },
      'flowchart': {
        'htmlLabels': true,
        'useMaxWidth': false,
      },
      'sequence': {
        'diagramMarginX': 50,
        'diagramMarginY': 10,
        'actorMargin': 50,
        'width': 150,
        'height': 65,
        'boxMargin': 10,
        'boxTextMargin': 5,
        'noteMargin': 10,
        'messageMargin': 35,
        'mirrorActors': true,
        'bottomMarginAdj': 1,
        'useMaxWidth': false,
      },
      'gantt': {
        'useMaxWidth': false,
      },
    };
    
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
            min-height: 200px;
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
        
        /* Force responsive scaling with proper overrides */
        #mermaid-graph svg {
            max-width: none !important;
            width: 100% !important;
            height: auto !important;
            display: block;
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
    
    <script src="https://unpkg.com/mermaid@10.9.1/dist/mermaid.min.js"></script>
    <script>
        // Wait for Mermaid to be available and initialize it
        function initializeMermaid() {
            try {
                if (typeof mermaid === 'undefined') {
                    showError('Mermaid library failed to load');
                    return;
                }
                
                mermaid.initialize(${jsonEncode(mermaidConfig)});
            } catch (error) {
                showError('Failed to initialize Mermaid: ' + error.message);
            }
        }
        
        // Initialize when the page loads
        if (typeof mermaid !== 'undefined') {
            initializeMermaid();
        } else {
            // Wait a bit for the script to load
            setTimeout(initializeMermaid, 100);
        }
        
        async function renderMermaid(content) {
            try {
                const container = document.getElementById('mermaid-graph');
                
                // Use the modern mermaid.render API for better control
                const { svg } = await mermaid.render('mermaid-diagram', content);
                container.innerHTML = svg;
                
                // Apply responsive fixes after render
                setTimeout(() => {
                    const svgElement = container.querySelector('svg');
                    if (svgElement) {
                        // Remove fixed dimensions and max-width constraints
                        svgElement.removeAttribute('width');
                        svgElement.removeAttribute('height');
                        svgElement.style.maxWidth = 'none';
                        svgElement.style.width = '100%';
                        svgElement.style.height = 'auto';
                        
                        // Calculate actual content height and adjust body
                        const svgBounds = svgElement.getBoundingClientRect();
                        const contentHeight = svgBounds.height + 32; // Add padding
                        const minHeight = Math.max(200, contentHeight);
                        
                        document.body.style.height = minHeight + 'px';
                        document.documentElement.style.height = minHeight + 'px';
                    }
                }, 100);
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
</html>
    ''';
  }
  
  String _escapeContent(String content) {
    return content
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\\', '\\\\');
  }
}

class _MermaidWebView extends StatefulWidget {
  final String content;
  final String theme;
  final GraphRenderOptions? options;

  const _MermaidWebView({
    required this.content,
    required this.theme,
    this.options,
  });

  @override
  State<_MermaidWebView> createState() => _MermaidWebViewState();
}

class _MermaidWebViewState extends State<_MermaidWebView> {
  late WebViewController controller;
  double height = 400; // Initial height

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    controller = WebViewController();
    final html = _generateMermaidHTML(widget.content, widget.theme, widget.options);
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    
    // Add JavaScript channel to receive height updates
    await controller.addJavaScriptChannel(
      'HeightChannel',
      onMessageReceived: (JavaScriptMessage message) {
        final newHeight = double.tryParse(message.message);
        if (newHeight != null && mounted) {
          setState(() {
            height = newHeight;
          });
        }
      },
    );
    
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          // Wait for Mermaid.js to be fully loaded and initialized
          Future.delayed(const Duration(milliseconds: 800), () {
            final escapedContent = _escapeContent(widget.content);
            controller.runJavaScript('''
              if (window.renderMermaid) {
                window.renderMermaid(`$escapedContent`);
              }
            ''');
          });
        },
      ),
    );
    
    await controller.loadHtmlString(html);
  }

  String _generateMermaidHTML(String content, String theme, GraphRenderOptions? options) {
    final bgColor = options?.backgroundColorCss ?? 'transparent';
    
    final mermaidConfig = {
      'startOnLoad': false,
      'theme': 'base',
      'themeVariables': theme == 'dark' ? {
        'primaryColor': '#bb86fc',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#03dac6',
        'lineColor': '#ffffff',
        'secondaryColor': '#03dac6',
        'tertiaryColor': '#1f1f1f',
        'background': bgColor,
        'mainBkg': bgColor,
        'secondBkg': bgColor,
        'tertiaryBkg': bgColor,
        'edgeLabelBackground': bgColor,
      } : {
        'primaryColor': '#6366f1',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#4f46e5',
        'lineColor': '#374151',
        'secondaryColor': '#10b981',
        'tertiaryColor': '#f3f4f6',
        'background': bgColor,
        'mainBkg': bgColor,
        'secondBkg': bgColor,
        'tertiaryBkg': bgColor,
        'edgeLabelBackground': bgColor,
      },
      'flowchart': {
        'htmlLabels': true,
        'useMaxWidth': false,
      },
      'sequence': {
        'diagramMarginX': 50,
        'diagramMarginY': 10,
        'actorMargin': 50,
        'width': 150,
        'height': 65,
        'boxMargin': 10,
        'boxTextMargin': 5,
        'noteMargin': 10,
        'messageMargin': 35,
        'mirrorActors': true,
        'bottomMarginAdj': 1,
        'useMaxWidth': false,
      },
      'gantt': {
        'useMaxWidth': false,
      },
    };
    
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
            min-height: 200px;
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
        
        /* Force responsive scaling with proper overrides */
        #mermaid-graph svg {
            max-width: none !important;
            width: 100% !important;
            height: auto !important;
            display: block;
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
    
    <script src="https://unpkg.com/mermaid@10.9.1/dist/mermaid.min.js"></script>
    <script>
        // Wait for Mermaid to be available and initialize it
        function initializeMermaid() {
            try {
                if (typeof mermaid === 'undefined') {
                    showError('Mermaid library failed to load');
                    return;
                }
                
                mermaid.initialize(${jsonEncode(mermaidConfig)});
            } catch (error) {
                showError('Failed to initialize Mermaid: ' + error.message);
            }
        }
        
        // Initialize when the page loads
        if (typeof mermaid !== 'undefined') {
            initializeMermaid();
        } else {
            // Wait a bit for the script to load
            setTimeout(initializeMermaid, 100);
        }
        
        async function renderMermaid(content) {
            try {
                const container = document.getElementById('mermaid-graph');
                
                // Use the modern mermaid.render API for better control
                const { svg } = await mermaid.render('mermaid-diagram', content);
                container.innerHTML = svg;
                
                // Apply responsive fixes after render
                setTimeout(() => {
                    const svgElement = container.querySelector('svg');
                    if (svgElement) {
                        // Remove fixed dimensions and max-width constraints
                        svgElement.removeAttribute('width');
                        svgElement.removeAttribute('height');
                        svgElement.style.maxWidth = 'none';
                        svgElement.style.width = '100%';
                        svgElement.style.height = 'auto';
                        
                        // Calculate actual content height and send to Flutter
                        const svgBounds = svgElement.getBoundingClientRect();
                        const contentHeight = svgBounds.height + 32; // Add padding
                        const minHeight = Math.max(200, contentHeight);
                        
                        // Send height to Flutter via JavaScript channel
                        if (window.HeightChannel) {
                            window.HeightChannel.postMessage(minHeight.toString());
                        }
                    }
                }, 100);
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
</html>
    ''';
  }

  String _escapeContent(String content) {
    return content
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\\', '\\\\');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.options?.width ?? double.infinity,
      height: widget.options?.height ?? height,
      child: WebViewWidget(controller: controller),
    );
  }
}