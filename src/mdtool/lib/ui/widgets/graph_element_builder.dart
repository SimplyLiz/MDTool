import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/services/graph_renderer.dart';

/// Enhanced code element builder that handles both syntax highlighting and graph rendering
class GraphElementBuilder extends MarkdownElementBuilder {
  final Map<String, TextStyle> codeTheme;
  final GraphRendererRegistry registry;
  
  GraphElementBuilder({
    required this.codeTheme,
    GraphRendererRegistry? registry,
  }) : registry = registry ?? GraphRendererRegistry();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'pre') {
      return _handlePreElement(element, preferredStyle);
    }
    return null;
  }
  
  Widget _handlePreElement(md.Element element, TextStyle? preferredStyle) {
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
    final renderer = registry.findRenderer(language ?? '');
    if (renderer != null) {
      return _buildGraphWidget(renderer, code, language);
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
  
  Widget _buildGraphWidget(GraphRenderer renderer, String content, String? language) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<Widget>(
          future: _renderGraph(renderer, content, context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GraphLoadingWidget(
                message: 'Rendering ${renderer.displayName}...',
              );
            }
            
            if (snapshot.hasError) {
              return GraphErrorWidget(
                error: snapshot.error.toString(),
                content: content,
                onRetry: () => setState(() {}),
              );
            }
            
            if (snapshot.hasData) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: snapshot.data!,
                ),
              );
            }
            
            // Should not reach here, but fallback to code block
            return _buildFallbackCodeBlock(content, language);
          },
        );
      },
    );
  }
  
  Future<Widget> _renderGraph(GraphRenderer renderer, String content, BuildContext context) async {
    try {
      // Validate content first
      final validation = renderer.validate(content);
      if (!validation.isValid) {
        throw Exception('Invalid graph syntax: ${validation.errors.join(', ')}');
      }
      
      // Extract metadata for potential customization
      final metadata = renderer.extractMetadata(content);
      
      // Create render options
      final options = GraphRenderOptions(
        theme: Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light',
        interactive: true,
      );
      
      // Render the graph
      final widget = await renderer.render(content, context, options: options);
      
      // Wrap with metadata if available
      if (metadata.title != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata.title != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  metadata.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            widget,
            if (metadata.description != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  metadata.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        );
      }
      
      return widget;
    } catch (e) {
      rethrow; // Let FutureBuilder handle the error
    }
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
            // Language label
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
            // Highlighted code
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
    // Normalize common language aliases
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

/// Service for initializing and managing graph renderers
class GraphRenderingService {
  static final GraphRenderingService _instance = GraphRenderingService._internal();
  factory GraphRenderingService() => _instance;
  GraphRenderingService._internal();
  
  final GraphRendererRegistry registry = GraphRendererRegistry();
  bool _initialized = false;
  
  /// Initialize all available graph renderers
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Import and register all available renderers
    await _registerAvailableRenderers();
    
    _initialized = true;
    debugPrint('Graph rendering service initialized with ${registry.renderers.length} renderers');
  }
  
  Future<void> _registerAvailableRenderers() async {
    // This will be populated as we implement each renderer
    // For now, we'll register them manually when they're created
    debugPrint('Graph renderers will be registered as they are implemented');
  }
  
  /// Get the enhanced element builder for markdown
  GraphElementBuilder createElementBuilder(BuildContext context) {
    final theme = Theme.of(context).brightness == Brightness.dark
        ? vs2015Theme
        : githubTheme;
        
    return GraphElementBuilder(
      codeTheme: theme,
      registry: registry,
    );
  }
  
  /// Check if a syntax is supported by any renderer
  bool isGraphSyntax(String? syntax) {
    if (syntax == null) return false;
    return registry.findRenderer(syntax) != null;
  }
  
  /// Get all supported graph syntaxes
  List<String> getSupportedSyntaxes() {
    return registry.supportedSyntaxes;
  }
}