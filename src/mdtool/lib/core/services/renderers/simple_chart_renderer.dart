import 'package:flutter/material.dart';
import '../graph_renderer.dart';

/// Simplified chart renderer with basic implementation
class SimpleChartRenderer extends GraphRenderer {
  @override
  String get type => 'chart';
  
  @override
  String get displayName => 'Simple Charts';
  
  @override
  List<String> get supportedSyntaxes => [
    'chart',
    'barchart',
    'linechart',
    'piechart',
    'scatterchart',
    'areachart',
  ];
  
  @override
  Future<Widget> render(
    String content,
    BuildContext context, {
    GraphRenderOptions? options,
  }) async {
    return Container(
      height: options?.height ?? 300,
      width: options?.width ?? double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Chart Rendering',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Chart content will be rendered here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              content.length > 100 ? '${content.substring(0, 100)}...' : content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  GraphMetadata extractMetadata(String content) {
    return GraphMetadata(
      title: 'Chart',
      attributes: {
        'type': 'Simple Chart',
        'content_length': content.length.toString(),
      },
    );
  }
  
  @override
  GraphValidationResult validate(String content) {
    if (content.trim().isEmpty) {
      return GraphValidationResult.invalid(['Chart content cannot be empty']);
    }
    return GraphValidationResult.valid();
  }
}