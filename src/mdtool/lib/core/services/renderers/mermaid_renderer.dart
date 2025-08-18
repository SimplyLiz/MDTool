import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../graph_renderer.dart';
import 'dart:convert';

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
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          // Inject content after page loads
          controller.runJavaScript('renderMermaid(`${_escapeContent(content)}`)');
        },
      ),
    );
    
    await controller.loadHtmlString(html);
    
    return Container(
      height: options?.height ?? 400,
      width: options?.width ?? double.infinity,
      child: WebViewWidget(controller: controller),
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
        
        .mermaid {
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
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
</head>
<body>
    <div id="mermaid-container">
        <div class="mermaid" id="mermaid-graph">
            Loading...
        </div>
    </div>
    
    <script>
        mermaid.initialize(${jsonEncode(mermaidConfig)});
        
        function renderMermaid(content) {
            try {
                const container = document.getElementById('mermaid-graph');
                container.innerHTML = content;
                
                mermaid.run().then(() => {
                    console.log('Mermaid diagram rendered successfully');
                }).catch((error) => {
                    console.error('Mermaid rendering error:', error);
                    showError('Failed to render diagram: ' + error.message);
                });
            } catch (error) {
                console.error('Mermaid setup error:', error);
                showError('Failed to initialize diagram: ' + error.message);
            }
        }
        
        function showError(message) {
            const container = document.getElementById('mermaid-graph');
            container.innerHTML = '<div class="error-message">' + message + '</div>';
        }
        
        // Handle resize
        window.addEventListener('resize', () => {
            mermaid.run();
        });
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