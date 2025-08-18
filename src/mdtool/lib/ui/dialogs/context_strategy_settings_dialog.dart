import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/context_strategies/context_strategy.dart';

class ContextStrategySettingsDialog extends ConsumerStatefulWidget {
  const ContextStrategySettingsDialog({super.key});

  @override
  ConsumerState<ContextStrategySettingsDialog> createState() => _ContextStrategySettingsDialogState();
}

class _ContextStrategySettingsDialogState extends ConsumerState<ContextStrategySettingsDialog> {
  final ContextStrategyManager _manager = ContextStrategyManager.instance;
  late String _selectedStrategy;
  late Map<String, ContextStrategyConfig> _configurations;

  @override
  void initState() {
    super.initState();
    _selectedStrategy = _manager.activeStrategy.name;
    _configurations = {};
    
    // Load current configurations
    for (final strategy in _manager.availableStrategies) {
      _configurations[strategy.name] = strategy.config;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'AI Context Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
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
            const SizedBox(height: 24),
            
            // Strategy selection
            _buildStrategySelection(),
            const SizedBox(height: 24),
            
            // Strategy-specific settings
            Expanded(
              child: _buildStrategySettings(),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetToDefaults,
                  child: const Text('Reset to Defaults'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Context Strategy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showHelpDialog(),
                  icon: Icon(
                    Icons.help_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'What does this mean?',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStrategy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _manager.availableStrategies.map((strategy) {
                return DropdownMenuItem(
                  value: strategy.name,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strategy.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        strategy.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStrategy = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySettings() {
    final selectedStrategyObj = _manager.availableStrategies
        .firstWhere((s) => s.name == _selectedStrategy);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings for $_selectedStrategy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_selectedStrategy == 'Progressive Context')
              _buildProgressiveContextSettings()
            else if (_selectedStrategy == 'Simple Context')
              _buildSimpleContextSettings()
            else
              Text(
                'No settings available for this strategy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            
            const SizedBox(height: 16),
            
            // Current configuration explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Configuration:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedStrategyObj.getConfigExplanation(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressiveContextSettings() {
    final config = _configurations['Progressive Context']!;
    final settings = Map<String, dynamic>.from(config.settings);

    return Column(
      children: [
        _buildTokenLimitSlider(
          'Simple queries (grammar, spelling)',
          'simpleTokenLimit',
          settings,
          min: 500,
          max: 5000,
          divisions: 9,
        ),
        const SizedBox(height: 16),
        _buildTokenLimitSlider(
          'Medium queries (implementation help)',
          'mediumTokenLimit',
          settings,
          min: 2000,
          max: 15000,
          divisions: 13,
        ),
        const SizedBox(height: 16),
        _buildTokenLimitSlider(
          'Complex queries (architecture, design)',
          'complexTokenLimit',
          settings,
          min: 5000,
          max: 30000,
          divisions: 25,
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Enable file relationship detection'),
          subtitle: const Text('Find related documents automatically'),
          value: settings['enableFileRelationships'] as bool? ?? true,
          onChanged: (value) {
            setState(() {
              settings['enableFileRelationships'] = value ?? true;
              _configurations['Progressive Context'] = ContextStrategyConfig(
                enabled: config.enabled,
                settings: settings,
              );
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Enable query complexity analysis'),
          subtitle: const Text('Automatically detect question complexity'),
          value: settings['enableComplexityAnalysis'] as bool? ?? true,
          onChanged: (value) {
            setState(() {
              settings['enableComplexityAnalysis'] = value ?? true;
              _configurations['Progressive Context'] = ContextStrategyConfig(
                enabled: config.enabled,
                settings: settings,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSimpleContextSettings() {
    final config = _configurations['Simple Context']!;
    final settings = Map<String, dynamic>.from(config.settings);

    return Column(
      children: [
        _buildTokenLimitSlider(
          'Maximum tokens for current document',
          'maxTokens',
          settings,
          min: 1000,
          max: 10000,
          divisions: 18,
        ),
      ],
    );
  }

  Widget _buildTokenLimitSlider(
    String label,
    String key,
    Map<String, dynamic> settings,
    {required double min, required double max, required int divisions}
  ) {
    final value = (settings[key] as int? ?? min.toInt()).toDouble();
    final costPerQuery = (value / 1000) * 0.01; // Rough cost estimation

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: '${value.toInt()} tokens',
                onChanged: (newValue) {
                  setState(() {
                    settings[key] = newValue.toInt();
                    final strategyName = _selectedStrategy;
                    final currentConfig = _configurations[strategyName]!;
                    _configurations[strategyName] = ContextStrategyConfig(
                      enabled: currentConfig.enabled,
                      settings: settings,
                    );
                  });
                },
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${value.toInt()} tokens\n~\$${costPerQuery.toStringAsFixed(3)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelpDialog() {
    final selectedStrategy = _manager.availableStrategies
        .firstWhere((s) => s.name == _selectedStrategy);
    
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
                    Icons.help,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selectedStrategy.name,
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
                    selectedStrategy.helpText,
                    style: Theme.of(context).textTheme.bodyMedium,
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

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all context strategy settings to their default values. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _manager.resetToDefaults();
      setState(() {
        _selectedStrategy = _manager.activeStrategy.name;
        _configurations.clear();
        for (final strategy in _manager.availableStrategies) {
          _configurations[strategy.name] = strategy.config;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      // Save active strategy
      await _manager.setActiveStrategy(_selectedStrategy);
      
      // Save configurations for all strategies
      for (final entry in _configurations.entries) {
        await _manager.configureStrategy(entry.key, entry.value);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Context strategy settings saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}