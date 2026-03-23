import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/services/graph_renderer.dart';
import 'graph_element_builder.dart';

/// A fenced code block builder that handles both charts and syntax highlighting
class ChartCodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  final GraphRenderingService graphService;
  final Map<String, TextStyle> codeTheme;

  ChartCodeBlockBuilder({
    required this.context,
    required this.graphService,
  }) : codeTheme = Theme.of(context).brightness == Brightness.dark
            ? vs2015Theme
            : githubTheme;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'pre') return null;
    
    final codeElement = element.children?.firstWhere(
      (child) => child is md.Element && child.tag == 'code',
      orElse: () => element,
    ) as md.Element?;
    
    if (codeElement == null) {
      return _buildFallbackCodeBlock(element.textContent, null);
    }
    
    final code = codeElement.textContent;
    final language = _extractLanguage(codeElement);
    
    // Try to render as graph first
    if (language != null && language.isNotEmpty) {
      final renderer = graphService.registry.findRenderer(language);
      if (renderer != null) {
        return _buildChartWidget(renderer, code, language);
      }
    }
    
    // Fall back to syntax highlighting
    return _buildSyntaxHighlightedCode(code, language);
  }

  String? _extractLanguage(md.Element element) {
    final className = element.attributes['class'];
    if (className != null && className.startsWith('language-')) {
      return className.substring('language-'.length);
    }
    return null;
  }

  Widget _buildChartWidget(GraphRenderer renderer, String content, String? language) {
    // Use Builder to get a fresh, valid BuildContext from the widget tree
    return Builder(
      builder: (builderContext) {
        return FutureBuilder<Widget>(
          future: _renderChart(renderer, content, builderContext),
          builder: (futureContext, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              final errorColor = Theme.of(futureContext).colorScheme.error;
              final errorBg = Theme.of(futureContext).colorScheme.errorContainer;
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
                    color: Theme.of(futureContext).dividerColor,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: snapshot.data!,
                ),
              );
            }

            return _buildFallbackCodeBlock(content, language);
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

  Widget _buildSyntaxHighlightedCode(String code, String? language) {
    if (language != null && language.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: codeTheme['root']?.backgroundColor ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            HighlightView(
              code,
              language: _normalizeLanguage(language),
              theme: codeTheme,
              tabSize: 2,
              textStyle: const TextStyle(
                fontFamily: 'Monaco',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildFallbackCodeBlock(code, language);
  }

  String _normalizeLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'js':
        return 'javascript';
      case 'ts':
        return 'typescript';
      case 'sh':
      case 'shell':
        return 'bash';
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      default:
        return language;
    }
  }

  Widget _buildFallbackCodeBlock(String code, String? language) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: codeTheme['root']?.backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null) ...[
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
            code,
            style: const TextStyle(
              fontFamily: 'Monaco',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}