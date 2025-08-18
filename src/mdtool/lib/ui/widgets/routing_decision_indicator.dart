import 'package:flutter/material.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import '../../core/services/chat_service.dart';

/// Widget that shows AI routing decision information
class RoutingDecisionIndicator extends StatelessWidget {
  final RouteDecision routeDecision;
  final bool expanded;
  final VoidCallback? onToggle;

  const RoutingDecisionIndicator({
    super.key,
    required this.routeDecision,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _getProviderColor(theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getProviderColor(theme).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    _getProviderIcon(),
                    size: 16,
                    color: _getProviderColor(theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      routeDecision.reasoning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getProviderColor(theme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCostChip(theme),
                  if (onToggle != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: _getProviderColor(theme),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildDetailChip(
                    theme,
                    'Provider',
                    routeDecision.provider.displayName,
                    Icons.cloud,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    theme,
                    'Confidence',
                    '${(routeDecision.confidence * 100).toInt()}%',
                    Icons.psychology,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    theme,
                    'Cost',
                    _formatCost(routeDecision.estimatedCost),
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getProviderColor(ThemeData theme) {
    switch (routeDecision.provider) {
      case AIProvider.ollama:
        return Colors.green;
      case AIProvider.openai:
        return Colors.blue;
    }
  }

  IconData _getProviderIcon() {
    switch (routeDecision.provider) {
      case AIProvider.ollama:
        return Icons.computer;
      case AIProvider.openai:
        return Icons.cloud;
    }
  }

  Widget _buildCostChip(ThemeData theme) {
    final cost = routeDecision.estimatedCost;
    final isFree = cost == 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFree ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFree ? 'FREE' : _formatCost(cost),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isFree ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDetailChip(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getProviderColor(theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _getProviderColor(theme)),
          const SizedBox(width: 3),
          Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getProviderColor(theme),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost == 0.0) return 'FREE';
    if (cost < 0.001) return '\$0.00';
    if (cost < 0.01) return '\$${cost.toStringAsFixed(3)}';
    return '\$${cost.toStringAsFixed(2)}';
  }
}

/// Compact routing indicator for status display
class CompactRoutingIndicator extends StatelessWidget {
  final RouteDecision? routeDecision;
  final AIRoutingMode currentMode;

  const CompactRoutingIndicator({
    super.key,
    this.routeDecision,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (currentMode == AIRoutingMode.manual) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, size: 12, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              'Manual',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (routeDecision == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              'Auto',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    final providerColor = routeDecision!.provider == AIProvider.ollama 
        ? Colors.green 
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: providerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            routeDecision!.provider == AIProvider.ollama 
                ? Icons.computer 
                : Icons.cloud,
            size: 12,
            color: providerColor,
          ),
          const SizedBox(width: 4),
          Text(
            routeDecision!.provider.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: providerColor,
              fontSize: 10,
            ),
          ),
          if (routeDecision!.estimatedCost == 0.0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'FREE',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}