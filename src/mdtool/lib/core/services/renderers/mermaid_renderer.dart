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
    final controller = WebViewController();
    final theme = options?.theme ?? 
        (Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light');
    
    final html = _generateMermaidHTML(content, theme, options);
    debugPrint('MermaidRenderer: Generated HTML (${html.length} chars)');
    debugPrint('MermaidRenderer: HTML preview: ${html.substring(0, math.min(200, html.length))}...');
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          debugPrint('MermaidRenderer: Page started loading: $url');
        },
        onPageFinished: (url) {
          debugPrint('MermaidRenderer: Page finished loading: $url');
          // Wait for Mermaid.js to be fully loaded and initialized
          Future.delayed(const Duration(milliseconds: 800), () {
            final escapedContent = _escapeContent(content);
            debugPrint('MermaidRenderer: Injecting mermaid content (${escapedContent.length} chars)');
            controller.runJavaScript('''
              if (window.renderMermaid) {
                window.renderMermaid(`$escapedContent`);
              } else {
                console.error('renderMermaid function not available');
              }
            ''');
          });
        },
        onWebResourceError: (error) {
          debugPrint('MermaidRenderer: WebResource error: ${error.description}');
        },
      ),
    );
    
    debugPrint('MermaidRenderer: Loading HTML string...');
    await controller.loadHtmlString(html);
    debugPrint('MermaidRenderer: HTML string loaded');
    
    // For debugging - create a container with visible dimensions
    return Container(
      height: options?.height ?? 400,
      width: options?.width ?? double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        color: Colors.green.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green.withOpacity(0.2),
            child: Text(
              'WEBVIEW CONTAINER: ${options?.height ?? 400}px × ${options?.width ?? 'auto'}px',
              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
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
    final mermaidConfig = {
      'startOnLoad': false,
      'theme': theme == 'dark' ? 'dark' : 'default',
      'themeVariables': theme == 'dark' ? {
        'primaryColor': '#bb86fc',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#03dac6',
        'lineColor': '#ffffff',
        'secondaryColor': '#03dac6',
        'tertiaryColor': '#1f1f1f',
        'background': '#121212',
        'mainBkg': '#121212',
        'secondBkg': '#1f1f1f',
        'tertiaryBkg': '#2d2d2d',
      } : {
        'primaryColor': '#6366f1',
        'primaryTextColor': '#ffffff',
        'primaryBorderColor': '#4f46e5',
        'lineColor': '#374151',
        'secondaryColor': '#10b981',
        'tertiaryColor': '#f3f4f6',
        'background': '#ffffff',
        'mainBkg': '#ffffff',
        'secondBkg': '#f9fafb',
        'tertiaryBkg': '#f3f4f6',
      },
      'flowchart': {
        'htmlLabels': true,
        'useMaxWidth': true,
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
        'useMaxWidth': true,
      },
      'gantt': {
        'useMaxWidth': true,
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
            background: ${theme == 'dark' ? '#121212' : '#ffffff'};
            color: ${theme == 'dark' ? '#ffffff' : '#000000'};
            overflow: hidden;
        }
        
        #mermaid-container {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: auto;
        }
        
        #mermaid-graph {
            max-width: 100%;
            height: auto;
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
    
    <script src="https://unpkg.com/mermaid@10.9.1/dist/mermaid.min.js" 
            onload="console.log('Mermaid script loaded')"
            onerror="console.error('Failed to load Mermaid script')"></script>
    <script>
        // Wait for Mermaid to be available and initialize it
        function initializeMermaid() {
            try {
                if (typeof mermaid === 'undefined') {
                    console.error('Mermaid library not loaded');
                    showError('Mermaid library failed to load');
                    return;
                }
                
                mermaid.initialize(${jsonEncode(mermaidConfig)});
                console.log('Mermaid initialized successfully');
            } catch (error) {
                console.error('Mermaid initialization error:', error);
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
                
                console.log('Mermaid diagram rendered successfully');
            } catch (error) {
                console.error('Mermaid render error:', error);
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