import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/metrics_provider.dart';
import '../../core/services/metrics_service.dart';

class UsageLimitsDialog extends ConsumerStatefulWidget {
  const UsageLimitsDialog({super.key});

  @override
  ConsumerState<UsageLimitsDialog> createState() => _UsageLimitsDialogState();
}

class _UsageLimitsDialogState extends ConsumerState<UsageLimitsDialog> {
  late TextEditingController _dailyTokenController;
  late TextEditingController _dailyCostController;
  late TextEditingController _monthlyTokenController;
  late TextEditingController _monthlyCostController;
  bool _enableLimits = true;
  bool _disableWhenExceeded = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize with default values, will be updated in build
    _dailyTokenController = TextEditingController(text: '100000');
    _dailyCostController = TextEditingController(text: '5.0');
    _monthlyTokenController = TextEditingController(text: '1000000');
    _monthlyCostController = TextEditingController(text: '50.0');
  }

  @override
  void dispose() {
    _dailyTokenController.dispose();
    _dailyCostController.dispose();
    _monthlyTokenController.dispose();
    _monthlyCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLimits = ref.watch(usageLimitsProvider);
    final summary = ref.watch(usageSummaryProvider);

    // Update controllers with current values if they've changed
    if (_dailyTokenController.text != currentLimits.dailyTokenLimit.toString()) {
      _dailyTokenController.text = currentLimits.dailyTokenLimit.toString();
      _dailyCostController.text = currentLimits.dailyCostLimit.toString();
      _monthlyTokenController.text = currentLimits.monthlyTokenLimit.toString();
      _monthlyCostController.text = currentLimits.monthlyCostLimit.toString();
      _enableLimits = currentLimits.enableLimits;
      _disableWhenExceeded = currentLimits.disableWhenExceeded;
    }

    return AlertDialog(
      title: const Text('OpenAI Usage Limits'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current usage summary
              summary.when(
                data: (usageSummary) => _buildCurrentUsage(context, usageSummary),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              
              // Info about Ollama
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ollama runs locally and is always unlimited. These limits only apply to paid OpenAI models.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Enable limits toggle
              SwitchListTile(
                title: const Text('Enable OpenAI usage limits'),
                subtitle: const Text('Control OpenAI usage to manage costs (Ollama is always unlimited)'),
                value: _enableLimits,
                onChanged: (value) {
                  setState(() {
                    _enableLimits = value;
                  });
                },
              ),
              
              if (_enableLimits) ...[
                const SizedBox(height: 16),
                
                // Daily limits
                Text(
                  'Daily Limits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _dailyTokenController,
                        label: 'Daily Token Limit',
                        suffix: 'tokens',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _dailyCostController,
                        label: 'Daily Cost Limit',
                        prefix: '\$',
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Monthly limits
                Text(
                  'Monthly Limits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        controller: _monthlyTokenController,
                        label: 'Monthly Token Limit',
                        suffix: 'tokens',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumberField(
                        controller: _monthlyCostController,
                        label: 'Monthly Cost Limit',
                        prefix: '\$',
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Disable when exceeded toggle
                SwitchListTile(
                  title: const Text('Block OpenAI when limits exceeded'),
                  subtitle: const Text('Prevent OpenAI requests when limits are reached (Ollama remains available)'),
                  value: _disableWhenExceeded,
                  onChanged: (value) {
                    setState(() {
                      _disableWhenExceeded = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveLimits,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildCurrentUsage(BuildContext context, UsageSummary summary) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current OpenAI Usage',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today:'),
                Text('${summary.totalTokensToday} tokens • \$${summary.totalCostToday.toStringAsFixed(3)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('This Month:'),
                Text('${summary.totalTokensThisMonth} tokens • \$${summary.totalCostThisMonth.toStringAsFixed(3)}'),
              ],
            ),
            if (summary.isBlocked) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'OpenAI usage blocked due to exceeded limits (Ollama remains available)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
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

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: decimal 
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
      inputFormatters: decimal
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
        : [FilteringTextInputFormatter.digitsOnly],
    );
  }

  void _saveLimits() {
    try {
      final newLimits = UsageLimits(
        dailyTokenLimit: int.parse(_dailyTokenController.text),
        dailyCostLimit: double.parse(_dailyCostController.text),
        monthlyTokenLimit: int.parse(_monthlyTokenController.text),
        monthlyCostLimit: double.parse(_monthlyCostController.text),
        enableLimits: _enableLimits,
        disableWhenExceeded: _disableWhenExceeded,
      );

      ref.read(usageLimitsProvider.notifier).updateLimits(newLimits);
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usage limits updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving limits: $e')),
      );
    }
  }
}