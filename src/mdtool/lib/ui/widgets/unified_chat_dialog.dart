import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/document_index_service.dart';
import '../../core/services/ai/context_strategies/context_strategy_manager.dart';
import '../../core/services/ai/ai_routing_manager.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/web_search_service.dart';
import '../../core/models/preferences.dart';
import 'routing_decision_indicator.dart';
import '../dialogs/ai_chat_settings_dialog.dart';
import 'detached_chat_window.dart';

class AttachedFile {
  final String filePath;
  final String fileName;
  final String content;
  final int size;
  
  const AttachedFile({
    required this.filePath,
    required this.fileName,
    required this.content,
    required this.size,
  });
}

class UnifiedChatDialog extends ConsumerStatefulWidget {
  final String? selectedText;
  final bool isDetached;
  final bool? initialUseDocumentContext;
  final bool? initialUseWebSearch;
  final Set<String>? initialSelectedDocuments;
  final List<AttachedFile>? initialAttachedFiles;
  
  const UnifiedChatDialog({
    super.key, 
    this.selectedText,
    this.isDetached = false,
    this.initialUseDocumentContext,
    this.initialUseWebSearch,
    this.initialSelectedDocuments,
    this.initialAttachedFiles,
  });

  @override
  ConsumerState<UnifiedChatDialog> createState() => _UnifiedChatDialogState();
}

