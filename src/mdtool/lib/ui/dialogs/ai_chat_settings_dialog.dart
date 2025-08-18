import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/document_index_service.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import 'context_strategy_settings_dialog.dart';
import 'usage_limits_dialog.dart';
import 'ai_analytics_dialog.dart';

class AIChatSettingsDialog extends ConsumerStatefulWidget {
  const AIChatSettingsDialog({super.key});

  @override
  ConsumerState<AIChatSettingsDialog> createState() => _AIChatSettingsDialogState();
}

class _AIChatSettingsDialogState extends ConsumerState<AIChatSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService.instance;
  final DocumentIndexService _documentIndex = DocumentIndexService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.8).clamp(500.0, 700.0);
    final dialogHeight = (screenSize.height * 0.8).clamp(400.0, 600.0);
    
    return Dialog(
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
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
                  Icon(Icons.settings, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'AI Chat Settings',
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
                Tab(icon: Icon(Icons.library_books), text: 'Context'),
                Tab(icon: Icon(Icons.language), text: 'Web Search'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContextTab(),
                  _buildWebSearchTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextTab() {
    final documentStats = _chatService.getDocumentStats();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatRow('Total Documents', '${documentStats['totalDocuments']}'),
                  _buildStatRow('Unique Tags', '${documentStats['uniqueTags']}'),
                  _buildStatRow('Recent Documents', '${documentStats['recentDocuments']} (last 7 days)'),
                  
                  if (documentStats['oldestDocument'] != null)
                    _buildStatRow('Oldest Document', _formatDate(documentStats['oldestDocument'])),
                  if (documentStats['newestDocument'] != null)
                    _buildStatRow('Newest Document', _formatDate(documentStats['newestDocument'])),

                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _refreshDocuments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Documents'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Context strategy info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Context Strategy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const ContextStrategySettingsDialog(),
                        ),
                        icon: const Icon(Icons.tune),
                        label: const Text('Configure'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Active Strategy: ${ContextStrategyManager.instance.activeStrategy.name}'),
                  const SizedBox(height: 8),
                  Text('Description: ${ContextStrategyManager.instance.activeStrategy.description}'),
                  const SizedBox(height: 8),
                  Text('Configuration: ${ContextStrategyManager.instance.activeStrategy.getConfigExplanation()}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Web search configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Web Search Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final preferences = ref.watch(preferencesProvider).valueOrNull;
                      final isWebSearchConfigured = preferences?.webSearchEnabled ?? false;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Web Search'),
                            subtitle: Text(isWebSearchConfigured 
                                ? 'Include web search results in AI responses'
                                : 'Configure Google Custom Search API in main Preferences'),
                            value: isWebSearchConfigured,
                            onChanged: (value) {
                              ref.read(preferencesProvider.notifier).setWebSearchEnabled(value);
                            },
                          ),
                          
                          if (!isWebSearchConfigured)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange[700]),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'To enable web search, configure Google Custom Search API in the main Preferences dialog (Web Search Integration section).',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (isWebSearchConfigured) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Web search is configured and ready to use. Toggle it on/off in individual conversations using the web search button.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Web search info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Web Search Works',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('• Web search results are automatically included when enabled'),
                  const SizedBox(height: 4),
                  const Text('• Search queries are based on your conversation message'),
                  const SizedBox(height: 4),
                  const Text('• Results are combined with document context for comprehensive answers'),
                  const SizedBox(height: 4),
                  const Text('• Fallback mode provides demo results when API is not configured'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick analytics overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Usage Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AIAnalyticsDialog(),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Detailed Analytics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Token usage indicator would go here
                  const Text('View detailed token usage, costs, and AI routing decisions in the full analytics dialog.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI routing settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Routing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Current Mode: ${AIRoutingManager.instance.mode}'),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const UsageLimitsDialog(),
                    ),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Usage Limits'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recent usage
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatRow('Total Messages', '${_chatService.messages.length}'),
                  _buildStatRow('Document Context Available', '${_chatService.hasDocumentContext}'),
                ],
              ),
            ),
          ),
        ],
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

  Future<void> _refreshDocuments() async {
    await _documentIndex.refreshIndex();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents refreshed successfully')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}