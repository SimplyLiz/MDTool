import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../graph_renderer.dart';
import 'dart:convert';

/// PlantUML renderer using PlantUML server
class PlantUMLRenderer extends GraphRenderer {
  @override
  String get type => 'plantuml';
  
  @override
  String get displayName => 'PlantUML Diagrams';
  
  @override
  List<String> get supportedSyntaxes => [
    'plantuml',
    'puml',
    'uml',
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
    
    final html = _generatePlantUMLHTML(content, theme);
    
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.loadHtmlString(html);
    
    return Container(
      height: options?.height ?? 400,
      width: options?.width ?? double.infinity,
      child: WebViewWidget(controller: controller),
    );
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    String? title;
    final lines = content.trim().split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('title ')) {
        title = trimmed.substring(6).trim();
        break;
      }
    }
    
    return GraphMetadata(
      title: title,
      attributes: {
        'type': 'PlantUML',
        'lines': lines.length.toString(),
      },
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    final errors = <String>[];
    
    if (content.trim().isEmpty) {
      errors.add('PlantUML content cannot be empty');
      return GraphValidationResult.invalid(errors);
    }
    
    // Check for required @startuml/@enduml tags
    final normalizedContent = content.toLowerCase();
    if (!normalizedContent.contains('@startuml') && !normalizedContent.contains('@start')) {
      errors.add('PlantUML diagram should start with @startuml or @start[type]');
    }
    
    if (!normalizedContent.contains('@enduml') && !normalizedContent.contains('@end')) {
      errors.add('PlantUML diagram should end with @enduml or @end[type]');
    }
    
    return errors.isNotEmpty 
        ? GraphValidationResult.invalid(errors)
        : GraphValidationResult.valid();
  }
  
  String _generatePlantUMLHTML(String content, String theme) {
    // Ensure the content has proper start/end tags
    String processedContent = content.trim();
    
    if (!processedContent.toLowerCase().contains('@start')) {
      processedContent = '@startuml\n$processedContent\n@enduml';
    }
    
    // Apply theme
    if (theme == 'dark' && !processedContent.contains('!theme')) {
      processedContent = processedContent.replaceFirst('@startuml', '@startuml\n!theme dark');
    }
    
    final encodedContent = _encodePlantUML(processedContent);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 16px;
            background: ${theme == 'dark' ? '#121212' : '#ffffff'};
            color: ${theme == 'dark' ? '#ffffff' : '#000000'};
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        
        .plantuml-container {
            max-width: 100%;
            max-height: 100%;
            overflow: auto;
        }
        
        .plantuml-container img {
            max-width: 100%;
            height: auto;
            border: 1px solid ${theme == 'dark' ? '#333' : '#ddd'};
            border-radius: 8px;
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
        
        .loading {
            text-align: center;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="plantuml-container">
        <div class="loading">Loading PlantUML diagram...</div>
    </div>
    
    <script>
        function loadPlantUML() {
            const container = document.querySelector('.plantuml-container');
            const serverUrl = 'https://www.plantuml.com/plantuml/svg/';
            const imageUrl = serverUrl + '${encodedContent}';
            
            const img = document.createElement('img');
            img.onload = function() {
                container.innerHTML = '';
                container.appendChild(img);
            };
            img.onerror = function() {
                container.innerHTML = '<div class="error-message">Failed to load PlantUML diagram. Please check your syntax.</div>';
            };
            img.src = imageUrl;
            img.alt = 'PlantUML Diagram';
        }
        
        // Load diagram when page is ready
        document.addEventListener('DOMContentLoaded', loadPlantUML);
    </script>
</body>
</html>
    ''';
  }
  
  String _encodePlantUML(String content) {
    // Simple base64 encoding for PlantUML
    // In a real implementation, you'd use the proper PlantUML encoding
    final bytes = utf8.encode(content);
    final base64 = base64Encode(bytes);
    return base64;
  }
}