class _UnifiedChatDialogState extends ConsumerState<UnifiedChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;
  final DocumentIndexService _documentIndex = DocumentIndexService.instance;
  final MetricsService _metricsService = MetricsService.instance;
  final WebSearchService _webSearchService = WebSearchService.instance;
  
  bool _isInitializing = true;
  bool _isSending = false;
  bool _useDocumentContext = true;
  final bool _useSmartContextAssembly = true;
  bool _useWebSearch = false;
  bool _hasMessage = false;
  String? _initError;
  AIProvider? _selectedProvider;
  String? _selectedModel;
  Set<String> _selectedDocuments = {}; // Per-session document selection
  List<AttachedFile> _attachedFiles = []; // Files attached to the chat

  @override
  void initState() {
    super.initState();
    
    // Initialize with passed values if provided
    _useDocumentContext = widget.initialUseDocumentContext ?? true;
    _useWebSearch = widget.initialUseWebSearch ?? false;
    if (widget.initialSelectedDocuments != null) {
      _selectedDocuments = Set<String>.from(widget.initialSelectedDocuments!);
    }
    if (widget.initialAttachedFiles != null) {
      _attachedFiles = List<AttachedFile>.from(widget.initialAttachedFiles!);
    }
    
    _initializeChat();
    
    _messageController.addListener(() {
      final hasMessage = _messageController.text.trim().isNotEmpty;
      if (hasMessage != _hasMessage) {
        setState(() {
          _hasMessage = hasMessage;
        });
      }
    });

    // Pre-populate with selected text if provided
    if (widget.selectedText != null && widget.selectedText!.isNotEmpty) {
      _messageController.text = 'Please help me with this text:\n\n${widget.selectedText}';
      _hasMessage = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      // Initialize metrics service
      await _metricsService.initialize();

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

      // Initialize selected documents with all available documents (default enabled)
      final allDocuments = await _documentIndex.getIndexedDocuments();
      _selectedDocuments = Set<String>.from(allDocuments.map((doc) => doc['path'] as String));

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = 'Failed to initialize: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = widget.isDetached 
        ? screenSize.width 
        : (screenSize.width * 0.9).clamp(300.0, 900.0);
    final dialogHeight = widget.isDetached 
        ? screenSize.height 
        : (screenSize.height * 0.85).clamp(400.0, 700.0);

    final chatContent = _buildChatContent(context, screenSize, dialogWidth, dialogHeight);

    if (widget.isDetached) {
      // Return the chat content directly without Dialog wrapper
      return chatContent;
    }

    return Dialog(
      child: chatContent,
    );
  }

  Widget _buildChatContent(BuildContext context, Size screenSize, double dialogWidth, double dialogHeight) {
    return Container(
      width: dialogWidth,
      height: dialogHeight,
      child: Column(
        children: [
            // Header - Claude-like
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: dialogWidth < 600 ? 12 : 20, 
                vertical: dialogWidth < 600 ? 8 : 12  // Reduced vertical padding
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  // Left side - routing info only (model moved to bottom)
                  if (dialogWidth >= 700) ...[
                    CompactRoutingIndicator(
                      currentMode: AIRoutingManager.instance.mode,
                    ),
                    const Spacer(),
                  ] else ...[
                    // For smaller screens, just show the title
                    Expanded(
                      child: Text(
                        'AI Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ],
                  
                  // Right side - controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      // Detach button (open in fullscreen) - only show when not detached
                      if (!widget.isDetached)
                        IconButton(
                          onPressed: _detachToSeparateWindow,
                          icon: Icon(Icons.open_in_new, size: dialogWidth < 600 ? 18 : 20),
                          tooltip: 'Open in fullscreen',
                        ),
                      
                      // Settings (always visible)
                      IconButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AIChatSettingsDialog(),
                        ),
                        icon: Icon(Icons.settings, size: dialogWidth < 600 ? 18 : 20),
                        tooltip: 'Chat Settings',
                      ),
                      
                      // More menu (consolidated for small screens)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: dialogWidth < 600 ? 18 : 20),
                        onSelected: (value) {
                          switch (value) {
                            case 'export':
                              _exportChat();
                              break;
                            case 'clear':
                              _clearChat();
                              break;
                            case 'refresh':
                              _refreshDocuments();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text('Export Chat')]),
                          ),
                          const PopupMenuItem(
                            value: 'clear',
                            child: Row(children: [Icon(Icons.clear), SizedBox(width: 8), Text('Clear Chat')]),
                          ),
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Refresh Context')]),
                          ),
                        ],
                      ),
                      
                      if (dialogWidth >= 600) const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, size: dialogWidth < 600 ? 18 : 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat Content Area
            Expanded(
              child: _buildChatContentArea(),
            ),

            // Input Area - Claude-like
            _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatContentArea() {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final hasAnyProvider = (preferences?.ollamaEnabled ?? false) || 
                          ((preferences?.openaiEnabled ?? false) && (preferences?.openaiApiKey.isNotEmpty ?? false));
    final messages = _chatService.messages;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(300.0, 900.0);

    // Clean chat area without the provider status bar
    if (!hasAnyProvider) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 48),
            const SizedBox(height: 16),
            const Text(
              'No AI provider configured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Enable Ollama or OpenAI in Preferences to use chat.'),
          ],
        ),
      );
    }

    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing AI assistant...'),
          ],
        ),
      );
    }

    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_initError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return _buildWelcomeView();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(dialogWidth < 600 ? 12 : 20),
      itemCount: messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }
        
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildInputArea() {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final hasAnyProvider = (preferences?.ollamaEnabled ?? false) || 
                          ((preferences?.openaiEnabled ?? false) && (preferences?.openaiApiKey.isNotEmpty ?? false));
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(300.0, 900.0);

    return Container(
      padding: EdgeInsets.all(dialogWidth < 600 ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input field with attachment and action buttons - Claude style
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Main input row - just the text field
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Text input (full width)
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: hasAnyProvider 
                                ? 'How can I help you today?'
                                : 'Configure AI provider in Preferences first',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          enabled: hasAnyProvider && !_isSending && !_isInitializing,
                          onSubmitted: (_) => _sendMessage(),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom toolbar with buttons and status indicators
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - + button and status badges
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // + button on the left
                            Container(
                              height: 32,
                              width: 32,
                              child: IconButton(
                                onPressed: hasAnyProvider ? _showAttachmentMenu : null,
                                icon: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: hasAnyProvider ? Colors.grey[600] : Colors.grey[400],
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Add attachment',
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Toggle buttons moved from header
                            Consumer(
                              builder: (context, ref, child) {
                                final preferences = ref.watch(preferencesProvider).valueOrNull;
                                final isWebSearchConfigured = preferences?.webSearchEnabled ?? false;
                                
                                return IconButton(
                                  onPressed: isWebSearchConfigured 
                                      ? () => setState(() => _useWebSearch = !_useWebSearch)
                                      : null,
                                  icon: Icon(
                                    Icons.language,
                                    color: !isWebSearchConfigured
                                        ? Colors.grey[300]  // Even lighter when not configured
                                        : (_useWebSearch 
                                            ? Theme.of(context).primaryColor 
                                            : Colors.grey[400]),
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: isWebSearchConfigured
                                      ? (_useWebSearch ? 'Disable web search' : 'Enable web search')
                                      : 'Web search not configured',
                                );
                              },
                            ),
                            
                            IconButton(
                              onPressed: () => setState(() => _useDocumentContext = !_useDocumentContext),
                              icon: Icon(
                                Icons.library_books,
                                color: _useDocumentContext 
                                    ? Theme.of(context).primaryColor 
                                    : Colors.grey[400],
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: _useDocumentContext ? 'Disable document context' : 'Enable document context',
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Status badges
                            if (_useDocumentContext) ...[
                              GestureDetector(
                                onTap: _showDocumentSelectionDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedDocuments.isEmpty 
                                        ? Colors.grey.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedDocuments.isEmpty 
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.library_books, 
                                        size: 14, 
                                        color: _selectedDocuments.isEmpty 
                                            ? Colors.grey[600]
                                            : Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedDocuments.isEmpty 
                                            ? 'No Documents' 
                                            : '${_selectedDocuments.length} Document${_selectedDocuments.length == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 11, 
                                          color: _selectedDocuments.isEmpty 
                                              ? Colors.grey[600]
                                              : Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_useDocumentContext && _useWebSearch) const SizedBox(width: 8),
                            if (_useWebSearch) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.language, size: 14, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text('Web Search', style: TextStyle(fontSize: 11, color: Colors.green[700])),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Attached files badge
                            if (_attachedFiles.isNotEmpty) ...[
                              if ((_useDocumentContext || _useWebSearch)) const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showAttachedFilesDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.attach_file, size: 14, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_attachedFiles.length} File${_attachedFiles.length == 1 ? '' : 's'}',
                                        style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Right side - model selector and send button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Model dropdown selector (like Claude)
                          Consumer(
                            builder: (context, ref, child) {
                              final preferences = ref.watch(preferencesProvider).valueOrNull;
                              return _buildCompactModelSelector(preferences);
                            },
                          ),
                          const SizedBox(width: 8),
                          
                          // Send button on the right
                          Container(
                            height: 32, // Match the height of other elements
                            width: 32,  // Make it square like the + button
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: (_hasMessage && hasAnyProvider && !_isSending && !_isInitializing)
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: (_hasMessage && hasAnyProvider && !_isSending && !_isInitializing) 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.5), // Slightly smaller to account for border
                              child: InkWell(
                                onTap: (_hasMessage && hasAnyProvider && !_isSending && !_isInitializing) 
                                    ? _sendMessage 
                                    : null,
                                borderRadius: BorderRadius.circular(6.5),
                                child: Center(
                                  child: _isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_upward,
                                          color: (_hasMessage && hasAnyProvider && !_isSending && !_isInitializing) 
                                              ? Colors.white 
                                              : Colors.grey[600],
                                          size: 16,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    final suggestions = _chatService.getSuggestedQuestions();
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(300.0, 900.0);
    final dialogHeight = widget.isDetached 
        ? screenSize.height 
        : (screenSize.height * 0.85).clamp(400.0, 700.0);
    
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(dialogWidth < 600 ? 12 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome, 
              size: dialogWidth < 400 ? 40 : (dialogWidth < 600 ? 60 : 80), 
              color: Colors.grey[400]
            ),
            SizedBox(height: dialogWidth < 400 ? 12 : (dialogWidth < 600 ? 16 : 24)),
            Text(
              'How can I help you today?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: dialogWidth < 400 ? 18 : (dialogWidth < 600 ? 20 : null),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: dialogWidth < 400 ? 12 : 16),
            if (widget.selectedText != null && widget.selectedText!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(dialogWidth < 400 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_snippet, color: Colors.blue[700], size: dialogWidth < 400 ? 16 : 20),
                        SizedBox(width: dialogWidth < 400 ? 4 : 8),
                        Text(
                          'Selected Text Ready', 
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: dialogWidth < 400 ? 14 : null,
                          )
                        ),
                      ],
                    ),
                    SizedBox(height: dialogWidth < 400 ? 8 : 12),
                    Text(
                      widget.selectedText!.length > 150 
                          ? '${widget.selectedText!.substring(0, 150)}...'
                          : widget.selectedText!,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: dialogWidth < 400 ? 13 : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: dialogWidth < 400 ? 16 : 24),
            ],
            if (suggestions.isNotEmpty) ...[
              Text(
                'Popular questions:',
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  color: Colors.grey,
                  fontSize: dialogWidth < 400 ? 14 : null,
                ),
              ),
              SizedBox(height: dialogWidth < 400 ? 12 : 16),
              Wrap(
                spacing: dialogWidth < 400 ? 4 : 8,
                runSpacing: dialogWidth < 400 ? 4 : 8,
                children: suggestions.take(dialogWidth < 400 ? 4 : 6).map((question) => ActionChip(
                  label: Text(
                    question,
                    style: TextStyle(fontSize: dialogWidth < 400 ? 12 : null),
                  ),
                  onPressed: () => _sendSuggestedQuestion(question),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  materialTapTargetSize: dialogWidth < 400 ? MaterialTapTargetSize.shrinkWrap : null,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          // Info button for AI messages with routing/context info
                          if (!isUser && (message.contextResult != null || message.routeDecision != null))
                            IconButton(
                              onPressed: () => _showMessageInfo(message),
                              icon: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: isUser ? Colors.white70 : Colors.grey[600],
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              tooltip: 'Show routing and context info',
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (!isUser && (message.inputTokens != null || message.outputTokens != null)) ...[
                        const SizedBox(width: 8),
                        MessageTokenUsage(
                          inputTokens: message.inputTokens,
                          outputTokens: message.outputTokens,
                          totalTokens: message.totalTokens,
                          cost: message.cost,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Thinking...'),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompactModelSelector(Preferences? preferences) {
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
      return const Text(
        'No AI Provider',
        style: TextStyle(fontSize: 12, color: Colors.red),
      );
    }
    
    // Auto-select first provider if none selected
    if (_selectedProvider == null && availableProviders.isNotEmpty) {
      final firstProvider = availableProviders.first;
      _selectedProvider = firstProvider['provider'] as AIProvider;
      _selectedModel = firstProvider['model'] as String;
    }
    
    if (availableProviders.length == 1) {
      // Only one provider available, show compact text
      final provider = availableProviders.first;
      return Text(
        provider['displayName'] as String,
        style: TextStyle(fontSize: 12, color: Colors.green[700]),
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // Multiple providers available, show compact dropdown
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      child: DropdownButton<String>(
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
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        underline: const SizedBox.shrink(),
        isDense: true,
      ),
    );
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
      
      // Perform web search if enabled
      String enhancedMessage = message;
      if (_useWebSearch && preferences.webSearchEnabled) {
        try {
          final searchResponse = await _webSearchService.search(
            query: message,
            maxResults: 5,
            apiKey: preferences.webSearchApiKey,
            searchEngineId: preferences.webSearchEngineId,
          );
          
          // Add web search results as context
          enhancedMessage = '$message\n\nWeb Search Context:\n${searchResponse.toContextString()}';
        } catch (e) {
          // If web search fails, continue with original message
          print('Web search failed: $e');
        }
      }
      
      // Add attached file content to message context
      if (_attachedFiles.isNotEmpty) {
        final filesContext = StringBuffer();
        filesContext.writeln('\n\nAttached Files:');
        
        for (final file in _attachedFiles) {
          filesContext.writeln('\n--- ${file.fileName} ---');
          filesContext.writeln(file.content);
          filesContext.writeln('--- End of ${file.fileName} ---');
        }
        
        enhancedMessage = '$enhancedMessage${filesContext.toString()}';
      }
      
      await _chatService.sendMessage(
        userMessage: enhancedMessage,
        provider: provider,
        model: model,
        baseUrl: baseUrl,
        apiKey: apiKey,
        useDocumentContext: _useDocumentContext,
        selectedDocuments: _useDocumentContext ? _selectedDocuments : null,
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
    await _initializeChat();
  }

  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attach File'),
              subtitle: const Text('Add text files to chat context'),
              onTap: () {
                Navigator.pop(context);
                _attachFile();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Toggle Document Context'),
              subtitle: Text(_useDocumentContext ? 'Currently enabled' : 'Currently disabled'),
              onTap: () {
                setState(() {
                  _useDocumentContext = !_useDocumentContext;
                });
                Navigator.pop(context);
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final preferences = ref.watch(preferencesProvider).valueOrNull;
                final isWebSearchConfigured = preferences?.webSearchEnabled ?? false;
                
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Toggle Web Search'),
                  subtitle: Text(_useWebSearch 
                      ? 'Currently enabled' 
                      : isWebSearchConfigured 
                          ? 'Currently disabled'
                          : 'Not configured'),
                  enabled: isWebSearchConfigured,
                  onTap: isWebSearchConfigured ? () {
                    setState(() {
                      _useWebSearch = !_useWebSearch;
                    });
                    Navigator.pop(context);
                  } : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false, // We'll read the files manually for better control
      );

      if (result != null && result.files.isNotEmpty) {
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            await _processAttachedFile(file.path!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAttachedFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = path.basename(filePath);
      final fileSize = await file.length();
      
      // Check file size (limit to 1MB for performance)
      if (fileSize > 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" is too large (max 1MB)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Try to read the file as text
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" is not a valid text file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Check if file is already attached
      if (_attachedFiles.any((f) => f.filePath == filePath)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" is already attached'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Add to attached files
      final attachedFile = AttachedFile(
        filePath: filePath,
        fileName: fileName,
        content: content,
        size: fileSize,
      );
      
      setState(() {
        _attachedFiles.add(attachedFile);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "$fileName" attached successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttachedFilesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attached Files'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 400 : MediaQuery.of(context).size.width * 0.9,
          child: _attachedFiles.isEmpty
              ? const Text('No files attached')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'These files will be included in your chat context:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _attachedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _attachedFiles[index];
                          return ListTile(
                            leading: const Icon(Icons.text_snippet, color: Colors.orange),
                            title: Text(
                              file.fileName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB • ${file.content.split('\n').length} lines',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _attachedFiles.removeAt(index);
                                });
                                Navigator.pop(context);
                                if (_attachedFiles.isNotEmpty) {
                                  _showAttachedFilesDialog(); // Refresh the dialog
                                }
                              },
                              tooltip: 'Remove file',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _attachedFiles.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDocumentSelectionDialog() async {
    final allDocuments = await _documentIndex.getIndexedDocuments();
    
    if (!mounted) return;
    
    if (allDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No documents found. Open a folder or file first.'),
        ),
      );
      return;
    }
    
    // Create a local copy for dialog state
    Set<String> tempSelectedDocuments = Set<String>.from(_selectedDocuments);
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.library_books),
              SizedBox(width: 8),
              Text('Select Documents'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Select all/none controls
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          tempSelectedDocuments = Set<String>.from(
                            allDocuments.map((doc) => doc['path'] as String)
                          );
                        });
                      },
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('Select All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          tempSelectedDocuments.clear();
                        });
                      },
                      icon: const Icon(Icons.deselect, size: 16),
                      label: const Text('Select None'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tempSelectedDocuments.length} of ${allDocuments.length} documents selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Document list
                Expanded(
                  child: ListView.builder(
                    itemCount: allDocuments.length,
                    itemBuilder: (context, index) {
                      final document = allDocuments[index];
                      final path = document['path'] as String;
                      final fileName = path.split('/').last;
                      final isSelected = tempSelectedDocuments.contains(path);
                      
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              tempSelectedDocuments.add(path);
                            } else {
                              tempSelectedDocuments.remove(path);
                            }
                          });
                        },
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          path,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDocuments = tempSelectedDocuments;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _detachToSeparateWindow() async {
    // Close the current dialog
    Navigator.of(context).pop();
    
    // Open the chat in fullscreen mode
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DetachedChatWindow(
          initialMessages: _chatService.messages,
          useDocumentContext: _useDocumentContext,
          useWebSearch: _useWebSearch,
          selectedDocuments: _selectedDocuments,
          attachedFiles: _attachedFiles,
        ),
        fullscreenDialog: true,
      ),
    );
  }
  

  void _showMessageInfo(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('Message Details'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 400 : MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp and basic info
                Text(
                  'Generated at ${_formatTime(message.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Token usage
                if (message.inputTokens != null || message.outputTokens != null) ...[
                  const Text(
                    'Token Usage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.inputTokens != null)
                          Text('Input: ${message.inputTokens} tokens'),
                        if (message.outputTokens != null)
                          Text('Output: ${message.outputTokens} tokens'),
                        if (message.totalTokens != null)
                          Text('Total: ${message.totalTokens} tokens'),
                        if (message.cost != null)
                          Text('Cost: \$${message.cost!.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Routing decision
                if (message.routeDecision != null) ...[
                  const Text(
                    'AI Routing Decision',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Provider: ${message.routeDecision!.provider.name.toUpperCase()}'),
                        const SizedBox(height: 4),
                        Text('Reasoning: ${message.routeDecision!.reasoning}'),
                        if (message.routeDecision!.confidence != null)
                          Text('Confidence: ${(message.routeDecision!.confidence! * 100).toStringAsFixed(1)}%'),
                        if (message.routeDecision!.estimatedCost != null)
                          Text('Estimated Cost: \$${message.routeDecision!.estimatedCost!.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Context information
                if (message.contextResult != null) ...[
                  const Text(
                    'Document Context',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Strategy: ${message.contextResult!.strategyUsed}'),
                        const SizedBox(height: 4),
                        Text('Documents Used: ${message.contextResult!.filesUsed.length}'),
                        Text('Total Tokens: ${message.contextResult!.tokenCount}'),
                        if (message.contextResult!.explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Summary:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.contextResult!.explanation,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}

// CompactRoutingIndicator is imported from routing_decision_indicator.dart

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
    if (totalTokens == null || totalTokens == 0) return const SizedBox.shrink();
    
    return Text(
      'Tokens: ${totalTokens ?? 0}${cost != null ? ' • \$${cost!.toStringAsFixed(3)}' : ''}',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
      ),
    );
  }
}