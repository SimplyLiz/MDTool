import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/context_strategies/context_strategy.dart';

/// Provider for the last context result (to be used when available)
final lastContextResultProvider = StateProvider<ContextResult?>(
  (ref) => null,
);

/// Status indicator showing current context strategy and recent usage
class ContextStatusIndicator extends ConsumerWidget {
  const ContextStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final manager = ContextStrategyManager.instance;
    final lastResult = ref.watch(lastContextResultProvider);

    return StreamBuilder<ContextStrategy>(
      stream: manager.activeStrategyStream,
      initialData: manager.activeStrategy,
      builder: (context, snapshot) {
        final activeStrategy = snapshot.data ?? manager.activeStrategy;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                _getStatusText(activeStrategy, lastResult),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (lastResult != null) ...[
                const SizedBox(width: 4),
                Text(
                  '•',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getCostText(lastResult),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(ContextStrategy strategy, ContextResult? lastResult) {
    if (lastResult != null) {
      final fileCount = lastResult.filesUsed.length;
      final tokenCount = lastResult.tokenCount;
      
      return '${strategy.name}: ${fileCount} file${fileCount == 1 ? '' : 's'}, ${_formatTokenCount(tokenCount)}';
    }
    
    return strategy.name;
  }

  String _getCostText(ContextResult result) {
    if (result.estimatedCost < 0.001) {
      return '\$0.00';
    } else if (result.estimatedCost < 0.01) {
      return '\$${result.estimatedCost.toStringAsFixed(3)}';
    } else {
      return '\$${result.estimatedCost.toStringAsFixed(2)}';
    }
  }

  String _formatTokenCount(int tokens) {
    if (tokens < 1000) {
      return '${tokens}t';
    } else {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
  }
}

/// Detailed context info tooltip widget
class ContextInfoTooltip extends ConsumerWidget {
  final ContextResult contextResult;
  
  const ContextInfoTooltip({
    super.key,
    required this.contextResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Context Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow('Strategy', contextResult.strategyUsed),
            _buildInfoRow('Files Used', '${contextResult.filesUsed.length}'),
            _buildInfoRow('Token Count', _formatTokenCount(contextResult.tokenCount)),
            _buildInfoRow('Estimated Cost', _getCostText(contextResult)),
            
            if (contextResult.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Explanation:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contextResult.explanation,
                style: theme.textTheme.bodySmall,
              ),
            ],
            
            if (contextResult.filesUsed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Files:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...contextResult.filesUsed.take(3).map(
                (file) => Text(
                  '• ${_getFileName(file)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (contextResult.filesUsed.length > 3)
                Text(
                  '• ...and ${contextResult.filesUsed.length - 3} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getCostText(ContextResult result) {
    if (result.estimatedCost < 0.001) {
      return '\$0.00';
    } else if (result.estimatedCost < 0.01) {
      return '\$${result.estimatedCost.toStringAsFixed(3)}';
    } else {
      return '\$${result.estimatedCost.toStringAsFixed(2)}';
    }
  }

  String _formatTokenCount(int tokens) {
    if (tokens < 1000) {
      return '$tokens tokens';
    } else {
      return '${(tokens / 1000).toStringAsFixed(1)}k tokens';
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }
}

/// Expandable context usage widget for chat interface
class ContextUsageIndicator extends ConsumerWidget {
  final ContextResult? contextResult;
  final bool expanded;
  final VoidCallback? onToggle;
  
  const ContextUsageIndicator({
    super.key,
    this.contextResult,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contextResult == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contextResult!.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCostText(contextResult!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (onToggle != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatChip(
                        context,
                        'Files',
                        '${contextResult!.filesUsed.length}',
                        Icons.description,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        'Tokens',
                        _formatTokenCount(contextResult!.tokenCount),
                        Icons.data_usage,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        'Strategy',
                        _getStrategyShortName(contextResult!.strategyUsed),
                        Icons.psychology,
                      ),
                    ],
                  ),
                  if (contextResult!.filesUsed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Files included:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: contextResult!.filesUsed.map(
                        (file) => Chip(
                          label: Text(
                            _getFileName(file),
                            style: theme.textTheme.bodySmall,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCostText(ContextResult result) {
    if (result.estimatedCost < 0.001) {
      return '\$0.00';
    } else if (result.estimatedCost < 0.01) {
      return '\$${result.estimatedCost.toStringAsFixed(3)}';
    } else {
      return '\$${result.estimatedCost.toStringAsFixed(2)}';
    }
  }

  String _formatTokenCount(int tokens) {
    if (tokens < 1000) {
      return '${tokens}t';
    } else {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _getStrategyShortName(String strategyName) {
    if (strategyName == 'Progressive Context') return 'Progressive';
    if (strategyName == 'Simple Context') return 'Simple';
    return strategyName;
  }
}