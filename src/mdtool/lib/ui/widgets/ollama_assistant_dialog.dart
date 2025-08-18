import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/services/ollama_service.dart';

class OllamaAssistantDialog extends ConsumerStatefulWidget {
  final String? selectedText;
  
  const OllamaAssistantDialog({super.key, this.selectedText});

  @override
  ConsumerState<OllamaAssistantDialog> createState() => _OllamaAssistantDialogState();
}

class _OllamaAssistantDialogState extends ConsumerState<OllamaAssistantDialog> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  bool _hasText = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.selectedText != null && widget.selectedText!.isNotEmpty) {
      _promptController.text = 'Please help me with this text:\n\n${widget.selectedText}';
      _hasText = true;
    }
    
    _promptController.addListener(() {
      final hasText = _promptController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateResponse() async {
    final preferences = ref.read(preferencesProvider).valueOrNull;
    if (preferences == null || !preferences.ollamaEnabled) {
      setState(() {
        _error = 'Ollama is not enabled in preferences';
      });
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _responseController.clear();
    });

    try {
      final response = await OllamaService.instance.generateCompletion(
        baseUrl: preferences.ollamaBaseUrl,
        model: preferences.ollamaModel,
        prompt: _promptController.text.trim(),
      );

      setState(() {
        _responseController.text = response;
        _isGenerating = false;
      });

      // Scroll to show response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  void _copyResponse() {
    if (_responseController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _responseController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response copied to clipboard')),
      );
    }
  }

  void _insertResponse() {
    if (_responseController.text.isNotEmpty) {
      Navigator.of(context).pop(_responseController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final isOllamaEnabled = preferences?.ollamaEnabled ?? false;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.smart_toy, size: 24),
          const SizedBox(width: 8),
          const Text('Ollama Assistant'),
          const Spacer(),
          if (isOllamaEnabled)
            Chip(
              label: Text(preferences?.ollamaModel ?? 'Unknown'),
              backgroundColor: Colors.green.withOpacity(0.1),
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOllamaEnabled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Ollama is not enabled. Enable it in Preferences to use this feature.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text('Prompt:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your prompt here...',
                  contentPadding: EdgeInsets.all(12),
                ),
                enabled: isOllamaEnabled && !_isGenerating,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_responseController.text.isNotEmpty && !_isGenerating) ...[
                  TextButton.icon(
                    onPressed: _copyResponse,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _insertResponse,
                    icon: const Icon(Icons.insert_drive_file, size: 16),
                    label: const Text('Insert'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _isGenerating
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Generating response...'),
                          ],
                        ),
                      )
                    : TextField(
                        controller: _responseController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        readOnly: true,
                        scrollController: _scrollController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Response will appear here...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: isOllamaEnabled && !_isGenerating && _hasText
              ? _generateResponse
              : null,
          icon: _isGenerating 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(_isGenerating ? 'Generating...' : 'Generate'),
        ),
      ],
    );
  }
}