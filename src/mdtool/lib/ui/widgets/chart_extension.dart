import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/services/graph_renderer.dart';

/// Custom markdown syntax for chart blocks
class ChartBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^🔄CHART:([^:]+):(\d+)🔄(.*)🔄END🔄$', 
                              multiLine: true, dotAll: true);

  const ChartBlockSyntax();

  @override
  bool canParse(md.BlockParser parser) {
    final line = parser.current.content;
    return pattern.hasMatch(line);
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final line = parser.current.content;
    final match = pattern.firstMatch(line);
    
    if (match != null) {
      final language = match.group(1)!;
      final index = match.group(2)!;
      final content = match.group(3)!;
      
      parser.advance();
      
      final element = md.Element.text('chart-block', content);
      element.attributes['data-language'] = language;
      element.attributes['data-index'] = index;
      
      return element;
    }
    
    return null;
  }
}

/// Element builder for chart blocks
class ChartBlockElementBuilder extends MarkdownElementBuilder {
  final GraphRendererRegistry registry;
  final BuildContext context;
  
  ChartBlockElementBuilder({
    required this.registry,
    required this.context,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    print('ChartBlockElementBuilder: Processing element - tag: ${element.tag}');
    
    if (element.tag == 'chart-block') {
      final language = element.attributes['data-language'];
      final content = element.textContent;
      
      print('ChartBlockElementBuilder: Found chart block - language: $language, content: $content');
      
      if (language != null) {
        final renderer = registry.findRenderer(language);
        if (renderer != null) {
          print('ChartBlockElementBuilder: Found renderer for $language, building widget');
          return _buildChartWidget(renderer, content);
        } else {
          print('ChartBlockElementBuilder: No renderer found for language: $language');
        }
      }
    }
    return null;
  }

  Widget _buildChartWidget(GraphRenderer renderer, String content) {
    return FutureBuilder<Widget>(
      future: _renderChart(renderer, content),
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
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Chart Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
  
  Future<Widget> _renderChart(GraphRenderer renderer, String content) async {
    try {
      final options = GraphRenderOptions(
        theme: Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light',
        interactive: true,
      );
      
      return await renderer.render(content, context, options: options);
    } catch (e) {
      rethrow;
    }
  }
}