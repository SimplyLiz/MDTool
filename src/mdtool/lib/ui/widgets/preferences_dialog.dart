import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import '../dialogs/context_strategy_settings_dialog.dart';
import '../dialogs/ai_analytics_dialog.dart';
import 'ollama_help_screen.dart';
import '../../core/services/ollama_service.dart';
import 'ai/settings/ai_worker_settings_page.dart';

class PreferencesDialog extends ConsumerStatefulWidget {
  const PreferencesDialog({super.key});

  @override
  ConsumerState<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends ConsumerState<PreferencesDialog> {
  bool? _isOllamaAvailable;

  @override
  void initState() {
    super.initState();
    _checkOllamaAvailability();
  }

  Future<void> _checkOllamaAvailability() async {
    final isRunning = await OllamaService.instance.isRunning();
    if (mounted) {
      setState(() {
        _isOllamaAvailable = isRunning;
      });
    }
  }

  // Helper method to ensure the OpenAI model value is valid
  String _getValidOpenaiModel(String currentModel) {
    const validModels = [
      'gpt-5',
      'gpt-5-mini',
      'gpt-5-nano',
    ];
    
    return validModels.contains(currentModel) ? currentModel : 'gpt-5';
  }

  void _showContextStrategyHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Smart Context Assembly',
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
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: const SingleChildScrollView(
                  child: Text(
                    '''Smart Context Assembly automatically optimizes how much information to send to AI based on your question type.

🧠 How it works:
• Analyzes your question to understand complexity
• Simple questions (grammar, spelling) get minimal context
• Complex questions (architecture, design) get comprehensive context
• Automatically finds related documents in your project

💰 Cost savings:
• Simple queries: ~\$0.005 (vs \$0.03 without optimization)
• Medium queries: ~\$0.02 (vs \$0.12 without optimization)  
• Complex queries: ~\$0.06 (vs \$0.20 without optimization)
• Average savings: 60-70% reduction in AI costs

⚡ Performance benefits:
• Faster responses for simple questions
• Better answers through right-sized context
• No manual file selection needed
• Works automatically in the background

🎯 Example:
• "Fix this grammar" → Uses current document only
• "How to implement navigation?" → Includes related files
• "Redesign app architecture" → Full project context

The AI gets exactly the right amount of information for your question type, saving you money while providing better, more relevant answers.''',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openContextStrategySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ContextStrategySettingsDialog(),
    );
  }

  void _openAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AIAnalyticsDialog(),
    );
  }

  void _showRoutingHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cost-Intelligent AI Routing',
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
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Text(
                    AIRoutingManager.instance.getHelpText(),
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutingModeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final routingManager = AIRoutingManager.instance;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<AIRoutingMode>(
                title: const Text('Manual'),
                subtitle: const Text('I choose the AI provider'),
                value: AIRoutingMode.manual,
                groupValue: routingManager.mode,
                onChanged: (value) {
                  if (value != null) {
                    routingManager.setMode(value);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<AIRoutingMode>(
                title: const Text('Auto'),
                subtitle: const Text('AI chooses automatically'),
                value: AIRoutingMode.auto,
                groupValue: routingManager.mode,
                onChanged: (value) {
                  if (value != null) {
                    routingManager.setMode(value);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                routingManager.mode == AIRoutingMode.auto 
                    ? Icons.auto_awesome 
                    : Icons.settings,
                size: 16,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routingManager.mode == AIRoutingMode.auto
                      ? 'Auto mode: Saves 80-85% on AI costs automatically'
                      : 'Manual mode: You select the provider for each conversation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOllamaWarningSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ollama Not Installed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ollama is not installed or not running. Install Ollama to use local AI models.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OllamaHelpScreen(),
                ),
              );
            },
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text('How to Install'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(preferencesProvider);

    return preferencesAsync.when(
      data: (preferences) => AlertDialog(
        title: const Text('Preferences'),
        content: SizedBox(
          width: 400,
          height: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Font Size Setting
                Text('Font Size', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: preferences.fontSize,
                        min: 10.0,
                        max: 24.0,
                        divisions: 14,
                        label: preferences.fontSize.round().toString(),
                        onChanged: (value) {
                          ref.read(preferencesProvider.notifier).setFontSize(value);
                        },
                      ),
                    ),
                    SizedBox(width: 40, child: Text('${preferences.fontSize.round()}pt', textAlign: TextAlign.center)),
                  ],
                ),
                const SizedBox(height: 16),

                // Theme Setting
                Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: preferences.isDarkMode,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setDarkMode(value);
                  },
                ),
                const SizedBox(height: 8),

                // Editor Settings
                Text('Editor', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Word Wrap'),
                  subtitle: const Text('Wrap long lines'),
                  value: preferences.wordWrap,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setWordWrap(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Line Numbers'),
                  subtitle: const Text('Show line numbers in editor'),
                  value: preferences.showLineNumbers,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setShowLineNumbers(value);
                  },
                ),
                const SizedBox(height: 16),

                // File Browser Settings
                Text('File Browser', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Filter Directories'),
                  subtitle: const Text('Hide .git, node_modules, build folders, etc.'),
                  value: preferences.filterDirectories,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setFilterDirectories(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-navigate to file folder'),
                  subtitle: const Text('Automatically show opened file\'s folder in sidebar'),
                  value: preferences.autoNavigateToFileFolder,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setAutoNavigateToFileFolder(value);
                  },
                ),
                const SizedBox(height: 16),

                // Preview Settings
                Text('Preview Mode', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Auto-switch to edit mode'),
                  subtitle: const Text('When opening preview, switch main window to edit mode'),
                  value: preferences.previewAutoEdit,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setPreviewAutoEdit(value);
                  },
                ),
                const SizedBox(height: 16),

                // Font Family Setting
                Text('Font Family', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: preferences.fontFamily,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'SF Pro Text', child: Text('SF Pro Text')),
                    DropdownMenuItem(value: 'Monaco', child: Text('Monaco')),
                    DropdownMenuItem(value: 'Consolas', child: Text('Consolas')),
                    DropdownMenuItem(value: 'Courier New', child: Text('Courier New')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(preferencesProvider.notifier).setFontFamily(value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Ollama Settings
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Ollama Integration', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const OllamaHelpScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.help_outline, size: 16),
                          label: const Text('Setup Help'),
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !preferences.ollamaEnabled
                                ? Colors.grey.withValues(alpha: 0.1)
                                : _isOllamaAvailable == true 
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : _isOllamaAvailable == false 
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !preferences.ollamaEnabled
                                  ? Colors.grey.withValues(alpha: 0.5)
                                  : _isOllamaAvailable == true 
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : _isOllamaAvailable == false 
                                          ? Colors.red.withValues(alpha: 0.5)
                                          : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                !preferences.ollamaEnabled
                                    ? Icons.power_settings_new
                                    : _isOllamaAvailable == true 
                                        ? Icons.check_circle 
                                        : _isOllamaAvailable == false 
                                            ? Icons.cancel
                                            : Icons.refresh,
                                size: 14,
                                color: !preferences.ollamaEnabled
                                    ? Colors.grey[700]
                                    : _isOllamaAvailable == true 
                                        ? Colors.green[700]
                                        : _isOllamaAvailable == false 
                                            ? Colors.red[700]
                                            : Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                !preferences.ollamaEnabled
                                    ? 'Disabled'
                                    : _isOllamaAvailable == true 
                                        ? 'Connected'
                                        : _isOllamaAvailable == false 
                                            ? 'Not Connected'
                                            : 'Checking...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: !preferences.ollamaEnabled
                                      ? Colors.grey[700]
                                      : _isOllamaAvailable == true 
                                          ? Colors.green[700]
                                          : _isOllamaAvailable == false 
                                              ? Colors.red[700]
                                              : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isOllamaAvailable == null ? null : _checkOllamaAvailability,
                          icon: const Icon(Icons.refresh, size: 16),
                          tooltip: 'Refresh connection status',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Check Ollama availability
                if (_isOllamaAvailable == false) ...[
                  _buildOllamaWarningSection(context),
                ] else if (_isOllamaAvailable == null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Checking Ollama availability...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SwitchListTile(
                    title: const Text('Enable Ollama'),
                    subtitle: const Text('Connect to local Ollama server'),
                    value: preferences.ollamaEnabled,
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setOllamaEnabled(value);
                    },
                  ),
                  if (preferences.ollamaEnabled) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: preferences.ollamaBaseUrl,
                      decoration: const InputDecoration(labelText: 'Ollama Base URL', hintText: 'http://localhost:11434', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      onChanged: (value) {
                        ref.read(preferencesProvider.notifier).setOllamaBaseUrl(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: preferences.ollamaModel,
                      decoration: const InputDecoration(labelText: 'Default Model', hintText: 'llama2', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      onChanged: (value) {
                        ref.read(preferencesProvider.notifier).setOllamaModel(value);
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 16),

                // OpenAI Settings
                Text('OpenAI Integration', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable OpenAI'),
                  subtitle: const Text('Connect to OpenAI API (ChatGPT)'),
                  value: preferences.openaiEnabled,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setOpenaiEnabled(value);
                  },
                ),
                if (preferences.openaiEnabled) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: preferences.openaiApiKey,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key',
                      hintText: 'sk-...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setOpenaiApiKey(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _getValidOpenaiModel(preferences.openaiModel),
                    decoration: const InputDecoration(
                      labelText: 'OpenAI Model',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gpt-5', child: Text('GPT-5')),
                      DropdownMenuItem(value: 'gpt-5-mini', child: Text('GPT-5 Mini')),
                      DropdownMenuItem(value: 'gpt-5-nano', child: Text('GPT-5 Nano')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(preferencesProvider.notifier).setOpenaiModel(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: preferences.openaiBaseUrl,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI Base URL (Optional)',
                      hintText: 'https://api.openai.com/v1',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setOpenaiBaseUrl(value);
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Web Search Settings
                Text('Web Search Integration', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable Web Search'),
                  subtitle: const Text('Include web search results in AI responses'),
                  value: preferences.webSearchEnabled,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setWebSearchEnabled(value);
                  },
                ),
                if (preferences.webSearchEnabled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Web search requires Google Custom Search API configuration',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Get your API key and search engine ID from Google Cloud Console and configure a Custom Search Engine.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: preferences.webSearchApiKey,
                    decoration: const InputDecoration(
                      labelText: 'Google API Key',
                      hintText: 'Enter your Google Custom Search API key',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setWebSearchApiKey(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: preferences.webSearchEngineId,
                    decoration: const InputDecoration(
                      labelText: 'Search Engine ID',
                      hintText: 'Enter your Custom Search Engine ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setWebSearchEngineId(value);
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // AI Context Strategy Settings
                Text('AI Context Settings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, 
                                 size: 20, 
                                 color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Smart Context Assembly',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _showContextStrategyHelp(context),
                              icon: Icon(
                                Icons.help_outline,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'What does this do?',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Automatically optimizes which documents to send to AI based on your question complexity. Saves 60-70% on AI costs while improving response quality.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Current: ${ContextStrategyManager.instance.activeStrategy.name}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _openContextStrategySettings(context),
                              child: const Text('Configure'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // AI Analytics Section
                Text('AI Analytics & Performance', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, 
                                 size: 20, 
                                 color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Cost Savings Analytics',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _openAnalyticsDialog(context),
                              child: const Text('View Analytics'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your AI cost savings over time and optimize routing performance with detailed analytics.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // AI Routing Mode Settings
                Text('AI Provider Selection', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.route, 
                                 size: 20, 
                                 color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Cost-Intelligent AI Routing',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _showRoutingHelp(context),
                              icon: Icon(
                                Icons.help_outline,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'What does this do?',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Automatically chooses the best AI provider for each question to save 80-85% on costs while maintaining quality.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoutingModeSelector(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Worker Settings
                Text('AI Worker (Anthropic Sidecar)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const AIWorkerSettingsPage(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(preferencesProvider.notifier).resetToDefaults();
            },
            child: const Text('Reset to Defaults'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
      loading: () => const AlertDialog(
        title: Text('Preferences'),
        content: SizedBox(width: 400, height: 200, child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load preferences: $error'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
