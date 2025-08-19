import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/graph_renderer.dart';
import '../../core/services/renderers/mermaid_renderer.dart';
import '../../core/services/renderers/chart_renderer.dart';
import '../../core/services/renderers/simple_chart_renderer.dart';
import 'package:markdown/markdown.dart' as md;

/// Preprocessor that converts chart code blocks into special HTML that can be rendered
class ChartPreprocessor {
  final GraphRendererRegistry registry;
  
  ChartPreprocessor() : registry = GraphRendererRegistry() {
    // Ensure renderers are registered
    if (registry.renderers.isEmpty) {
      registry.register(MermaidRenderer());
      registry.register(ChartRenderer());
      registry.register(SimpleChartRenderer());
    }
  }
  
  /// Process markdown content and replace chart blocks with placeholder HTML
  String preprocessMarkdown(String markdown) {
    print('ChartPreprocessor: Processing markdown content:');
    print('--- START CONTENT ---');
    print(markdown);
    print('--- END CONTENT ---');
    
    // Find all fenced code blocks
    final lines = markdown.split('\n');
    final processedLines = <String>[];
    
    bool inCodeBlock = false;
    String? currentLanguage;
    final currentBlock = <String>[];
    int blockIndex = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('```')) {
        if (!inCodeBlock) {
          // Starting a code block
          inCodeBlock = true;
          currentLanguage = line.substring(3).trim();
          currentBlock.clear();
        } else {
          // Ending a code block
          inCodeBlock = false;
          
          // Check if this is a chart language
          if (currentLanguage != null && 
              currentLanguage.isNotEmpty &&
              registry.findRenderer(currentLanguage) != null) {
            // Replace with special markdown that will be handled by the builder
            final content = currentBlock.join('\n');
            print('ChartPreprocessor: Found chart block - language: $currentLanguage, content length: ${content.length}');
            // Use a special text pattern that the element builder can recognize
            final placeholder = '🔄CHART:$currentLanguage:$blockIndex🔄$content🔄END🔄';
            processedLines.add(placeholder);
            blockIndex++;
          } else {
            // Keep as regular code block
            processedLines.add('```$currentLanguage');
            processedLines.addAll(currentBlock);
            processedLines.add('```');
          }
          
          currentLanguage = null;
          currentBlock.clear();
        }
      } else if (inCodeBlock) {
        currentBlock.add(line);
      } else {
        processedLines.add(line);
      }
    }
    
    return processedLines.join('\n');
  }
}

