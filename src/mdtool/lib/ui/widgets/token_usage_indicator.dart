import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/metrics_provider.dart';
import '../../core/services/metrics_service.dart';

/// Widget that displays live token usage information
class TokenUsageIndicator extends ConsumerWidget {
  final bool isCompact;
  final bool showDetails;

  const TokenUsageIndicator({
    super.key,
    this.isCompact = false,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageSummaryAsync = ref.watch(usageSummaryProvider);
    final isBlocked = ref.watch(isUsageBlockedProvider);

    return usageSummaryAsync.when(
      data: (summary) => _buildUsageIndicator(context, summary, isBlocked),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildUsageIndicator(BuildContext context, UsageSummary summary, bool isBlocked) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color based on usage
    Color statusColor;
    if (isBlocked) {
      statusColor = colorScheme.error;
    } else if (summary.dailyTokenPercentage > 80 || summary.dailyCostPercentage > 80) {
      statusColor = Colors.orange;
    } else if (summary.dailyTokenPercentage > 50 || summary.dailyCostPercentage > 50) {
      statusColor = Colors.yellow.shade700;
    } else {
      statusColor = Colors.green;
    }

    if (isCompact) {
      return _buildCompactIndicator(context, summary, statusColor, isBlocked);
    } else {
      return _buildDetailedIndicator(context, summary, statusColor, isBlocked);
    }
  }

  Widget _buildCompactIndicator(BuildContext context, UsageSummary summary, Color statusColor, bool isBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBlocked ? Icons.block : Icons.token,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            isBlocked 
              ? 'OpenAI Blocked' 
              : 'OpenAI: ${_formatNumber(summary.totalTokensToday)}/${_formatCurrency(summary.totalCostToday)}',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedIndicator(BuildContext context, UsageSummary summary, Color statusColor, bool isBlocked) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.block : Icons.analytics_outlined,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'OpenAI Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isBlocked)
                  Chip(
                    label: const Text('BLOCKED'),
                    backgroundColor: statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (showDetails) ...[
              _buildUsageRow(
                context,
                'Today',
                '${_formatNumber(summary.totalTokensToday)} tokens',
                '\$${summary.totalCostToday.toStringAsFixed(3)}',
                summary.dailyTokenPercentage.isFinite ? summary.dailyTokenPercentage : 0,
                summary.dailyCostPercentage.isFinite ? summary.dailyCostPercentage : 0,
                statusColor,
              ),
              const SizedBox(height: 12),
              _buildUsageRow(
                context,
                'This Month',
                '${_formatNumber(summary.totalTokensThisMonth)} tokens',
                '\$${summary.totalCostThisMonth.toStringAsFixed(3)}',
                summary.monthlyTokenPercentage.isFinite ? summary.monthlyTokenPercentage : 0,
                summary.monthlyCostPercentage.isFinite ? summary.monthlyCostPercentage : 0,
                statusColor,
              ),
            ],
            if (isBlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OpenAI usage limits exceeded. Adjust limits in preferences or use Ollama.',
                        style: TextStyle(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(
    BuildContext context,
    String period,
    String tokenUsage,
    String cost,
    double tokenPercentage,
    double costPercentage,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              period,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$tokenUsage • $cost',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildProgressBar(tokenPercentage, statusColor, 'Tokens'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProgressBar(costPercentage, statusColor, 'Cost'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percentage, Color statusColor, String label) {
    final clampedPercentage = percentage.clamp(0.0, 100.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${clampedPercentage.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: clampedPercentage / 100,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          minHeight: 4,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(3);
  }
}

/// Message-specific token usage display
class MessageTokenUsage extends StatelessWidget {
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final double? cost;

  const MessageTokenUsage({
    super.key,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.cost,
  });

  @override
  Widget build(BuildContext context) {
    if (totalTokens == null || totalTokens == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.token,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '${totalTokens} tokens',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          if (cost != null && cost! > 0) ...[
            const SizedBox(width: 8),
            Text(
              '\$${cost!.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}