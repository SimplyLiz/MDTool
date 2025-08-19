import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../graph_renderer.dart';
import '../webview_pool.dart';

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
    return _PooledMermaidWebView(
      content: content,
      theme: options?.theme ?? 
          (Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light'),
      options: options,
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
  
}

class _PooledMermaidWebView extends StatefulWidget {
  final String content;
  final String theme;
  final GraphRenderOptions? options;

  const _PooledMermaidWebView({
    required this.content,
    required this.theme,
    this.options,
  });

  @override
  State<_PooledMermaidWebView> createState() => _PooledMermaidWebViewState();
}

class _PooledMermaidWebViewState extends State<_PooledMermaidWebView> {
  WebViewController? controller;
  double height = 200; // Initial height, will be updated by JS
  final WebViewPool _pool = WebViewPool();
  bool _isLoading = true;
  late final String _channelName; // Unique channel name for this instance

  @override
  void initState() {
    super.initState();
    _channelName = 'HeightChannel_${DateTime.now().millisecondsSinceEpoch}_$hashCode';
    _initializeWebView();
  }

  @override
  void dispose() {
    // Return controller to pool for reuse
    if (controller != null) {
      _pool.returnController(controller!);
    }
    super.dispose();
  }

  void _initializeWebView() async {
    try {
      // Get controller from pool (much faster than creating new one)
      controller = await _pool.getController();
      
      // Add a unique height channel for this instance
      await controller!.addJavaScriptChannel(
        _channelName,
        onMessageReceived: (JavaScriptMessage message) {
          final newHeight = double.tryParse(message.message);
          if (newHeight != null && mounted) {
            setState(() {
              height = newHeight;
            });
          }
        },
      );
      
      // Get optimized HTML template
      final html = await WebViewPool.getMermaidHTML(
        widget.theme,
        backgroundColorCss: widget.options?.backgroundColorCss,
      );
      
      await controller!.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // Minimal delay for DOM readiness
            Future.delayed(const Duration(milliseconds: 50), () {
              final escapedContent = _escapeContent(widget.content);
              controller!.runJavaScript('''
                // Set the channel name for this chart instance
                window.currentHeightChannel = '$_channelName';
                if (window.renderMermaid) {
                  window.renderMermaid(`$escapedContent`);
                }
              ''');
            });
          },
        ),
      );
      
      await controller!.loadHtmlString(html);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize pooled WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _escapeContent(String content) {
    return content
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\\', '\\\\');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || controller == null) {
      return Container(
        width: widget.options?.width ?? double.infinity,
        height: 200,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading Mermaid chart...'),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.options?.width ?? double.infinity,
      height: widget.options?.height ?? height,
      child: WebViewWidget(controller: controller!),
    );
  }
}