import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/document_index_service.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import '../../core/models/preferences.dart';
import 'context_status_indicator.dart';
import 'routing_decision_indicator.dart';
import 'token_usage_indicator.dart';
import '../dialogs/usage_limits_dialog.dart';

class ChatDialog extends ConsumerStatefulWidget {
  const ChatDialog({super.key});

  @override
  ConsumerState<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends ConsumerState<ChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;
  final DocumentIndexService _documentIndex = DocumentIndexService.instance;
  
  bool _isInitializing = true;
  bool _isSending = false;
  bool _useDocumentContext = true;
  bool _useSmartContextAssembly = true;
  bool _hasMessage = false;
  String? _initError;
  AIProvider? _selectedProvider;
  String? _selectedModel;
  final Set<String> _expandedContextMessages = {};
  final Set<String> _expandedRoutingMessages = {};

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
    
    _messageController.addListener(() {
      final hasMessage = _messageController.text.trim().isNotEmpty;
      if (hasMessage != _hasMessage) {
        setState(() {
          _hasMessage = hasMessage;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeDocuments() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      // Index the current file if available
      final appState = ref.read(appStateProvider);
      if (appState.currentFile != null) {
        await _documentIndex.indexFile(appState.currentFile!);
        
        // Index the directory containing the current file
        final currentDir = path.dirname(appState.currentFile!);
        await _documentIndex.indexDirectory(currentDir);
      }

      // If in split screen, index the secondary file too
      if (appState.isSplitScreenMode && appState.secondaryFile != null) {
        await _documentIndex.indexFile(appState.secondaryFile!);
        
        // Index its directory if different
        final secondaryDir = path.dirname(appState.secondaryFile!);
        final currentDir = appState.currentFile != null ? path.dirname(appState.currentFile!) : null;
        if (secondaryDir != currentDir) {
          await _documentIndex.indexDirectory(secondaryDir);
        }
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = 'Failed to initialize documents: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final preferences = ref.read(preferencesProvider).valueOrNull;
    if (preferences == null) {
      _showError('Preferences not loaded');
      return;
    }

    // Determine which provider to use
    AIProvider provider;
    String model;
    String? baseUrl;
    String? apiKey;

    if (_selectedProvider != null && _selectedModel != null) {
      provider = _selectedProvider!;
      model = _selectedModel!;
      
      switch (provider) {
        case AIProvider.ollama:
          if (!preferences.ollamaEnabled) {
            _showError('Ollama is not enabled in preferences');
            return;
          }
          baseUrl = preferences.ollamaBaseUrl;
          break;
        case AIProvider.openai:
          if (!preferences.openaiEnabled) {
            _showError('OpenAI is not enabled in preferences');
            return;
          }
          apiKey = preferences.openaiApiKey;
          baseUrl = preferences.openaiBaseUrl;
          break;
      }
    } else {
      // Auto-select first available provider
      if (preferences.ollamaEnabled) {
        provider = AIProvider.ollama;
        model = preferences.ollamaModel;
        baseUrl = preferences.ollamaBaseUrl;
      } else if (preferences.openaiEnabled && preferences.openaiApiKey.isNotEmpty) {
        provider = AIProvider.openai;
        model = preferences.openaiModel;
        apiKey = preferences.openaiApiKey;
        baseUrl = preferences.openaiBaseUrl;
      } else {
        _showError('No AI provider is configured. Please enable Ollama or OpenAI in preferences.');
        return;
      }
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();
    
    // Scroll to bottom after adding user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Set the context strategy based on smart toggle
      if (_useDocumentContext) {
        final strategyName = _useSmartContextAssembly ? 'Enhanced Progressive Context' : 'Simple Context';
        await ContextStrategyManager.instance.setActiveStrategy(strategyName);
      }
      
      await _chatService.sendMessage(
        userMessage: message,
        provider: provider,
        model: model,
        baseUrl: baseUrl,
        apiKey: apiKey,
        useDocumentContext: _useDocumentContext,
      );

      setState(() {
        _isSending = false;
      });

      // Scroll to bottom after getting response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _showError('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _copyMessageToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _chatService.clearChat();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportChat() {
    final markdown = _chatService.exportChatAsMarkdown();
    Clipboard.setData(ClipboardData(text: markdown));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat exported to clipboard as Markdown')),
    );
  }

  void _refreshDocuments() async {
    setState(() {
      _isInitializing = true;
    });
    
    await _documentIndex.refreshIndex();
    await _initializeDocuments();
  }

  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  void _showDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, size: 24),
                  const SizedBox(width: 8),
                  const Text('Chat Diagnostics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDiagnosticSection('Chat Service Status', [
                        'Messages: ${_chatService.messages.length}',
                        'Has document context: ${_chatService.hasDocumentContext}',
                        'Document stats: ${_chatService.getDocumentStats()}',
                      ]),
                      const SizedBox(height: 16),
                      _buildDiagnosticSection('Document Index', [
                        'Indexed documents: ${_documentIndex.documents.length}',
                        'Documents: ${_documentIndex.documents.map((d) => d.filePath).join(', ')}',
                      ]),
                      const SizedBox(height: 16),
                      _buildDiagnosticSection('Context Strategy', [
                        'Active strategy: ${ContextStrategyManager.instance.activeStrategy.name}',
                        'Strategy description: ${ContextStrategyManager.instance.activeStrategy.description}',
                        'Available strategies: ${ContextStrategyManager.instance.availableStrategies.map((s) => s.name).join(', ')}',
                        'Configuration: ${ContextStrategyManager.instance.activeStrategy.getConfigExplanation()}',
                      ]),
                      const SizedBox(height: 16),
                      _buildDiagnosticSection('AI Routing', [
                        'Current mode: ${AIRoutingManager.instance.mode}',
                      ]),
                      const SizedBox(height: 16),
                      _buildDiagnosticSection('Current Settings', [
                        'Use document context: $_useDocumentContext',
                        'Use smart context assembly: $_useSmartContextAssembly',
                        'Selected provider: $_selectedProvider',
                        'Selected model: $_selectedModel',
                        'Is sending: $_isSending',
                        'Is initializing: $_isInitializing',
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final diagnostics = _generateDiagnosticsText();
                      Clipboard.setData(ClipboardData(text: diagnostics));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diagnostics copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          )),
        ],
      ),
    );
  }

  String _generateDiagnosticsText() {
    final buffer = StringBuffer();
    buffer.writeln('# Chat Diagnostics');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('## Chat Service Status');
    buffer.writeln('- Messages: ${_chatService.messages.length}');
    buffer.writeln('- Has document context: ${_chatService.hasDocumentContext}');
    buffer.writeln('- Document stats: ${_chatService.getDocumentStats()}');
    buffer.writeln();
    
    buffer.writeln('## Document Index');
    buffer.writeln('- Indexed documents: ${_documentIndex.documents.length}');
    buffer.writeln('- Documents: ${_documentIndex.documents.map((d) => d.filePath).join(', ')}');
    buffer.writeln();
    
    buffer.writeln('## Context Strategy');
    buffer.writeln('- Active strategy: ${ContextStrategyManager.instance.activeStrategy.name}');
    buffer.writeln('- Strategy description: ${ContextStrategyManager.instance.activeStrategy.description}');
    buffer.writeln('- Available strategies: ${ContextStrategyManager.instance.availableStrategies.map((s) => s.name).join(', ')}');
    buffer.writeln('- Configuration: ${ContextStrategyManager.instance.activeStrategy.getConfigExplanation()}');
    buffer.writeln();
    
    buffer.writeln('## AI Routing');
    buffer.writeln('- Current mode: ${AIRoutingManager.instance.mode}');
    buffer.writeln();
    
    buffer.writeln('## Current Settings');
    buffer.writeln('- Use document context: $_useDocumentContext');
    buffer.writeln('- Use smart context assembly: $_useSmartContextAssembly');
    buffer.writeln('- Selected provider: $_selectedProvider');
    buffer.writeln('- Selected model: $_selectedModel');
    buffer.writeln('- Is sending: $_isSending');
    buffer.writeln('- Is initializing: $_isInitializing');
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final hasAnyProvider = (preferences?.ollamaEnabled ?? false) || 
                          ((preferences?.openaiEnabled ?? false) && (preferences?.openaiApiKey?.isNotEmpty ?? false));
    final messages = _chatService.messages;
    final documentStats = _chatService.getDocumentStats();

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.chat, size: 24),
                const SizedBox(width: 8),
                const Text('Document Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                const TokenUsageIndicator(isCompact: true),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const UsageLimitsDialog(),
                  ),
                  tooltip: 'Usage Limits',
                ),
                const SizedBox(width: 4),
                _buildModelSelector(preferences),
                const SizedBox(width: 4),
                CompactRoutingIndicator(
                  currentMode: AIRoutingManager.instance.mode,
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _refreshDocuments();
                        break;
                      case 'export':
                        _exportChat();
                        break;
                      case 'clear':
                        _clearChat();
                        break;
                      case 'diagnostics':
                        _showDiagnostics();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Refresh Documents')]),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text('Export Chat')]),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(children: [Icon(Icons.clear), SizedBox(width: 8), Text('Clear Chat')]),
                    ),
                    const PopupMenuItem(
                      value: 'diagnostics',
                      child: Row(children: [Icon(Icons.bug_report), SizedBox(width: 8), Text('Show Diagnostics')]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status and Info
            if (_isInitializing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Indexing your documents...'),
                  ],
                ),
              ),
            ] else if (_initError != null) ...[
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
                    Expanded(child: Text(_initError!)),
                  ],
                ),
              ),
            ] else ...[
              // Document stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_books, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text('${documentStats['totalDocuments']} documents indexed'),
                        const Spacer(),
                        Switch(
                          value: _useDocumentContext,
                          onChanged: (value) => setState(() => _useDocumentContext = value),
                        ),
                        const Text('Use Context'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text('Smart Context Assembly'),
                        const Spacer(),
                        Switch(
                          value: _useSmartContextAssembly,
                          onChanged: _useDocumentContext ? (value) => setState(() => _useSmartContextAssembly = value) : null,
                        ),
                        const Text('Smart'),
                      ],
                    ),
                    if (documentStats['uniqueTags'] > 0)
                      Text('${documentStats['uniqueTags']} unique tags found'),
                  ],
                ),
              ),
            ],

            if (!hasAnyProvider) ...[
              const SizedBox(height: 16),
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
                      child: Text('No AI provider configured. Enable Ollama or OpenAI in Preferences to use chat.'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Chat messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: messages.isEmpty
                    ? _buildWelcomeView()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            // Sending indicator
                            return _buildTypingIndicator();
                          }
                          
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Input area
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your documents...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    enabled: hasAnyProvider && !_isSending && !_isInitializing,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: hasAnyProvider && !_isSending && !_isInitializing && _hasMessage
                      ? _sendMessage
                      : null,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    final suggestions = _chatService.getSuggestedQuestions();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Welcome to Document Chat!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask questions about your Markdown documents. I can help you find information, summarize content, and organize your files.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Suggested questions:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((question) => ActionChip(
              label: Text(question),
              onPressed: () => _sendSuggestedQuestion(question),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.smart_toy, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyMessageToClipboard(message.content),
                        icon: Icon(
                          Icons.copy,
                          size: 16,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        tooltip: 'Copy message',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (message.contextResult != null) ...[
                    const SizedBox(height: 8),
                    ContextUsageIndicator(
                      contextResult: message.contextResult,
                      expanded: _expandedContextMessages.contains(message.id),
                      onToggle: () {
                        setState(() {
                          if (_expandedContextMessages.contains(message.id)) {
                            _expandedContextMessages.remove(message.id);
                          } else {
                            _expandedContextMessages.add(message.id);
                          }
                        });
                      },
                    ),
                  ] else if (message.context != null) ...[
                    const SizedBox(height: 8),
                    _buildContextIndicator(message.context!),
                  ],
                  if (message.routeDecision != null) ...[
                    const SizedBox(height: 8),
                    RoutingDecisionIndicator(
                      routeDecision: message.routeDecision!,
                      expanded: _expandedRoutingMessages.contains(message.id),
                      onToggle: () {
                        setState(() {
                          if (_expandedRoutingMessages.contains(message.id)) {
                            _expandedRoutingMessages.remove(message.id);
                          } else {
                            _expandedRoutingMessages.add(message.id);
                          }
                        });
                      },
                    ),
                  ],
                  if (!isUser) ...[
                    const SizedBox(height: 4),
                    MessageTokenUsage(
                      inputTokens: message.inputTokens,
                      outputTokens: message.outputTokens,
                      totalTokens: message.totalTokens,
                      cost: message.cost,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.smart_toy, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Thinking...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(Preferences? preferences) {
    if (preferences == null) return const SizedBox.shrink();
    
    final availableProviders = _chatService.getAvailableProviders(
      ollamaEnabled: preferences.ollamaEnabled,
      openaiEnabled: preferences.openaiEnabled,
      ollamaBaseUrl: preferences.ollamaBaseUrl,
      ollamaModel: preferences.ollamaModel,
      openaiApiKey: preferences.openaiApiKey,
      openaiModel: preferences.openaiModel,
    );
    
    if (availableProviders.isEmpty) {
      return const Chip(
        label: Text('No AI Provider'),
        backgroundColor: Colors.red,
        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
      );
    }
    
    // Auto-select first provider if none selected
    if (_selectedProvider == null && availableProviders.isNotEmpty) {
      final firstProvider = availableProviders.first;
      _selectedProvider = firstProvider['provider'] as AIProvider;
      _selectedModel = firstProvider['model'] as String;
    }
    
    if (availableProviders.length == 1) {
      // Only one provider available, show as chip
      final provider = availableProviders.first;
      return Chip(
        label: Text(provider['displayName'] as String),
        backgroundColor: Colors.green.withOpacity(0.1),
        labelStyle: const TextStyle(fontSize: 12),
      );
    }
    
    // Multiple providers available, show dropdown
    return DropdownButton<String>(
      value: _selectedProvider != null ? '${_selectedProvider!.name}:$_selectedModel' : null,
      onChanged: (value) {
        if (value != null) {
          final parts = value.split(':');
          final providerName = parts[0];
          final model = parts[1];
          
          setState(() {
            _selectedProvider = AIProvider.values.firstWhere((p) => p.name == providerName);
            _selectedModel = model;
          });
        }
      },
      items: availableProviders.map<DropdownMenuItem<String>>((provider) {
        final key = '${(provider['provider'] as AIProvider).name}:${provider['model']}';
        return DropdownMenuItem<String>(
          value: key,
          child: Text(
            provider['displayName'] as String,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      underline: const SizedBox.shrink(),
      isDense: true,
    );
  }

  Widget _buildContextIndicator(String context) {
    // Parse basic context information
    final lines = context.split('\n');
    final contextInfo = <String, String>{};
    String documentCount = '0';
    String relevantDocs = '';
    
    // Extract key information from context
    for (final line in lines) {
      if (line.contains('Found') && line.contains('relevant document')) {
        final match = RegExp(r'Found (\d+) relevant document').firstMatch(line);
        if (match != null) {
          documentCount = match.group(1)!;
        }
      } else if (line.startsWith('📄 DOCUMENT')) {
        final docMatch = RegExp(r'📄 DOCUMENT \d+: (.+)').firstMatch(line);
        if (docMatch != null) {
          relevantDocs += (relevantDocs.isEmpty ? '' : ', ') + docMatch.group(1)!;
        }
      }
    }
    
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: Icon(Icons.folder_open, size: 16, color: Colors.blue[600]),
      title: Text(
        'Used context from $documentCount document${documentCount != '1' ? 's' : ''}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      subtitle: relevantDocs.isNotEmpty 
          ? Text(
              relevantDocs.length > 60 ? '${relevantDocs.substring(0, 60)}...' : relevantDocs,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            )
          : null,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Document Context Details',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildContextSummary(context),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showFullContext(context),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('View Full Context', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextSummary(String context) {
    final lines = context.split('\n');
    final summary = <Widget>[];
    
    // Extract document summaries
    String currentDoc = '';
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('📄 DOCUMENT')) {
        currentDoc = line.substring(line.indexOf(': ') + 2);
        summary.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.article, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currentDoc,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        
        // Look for tags and relevance score in next few lines
        for (int j = i + 1; j < (i + 6).clamp(0, lines.length); j++) {
          final nextLine = lines[j];
          if (nextLine.startsWith('🏷️ Tags:')) {
            final tags = nextLine.substring(nextLine.indexOf(': ') + 2);
            summary.add(
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  'Tags: $tags',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ),
            );
          } else if (nextLine.startsWith('📊 Relevance Score:')) {
            final score = nextLine.substring(nextLine.indexOf(': ') + 2);
            summary.add(
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  'Relevance: $score',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ),
            );
            break;
          } else if (nextLine.startsWith('📄') || nextLine.startsWith('═')) {
            break;
          }
        }
      }
    }
    
    if (summary.isEmpty) {
      return Text(
        'Context information available',
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summary.take(3).toList(), // Limit to first 3 documents in summary
    );
  }

  void _showFullContext(String contextText) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 700,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.description),
                  const SizedBox(width: 8),
                  const Text('Full Document Context', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      contextText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: contextText));
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Context copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
