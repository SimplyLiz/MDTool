import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import '../../core/services/ollama_service.dart';
import '../../core/utils/platform_install.dart';
import '../../core/providers/preferences_provider.dart';

class OllamaHelpScreen extends ConsumerStatefulWidget {
  const OllamaHelpScreen({super.key});

  @override
  ConsumerState<OllamaHelpScreen> createState() => _OllamaHelpScreenState();
}

class _OllamaHelpScreenState extends ConsumerState<OllamaHelpScreen> {
  final _ollamaService = OllamaService.instance;
  bool? _isRunning;
  ConnectionTestResult? _testResult;
  bool _isTestingConnection = false;
  final _remoteUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  @override
  void dispose() {
    _remoteUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    final prefsAsync = ref.read(preferencesProvider);
    final prefs = prefsAsync.valueOrNull;
    final baseUrl = (prefs?.ollamaBaseUrl.isNotEmpty == true) ? prefs!.ollamaBaseUrl : 'http://127.0.0.1:11434';

    final isRunning = await _ollamaService.isRunning(baseUrl: baseUrl);
    setState(() {
      _isRunning = isRunning;
    });

    if (isRunning) {
      final result = await _ollamaService.testConnection(baseUrl: baseUrl);
      setState(() {
        _testResult = result;
      });
    }

    setState(() {
      _isTestingConnection = false;
    });
  }

  Future<void> _testCustomConnection() async {
    final url = _remoteUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTestingConnection = true;
    });

    try {
      final result = await _ollamaService.testConnection(baseUrl: url);
      setState(() {
        _testResult = result;
        _isRunning = result.isConnected;
      });

      if (result.isConnected) {
        // Save the working URL to preferences
        await ref.read(preferencesProvider.notifier).setOllamaBaseUrl(result.url ?? url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to Ollama${result.version != null ? " v${result.version}" : ""}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: ${result.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Widget _buildStatusCard() {
    final isConnected = _isRunning == true;
    final isChecking = _isRunning == null || _isTestingConnection;
    
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isChecking) {
      statusText = 'Checking Ollama connection...';
      statusColor = Colors.grey;
      statusIcon = Icons.refresh;
    } else if (isConnected) {
      statusText = 'Ollama is running';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      
      if (_testResult?.version != null) {
        statusText += ' (v${_testResult!.version})';
      }
    } else {
      statusText = 'Ollama not detected';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isTestingConnection ? null : _checkConnection,
                  icon: _isTestingConnection 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.refresh),
                  label: Text('Re-check'),
                ),
              ],
            ),
            if (isConnected && _testResult != null) ...[
              const SizedBox(height: 8),
              if (_testResult!.url != null)
                Text('URL: ${_testResult!.url}', style: Theme.of(context).textTheme.bodySmall),
              if (_testResult!.models.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Models: ${_testResult!.models.take(3).join(", ")}${_testResult!.models.length > 3 ? " and ${_testResult!.models.length - 3} more" : ""}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationSection() {
    if (_isRunning == true) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Install Ollama',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Choose an installation method below:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Installation buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchURL(PlatformInstall.downloadUrl()),
                  icon: Icon(Icons.web),
                  label: Text('Download from Website'),
                ),
                if (PlatformInstall.brewCommand() != null)
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard('Homebrew', PlatformInstall.brewCommand()!),
                    icon: Icon(Icons.terminal),
                    label: Text('Copy Homebrew Command'),
                  ),
                if (PlatformInstall.linuxCommand() != null)
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard('Linux Install', PlatformInstall.linuxCommand()!),
                    icon: Icon(Icons.terminal),
                    label: Text('Copy Linux Install'),
                  ),
                if (PlatformInstall.wingetCommand() != null)
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard('winget', PlatformInstall.wingetCommand()!),
                    icon: Icon(Icons.terminal),
                    label: Text('Copy winget Command'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('Detailed Installation Instructions'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    PlatformInstall.getInstallInstructions(),
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Remote Ollama Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to Ollama running on another machine or custom port:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _remoteUrlController,
                    decoration: InputDecoration(
                      labelText: 'Ollama URL',
                      hintText: 'http://192.168.1.100:11434',
                      border: OutlineInputBorder(),
                      prefixText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isTestingConnection ? null : _testCustomConnection,
                  child: _isTestingConnection 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Test'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Examples: http://localhost:11434, http://192.168.1.100:11434',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularModelsSection() {
    if (_isRunning != true) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Popular Models',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Download these popular models to get started:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...PlatformInstall.getPopularModels().take(3).map((model) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(model.name, style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.description),
                    Text('Size: ${model.size}', style: TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.content_copy),
                  tooltip: 'Copy command',
                  onPressed: () => _copyToClipboard('Pull ${model.name}', model.pullCommand),
                ),
              ),
            )),
            const SizedBox(height: 8),
            Text(
              'Run these commands in Terminal after installing Ollama.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quick Start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                PlatformInstall.getQuickStartInstructions(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Privacy & Security',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Ollama runs locally on your machine\n'
              '• Your data and conversations stay private\n'
              '• No data is sent to external servers\n'
              '• Models are stored locally after download',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyToClipboard(String label, String text) async {
    await FlutterClipboard.copy(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $label to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Setup & Help'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            if (_isRunning != true) ...[
              _buildInstallationSection(),
              const SizedBox(height: 16),
              _buildQuickStartSection(),
              const SizedBox(height: 16),
            ],
            
            _buildRemoteConnectionSection(),
            const SizedBox(height: 16),
            
            _buildPopularModelsSection(),
            
            if (_testResult?.models.isNotEmpty ?? false) 
              const SizedBox(height: 16),
              
            _buildPrivacySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}