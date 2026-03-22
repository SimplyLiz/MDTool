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
    if (element.tag == 'chart-block') {
      final language = element.attributes['data-language'];
      final content = element.textContent;

      if (language != null) {
        final renderer = registry.findRenderer(language);
        if (renderer != null) {
          return _buildChartWidget(renderer, content);
        }
      }
    }
    return null;
  }

  Widget _buildChartWidget(GraphRenderer renderer, String content) {
    return Builder(
      builder: (builderContext) {
        return FutureBuilder<Widget>(
          future: _renderChart(renderer, content, builderContext),
          builder: (ctx, snapshot) {
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
              final errorColor = Theme.of(ctx).colorScheme.error;
              final errorBg = Theme.of(ctx).colorScheme.errorContainer;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorBg,
                  border: Border.all(color: errorColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: errorColor),
                    const SizedBox(height: 8),
                    Text(
                      'Chart Error: ${snapshot.error}',
                      style: TextStyle(color: errorColor),
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
                    color: Theme.of(ctx).dividerColor,
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
      },
    );
  }

  Future<Widget> _renderChart(GraphRenderer renderer, String content, BuildContext ctx) async {
    final options = GraphRenderOptions(
      theme: Theme.of(ctx).brightness == Brightness.dark ? 'dark' : 'light',
      interactive: true,
    );

    return await renderer.render(content, ctx, options: options);
  }
}