import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/services/graph_renderer.dart';
import '../../core/services/renderers/mermaid_renderer.dart';
import '../../core/services/renderers/chart_renderer.dart';
import '../../core/services/renderers/simple_chart_renderer.dart';
import '../themes/app_theme.dart';

/// Enhanced code element builder that handles both syntax highlighting and graph rendering
class GraphElementBuilder extends MarkdownElementBuilder {
  final Map<String, TextStyle> codeTheme;
  final GraphRendererRegistry registry;
  
  GraphElementBuilder({
    required this.codeTheme,
    GraphRendererRegistry? registry,
  }) : registry = registry ?? GraphRendererRegistry() {
    // Ensure renderers are registered
    GraphElementService.ensureRenderersRegistered(this.registry);
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'pre') {
      return _handlePreElement(element, preferredStyle);
    }
    return null;
  }
  
  @override
  bool visitElementBefore(md.Element element) {
    // For 'pre' elements that we will handle, prevent default processing
    if (element.tag == 'pre') {
      final codeElement = element.children?.firstWhere(
        (child) => child is md.Element && child.tag == 'code',
        orElse: () => element,
      ) as md.Element?;
      
      if (codeElement != null) {
        final language = _extractLanguage(codeElement);
        if (language != null && registry.findRenderer(language) != null) {
          return false; // We'll handle this, don't let flutter_markdown process it
        }
      }
    }
    return true; // Let flutter_markdown handle other elements
  }
  
  // Remove visitElementBefore - it's causing assertion errors in flutter_markdown
  
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
    
    // Only process fenced code blocks (those with language specifiers)
    if (language == null || language.isEmpty) {
      return _buildFallbackCodeBlock(code, null); // Handle inline code normally
    }
    
    // Try to render as graph first
    
    final renderer = registry.findRenderer(language);
    if (renderer != null) {
      final widget = _buildGraphWidget(renderer, code, language);
      return widget;
    }
    
    // Fall back to syntax highlighting
    return _buildSyntaxHighlightedCode(code, language);
  }
  
  Widget _handleCodeElement(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = _extractLanguage(element);
    
    // Only process fenced code blocks (those with language specifiers)
    if (language == null || language.isEmpty) {
      return _buildFallbackCodeBlock(code, null); // Handle inline code normally
    }
    
    // Try to render as graph first
    
    final renderer = registry.findRenderer(language);
    if (renderer != null) {
      final widget = _buildGraphWidget(renderer, code, language);
      return widget;
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
              return _buildCodeBlockStyle(snapshot.data!, language ?? '', content, context);
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

  Widget _buildCodeBlockStyle(Widget chartWidget, String language, String originalContent, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language label and copy button (same as code blocks)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkTheme 
                ? colorScheme.surfaceContainerHigh 
                : colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontFamily: 'Monaco',
                  ),
                ),
                const Spacer(),
                // Copy button for chart source
                _GraphCopyButton(code: originalContent, context: context),
              ],
            ),
          ),
          // Chart content
          Padding(
            padding: const EdgeInsets.all(12),
            child: chartWidget,
          ),
        ],
      ),
    );
  }
}

class _GraphCopyButton extends StatefulWidget {
  final String code;
  final BuildContext context;

  const _GraphCopyButton({required this.code, required this.context});

  @override
  State<_GraphCopyButton> createState() => _GraphCopyButtonState();
}

class _GraphCopyButtonState extends State<_GraphCopyButton> {
  bool _isCopied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));

    setState(() {
      _isCopied = true;
    });

    // Reset the copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isCopied 
            ? (isDarkTheme ? Colors.green.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.1)) 
            : colorScheme.onSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCopied ? Icons.check : Icons.copy,
              size: 14,
              color: _isCopied 
                ? Colors.green 
                : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              _isCopied ? 'Copied!' : 'Copy',
              style: TextStyle(
                fontSize: 11,
                color: _isCopied 
                  ? Colors.green 
                  : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service for initializing graph renderers in the element builder
class GraphElementService {
  static void ensureRenderersRegistered(GraphRendererRegistry registry) {
    
    // Check if renderers are already registered
    if (registry.renderers.isNotEmpty) {
      return;
    }
    
    
    // Register all available renderers
    try {
      registry.register(MermaidRenderer());
      
      registry.register(ChartRenderer());
      
      registry.register(SimpleChartRenderer());
      
    } catch (e) {
    }
  }
}