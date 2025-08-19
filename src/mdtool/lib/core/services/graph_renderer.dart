import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Abstract base class for all graph renderers
abstract class GraphRenderer {
  /// Unique identifier for this renderer type
  String get type;
  
  /// List of syntax identifiers this renderer can handle
  List<String> get supportedSyntaxes;
  
  /// Human-readable name for this renderer
  String get displayName;
  
  /// Check if this renderer can handle the given syntax/language
  bool canRender(String syntax) {
    return supportedSyntaxes.contains(syntax.toLowerCase());
  }
  
  /// Render the graph content into a Flutter widget
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  });
  
  /// Extract any metadata from the code block (e.g., title, theme, etc.)
  GraphMetadata extractMetadata(String content) {
    return GraphMetadata();
  }
  
  /// Validate that the content can be rendered (optional pre-check)
  GraphValidationResult validate(String content) {
    return GraphValidationResult.valid();
  }
}

/// Configuration options for graph rendering
class GraphRenderOptions {
  final double? width;
  final double? height;
  final String? theme; // 'light', 'dark', 'auto'
  final bool interactive;
  final Map<String, dynamic>? customOptions;
  
  const GraphRenderOptions({
    this.width,
    this.height,
    this.theme,
    this.interactive = true,
    this.customOptions,
  });
  
  GraphRenderOptions copyWith({
    double? width,
    double? height,
    String? theme,
    bool? interactive,
    Map<String, dynamic>? customOptions,
  }) {
    return GraphRenderOptions(
      width: width ?? this.width,
      height: height ?? this.height,
      theme: theme ?? this.theme,
      interactive: interactive ?? this.interactive,
      customOptions: customOptions ?? this.customOptions,
    );
  }
}

/// Metadata extracted from graph content
class GraphMetadata {
  final String? title;
  final String? description;
  final Map<String, String>? attributes;
  
  const GraphMetadata({
    this.title,
    this.description,
    this.attributes,
  });
}

/// Result of content validation
class GraphValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const GraphValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
  
  GraphValidationResult.valid() : this(isValid: true);
  
  GraphValidationResult.invalid(List<String> errors) 
      : this(isValid: false, errors: errors);
      
  GraphValidationResult.withWarnings(List<String> warnings)
      : this(isValid: true, warnings: warnings);
}

/// Registry for managing all graph renderers
class GraphRendererRegistry {
  static final GraphRendererRegistry _instance = GraphRendererRegistry._internal();
  factory GraphRendererRegistry() => _instance;
  GraphRendererRegistry._internal();
  
  final List<GraphRenderer> _renderers = [];
  
  /// Register a new graph renderer
  void register(GraphRenderer renderer) {
    // Remove existing renderer of same type
    _renderers.removeWhere((r) => r.type == renderer.type);
    _renderers.add(renderer);
    debugPrint('Graph renderer registered: ${renderer.type} (${renderer.displayName})');
  }
  
  /// Unregister a renderer by type
  void unregister(String type) {
    _renderers.removeWhere((r) => r.type == type);
  }
  
  /// Find a renderer that can handle the given syntax
  GraphRenderer? findRenderer(String syntax) {
    for (final renderer in _renderers) {
      if (renderer.canRender(syntax)) {
        return renderer;
      }
    }
    return null;
  }
  
  /// Get all registered renderers
  List<GraphRenderer> get renderers => List.unmodifiable(_renderers);
  
  /// Get all supported syntaxes across all renderers
  List<String> get supportedSyntaxes {
    final syntaxes = <String>{};
    for (final renderer in _renderers) {
      syntaxes.addAll(renderer.supportedSyntaxes);
    }
    return syntaxes.toList();
  }
  
  /// Clear all registered renderers
  void clear() {
    _renderers.clear();
  }
}

/// Error widget for graph rendering failures
class GraphErrorWidget extends StatelessWidget {
  final String error;
  final String? content;
  final VoidCallback? onRetry;
  
  const GraphErrorWidget({
    super.key,
    required this.error,
    this.content,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Graph Rendering Error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading widget for graph rendering
class GraphLoadingWidget extends StatelessWidget {
  final String? message;
  
  const GraphLoadingWidget({
    super.key,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Main service for graph rendering functionality
class GraphRenderingService {
  final GraphRendererRegistry _registry = GraphRendererRegistry();
  bool _initialized = false;
  
  GraphRendererRegistry get registry => _registry;
  
  bool get isInitialized => _initialized;
  
  /// Initialize the graph rendering service
  Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('Initializing GraphRenderingService...');
    await _registerAvailableRenderers();
    _initialized = true;
    debugPrint('GraphRenderingService initialized with ${_registry.renderers.length} renderers');
  }
  
  /// Register all available renderers
  Future<void> _registerAvailableRenderers() async {
    // We can't import the renderers here due to circular dependencies
    // Instead, ensure the registry is shared globally and let renderers register themselves
    debugPrint('GraphRenderingService: Registry ready, renderers will register on first use');
  }
  
  /// Create a markdown element builder that can render graphs
  dynamic createElementBuilder(BuildContext context) {
    // This method is not used - element builders are created directly
    // by the UI components that need them
    throw UnimplementedError('Use GraphElementBuilder directly from ui/widgets/graph_element_builder.dart');
  }
  
  /// Render a graph with the given syntax and content
  Future<Widget> renderGraph(
    String syntax, 
    String content, 
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    final renderer = _registry.findRenderer(syntax);
    
    if (renderer == null) {
      return GraphErrorWidget(
        error: 'No renderer found for syntax: $syntax',
        content: content,
      );
    }
    
    try {
      // Validate content
      final validation = renderer.validate(content);
      if (!validation.isValid) {
        return GraphErrorWidget(
          error: 'Invalid content: ${validation.errors.join(', ')}',
          content: content,
        );
      }
      
      // Render the graph
      return await renderer.render(content, context, options: options);
    } catch (e) {
      return GraphErrorWidget(
        error: 'Rendering failed: $e',
        content: content,
      );
    }
  }
}

/// Static registry for renderers to register themselves
class RendererRegistry {
  static final GraphRendererRegistry _globalRegistry = GraphRendererRegistry();
  
  static void registerRenderer(GraphRenderer renderer) {
    _globalRegistry.register(renderer);
  }
  
  static GraphRendererRegistry get instance => _globalRegistry;
}