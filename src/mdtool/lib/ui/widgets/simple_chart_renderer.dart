import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  renderer.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontFamily: 'Monaco',
                  ),
                ),
                const Spacer(),
                // Copy button for chart source
                _ChartCopyButton(code: content, context: context),
              ],
            ),
          ),
          // Chart content
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<Widget>(
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
              return snapshot.data!;
            }
            
            return const SizedBox.shrink();
              },
            ),
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
      
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      
      final options = GraphRenderOptions(
        theme: theme.brightness == Brightness.dark ? 'dark' : 'light',
        interactive: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
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

class _ChartCopyButton extends StatefulWidget {
  final String code;
  final BuildContext context;

  const _ChartCopyButton({required this.code, required this.context});

  @override
  State<_ChartCopyButton> createState() => _ChartCopyButtonState();
}

class _ChartCopyButtonState extends State<_ChartCopyButton> {
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