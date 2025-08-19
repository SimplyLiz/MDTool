import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/graph_renderer.dart';
import '../../core/services/renderers/mermaid_renderer.dart';
import '../../core/services/renderers/chart_renderer.dart';
import '../../core/services/renderers/simple_chart_renderer.dart' as core_simple;
import 'package:markdown/markdown.dart' as md;
import 'dart:math' as math;

class SimpleChartRenderer {
  static final GraphRendererRegistry _registry = GraphRendererRegistry();
  
  static void _ensureRenderersRegistered() {
    if (_registry.renderers.isEmpty) {
      _registry.register(MermaidRenderer());
      _registry.register(ChartRenderer());
      _registry.register(core_simple.SimpleChartRenderer());
      print('SimpleChartRenderer: Registered ${_registry.renderers.length} renderers');
    }
  }
  
  /// Process markdown content and return a list of widgets
  static List<Widget> processMarkdown(String markdown, BuildContext context) {
    _ensureRenderersRegistered();
    
    final widgets = <Widget>[];
    final lines = markdown.split('\n');
    
    int i = 0;
    while (i < lines.length) {
      if (lines[i].startsWith('```')) {
        // Found a code block
        final language = lines[i].substring(3).trim();
        final codeLines = <String>[];
        i++; // Move past the opening ```
        
        // Collect code block content
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        
        if (i < lines.length) {
          i++; // Move past the closing ```
        }
        
        // Check if this is a chart language
        final renderer = _registry.findRenderer(language);
        if (renderer != null) {
          print('SimpleChartRenderer: Found chart block - language: $language');
          final content = codeLines.join('\n');
          print('SimpleChartRenderer: Adding chart widget for $language (content length: ${content.length})');
          widgets.add(_buildChartWidget(renderer, content, context));
        } else {
          print('SimpleChartRenderer: No renderer for language $language, showing as code block');
          // Regular code block - add as text
          widgets.add(_buildCodeBlock(language, codeLines.join('\n')));
        }
      } else {
        // Regular text line - collect until we find a code block or end
        final textLines = <String>[];
        while (i < lines.length && !lines[i].startsWith('```')) {
          textLines.add(lines[i]);
          i++;
        }
        
        if (textLines.isNotEmpty) {
          final text = textLines.join('\n').trim();
          if (text.isNotEmpty) {
            widgets.add(_buildMarkdownText(text, context));
          }
        }
      }
    }
    
    return widgets;
  }
  
  static Widget _buildChartWidget(GraphRenderer renderer, String content, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withOpacity(0.1),
            child: Text(
              'CHART WIDGET: ${renderer.type}',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder<Widget>(
            future: _renderChart(renderer, content, context),
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text('Rendering ${renderer.displayName}...'),
                  ],
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            print('SimpleChartRenderer: Error rendering ${renderer.type}: ${snapshot.error}');
            // Fallback to showing the content as a code block
            return _buildCodeBlock(renderer.type, content);
          }
          
          if (snapshot.hasData) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: snapshot.data!,
              ),
            );
          }
          
          return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
  
  static Widget _buildCodeBlock(String language, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Monaco',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildMarkdownText(String text, BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: false,
    );
  }
  
  static Future<Widget> _renderChart(GraphRenderer renderer, String content, BuildContext context) async {
    try {
      print('SimpleChartRenderer: Starting render for ${renderer.type}');
      print('SimpleChartRenderer: Content preview: ${content.substring(0, math.min(100, content.length))}...');
      
      final options = GraphRenderOptions(
        theme: Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light',
        interactive: true,
      );
      
      final result = await renderer.render(content, context, options: options);
      print('SimpleChartRenderer: Render completed successfully for ${renderer.type}');
      return result;
    } catch (e) {
      print('SimpleChartRenderer: Render failed for ${renderer.type}: $e');
      rethrow;
    }
  }
}