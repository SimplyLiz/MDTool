import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/ai/ai_analytics_service.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import '../../core/services/chat_service.dart';

class AIAnalyticsDialog extends StatefulWidget {
  const AIAnalyticsDialog({super.key});

  @override
  State<AIAnalyticsDialog> createState() => _AIAnalyticsDialogState();
}

class _AIAnalyticsDialogState extends State<AIAnalyticsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CostSavingsAnalysis? _analysis;
  ThresholdOptimization? _optimization;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      await AIAnalyticsService.instance.initialize();
      final analysis = AIAnalyticsService.instance.getCostSavingsAnalysis();
      final optimization = AIAnalyticsService.instance.getThresholdOptimization();
      
      setState(() {
        _analysis = analysis;
        _optimization = optimization;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'AI Cost Analytics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.savings), text: 'Cost Savings'),
                Tab(icon: Icon(Icons.tune), text: 'Optimization'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Usage Stats'),
              ],
            ),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCostSavingsTab(),
                        _buildOptimizationTab(),
                        _buildUsageStatsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSavingsTab() {
    if (_analysis == null) {
      return const Center(child: Text('No data available'));
    }

    final analysis = _analysis!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Saved',
                  '\$${analysis.totalCostSaved.toStringAsFixed(2)}',
                  Icons.savings,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  '\$${analysis.totalSpent.toStringAsFixed(2)}',
                  Icons.payment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Savings %',
                  '${analysis.averageSavingsPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  analysis.averageSavingsPercentage > 50 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detailed Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatRow('Total Queries', '${analysis.totalQueries}'),
                      ),
                      Expanded(
                        child: _buildStatRow('Auto-Routed', '${analysis.autoRoutedQueries}'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatRow('Local AI Usage', '${analysis.localQueries}'),
                      ),
                      Expanded(
                        child: _buildStatRow('Cloud AI Usage', '${analysis.cloudQueries}'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text('Weekly Trend: ${analysis.weeklyTrend >= 0 ? '+' : ''}${analysis.weeklyTrend.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Query Complexity Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Query Complexity Distribution',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...QueryComplexity.values.map((complexity) {
                    final count = analysis.queriesByComplexity[complexity] ?? 0;
                    final percentage = analysis.totalQueries > 0 
                        ? (count / analysis.totalQueries * 100)
                        : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(complexity.name.toUpperCase()),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count (${percentage.toStringAsFixed(1)}%)'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    if (_optimization == null) {
      return const Center(child: Text('No optimization data available'));
    }

    final optimization = _optimization!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current vs Recommended
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Threshold Optimization',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildThresholdComparison(
                    'Local AI Threshold',
                    optimization.currentLocalThreshold,
                    optimization.recommendedLocalThreshold,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildThresholdComparison(
                    'Cost Savings Target',
                    optimization.currentCostTarget,
                    optimization.recommendedCostTarget,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Optimization Recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text('${(optimization.confidenceScore * 100).toInt()}% confidence'),
                        backgroundColor: optimization.confidenceScore >= 0.7 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text(optimization.reasoning),
                  
                  const SizedBox(height: 16),
                  
                  Text('Sample Size: ${optimization.sampleSize} queries'),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: optimization.confidenceScore >= 0.7
                            ? () => _applyOptimization(optimization)
                            : null,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Apply Optimization'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _resetThresholds(),
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to Defaults'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Auto-Optimization Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Optimization Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Enable Auto-Optimization'),
                    subtitle: const Text('Automatically adjust thresholds based on usage patterns'),
                    value: AIRoutingManager.instance.autoOptimizeThresholds,
                    onChanged: (value) {
                      setState(() {
                        AIRoutingManager.instance.setAutoOptimization(value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsTab() {
    final recentMetrics = AIAnalyticsService.instance.getRecentMetrics(limit: 20);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Usage',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _exportAnalytics,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Data'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (recentMetrics.isEmpty)
            const Center(
              child: Text('No usage data available yet'),
            )
          else
            ...recentMetrics.map((metric) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  metric.provider == AIProvider.ollama 
                      ? Icons.computer 
                      : Icons.cloud,
                  color: metric.provider == AIProvider.ollama 
                      ? Colors.green 
                      : Colors.blue,
                ),
                title: Text(
                  '${metric.provider.displayName} • ${metric.complexity.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost: \$${metric.actualCost.toStringAsFixed(3)}'),
                    Text('Saved: \$${metric.estimatedSavings.toStringAsFixed(3)}'),
                    Text('${metric.wasAutoRouted ? 'Auto' : 'Manual'} • ${(metric.confidence * 100).toInt()}% confidence'),
                  ],
                ),
                trailing: Text(
                  _formatTime(metric.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildThresholdComparison(String label, double current, double recommended) {
    final isDifferent = (current - recommended).abs() > 0.05;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current', style: TextStyle(fontSize: 12)),
                  Text(
                    current.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDifferent ? Colors.grey : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Recommended', style: TextStyle(fontSize: 12)),
                  Text(
                    recommended.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDifferent ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _applyOptimization(ThresholdOptimization optimization) async {
    try {
      await AIAnalyticsService.instance.applyThresholdOptimization(optimization);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Optimization applied successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAnalytics(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying optimization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetThresholds() {
    AIRoutingManager.instance.setThresholds(
      localThreshold: 0.8,
      costSavingsTarget: 0.7,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thresholds reset to defaults'),
      ),
    );
    
    _loadAnalytics(); // Refresh data
  }

  void _exportAnalytics() {
    final analyticsData = AIAnalyticsService.instance.exportAnalyticsAsJson();
    Clipboard.setData(ClipboardData(text: analyticsData));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics data copied to clipboard'),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}