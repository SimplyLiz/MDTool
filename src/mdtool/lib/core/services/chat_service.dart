import 'dart:convert';
import 'ollama_service.dart';
import 'openai_service.dart';
import 'document_index_service.dart';
import 'metrics_service.dart';
import 'ai/context_strategies/context_strategy_manager.dart';
import 'ai/context_strategies/context_strategy.dart';
import 'ai/ai_routing_manager.dart';
import 'ai/ai_analytics_service.dart';

enum AIProvider {
  ollama('Ollama'),
  openai('OpenAI');

  const AIProvider(this.displayName);
  final String displayName;
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? context;
  final AIProvider? provider;
  final String? model;
  final ContextResult? contextResult;
  final RouteDecision? routeDecision;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final double? cost;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.context,
    this.provider,
    this.model,
    this.contextResult,
    this.routeDecision,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.cost,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'provider': provider?.name,
      'model': model,
      'contextResult': contextResult?.toJson(),
      'routeDecision': routeDecision != null ? {
        'provider': routeDecision!.provider.name,
        'reasoning': routeDecision!.reasoning,
        'confidence': routeDecision!.confidence,
        'estimatedCost': routeDecision!.estimatedCost,
      } : null,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'cost': cost,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    AIProvider? provider;
    if (json['provider'] != null) {
      try {
        provider = AIProvider.values.firstWhere((p) => p.name == json['provider']);
      } catch (e) {
        // Provider not found, leave as null
      }
    }
    
    ContextResult? contextResult;
    if (json['contextResult'] != null) {
      try {
        contextResult = ContextResult.fromJson(json['contextResult']);
      } catch (e) {
        // Ignore parsing errors for backward compatibility
      }
    }

    RouteDecision? routeDecision;
    if (json['routeDecision'] != null) {
      try {
        final routeData = json['routeDecision'] as Map<String, dynamic>;
        final providerName = routeData['provider'] as String;
        final provider = AIProvider.values.firstWhere((p) => p.name == providerName);
        
        routeDecision = RouteDecision(
          provider: provider,
          reasoning: routeData['reasoning'] ?? '',
          confidence: (routeData['confidence'] ?? 0.0).toDouble(),
          estimatedCost: (routeData['estimatedCost'] ?? 0.0).toDouble(),
        );
      } catch (e) {
        // Ignore parsing errors for backward compatibility
      }
    }
    
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      provider: provider,
      model: json['model'],
      contextResult: contextResult,
      routeDecision: routeDecision,
      inputTokens: json['inputTokens'],
      outputTokens: json['outputTokens'],
      totalTokens: json['totalTokens'],
      cost: json['cost']?.toDouble(),
    );
  }
}

class ChatService {
  static ChatService? _instance;
  final List<ChatMessage> _messages = [];
  final DocumentIndexService _documentIndex = DocumentIndexService.instance;
  final ContextStrategyManager _contextManager = ContextStrategyManager.instance;
  final AIRoutingManager _routingManager = AIRoutingManager.instance;
  final AIAnalyticsService _analyticsService = AIAnalyticsService.instance;
  final MetricsService _metricsService = MetricsService.instance;

  ChatService._();

  static ChatService get instance {
    _instance ??= ChatService._();
    return _instance!;
  }

  /// Get all chat messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Add a message to the chat
  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  /// Clear all chat messages
  void clearChat() {
    _messages.clear();
  }

  /// Send a message and get response from AI provider with document context
  Future<ChatMessage> sendMessage({
    required String userMessage,
    AIProvider? provider,  // Now optional - will be determined by routing
    required String model,
    String? baseUrl,
    String? apiKey,
    bool useDocumentContext = true,
    Set<String>? selectedDocuments, // Optional: specific documents to use for context
  }) async {
    // Initialize metrics service
    await _metricsService.initialize();
    // Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    addMessage(userMsg);

    try {
      // Get document context using context strategy
      ContextResult? contextResult;
      String? documentContext;
      
      if (useDocumentContext) {
        print('DEBUG: [ENHANCED] Building context using strategy: ${_contextManager.activeStrategy.name}');
        
        // Prepare file data for context strategies
        final documentsToUse = selectedDocuments != null
            ? _documentIndex.documents.where((doc) => selectedDocuments.contains(doc.filePath)).toList()
            : _documentIndex.documents;
        
        final availableFiles = documentsToUse.map((doc) => doc.filePath).toList();
        final fileContents = <String, String>{};
        for (final doc in documentsToUse) {
          fileContents[doc.filePath] = doc.content;
        }
        
        // Get current file from additional data if available
        final additionalData = <String, dynamic>{};
        // TODO: Get current file from app state when available
        // additionalData['currentFile'] = getCurrentFilePath();
        
        // Build context using strategy
        contextResult = await _contextManager.buildContext(
          query: userMessage,
          availableFiles: availableFiles,
          fileContents: fileContents,
          additionalData: additionalData,
        );
        
        documentContext = contextResult.content;
        
        print('DEBUG: Strategy: ${contextResult.strategyUsed}');
        print('DEBUG: Token count: ${contextResult.tokenCount}');
        print('DEBUG: Estimated cost: \$${contextResult.estimatedCost.toStringAsFixed(3)}');
        print('DEBUG: Files used: ${contextResult.filesUsed.length}');
        print('DEBUG: Explanation: ${contextResult.explanation}');
        
        if (documentContext.isNotEmpty) {
          print('DEBUG: Context preview: ${documentContext.substring(0, (documentContext.length).clamp(0, 200))}...');
        }
        
        // TODO: Update provider when riverpod is properly integrated
        // ref.read(lastContextResultProvider.notifier).state = contextResult;
      }

      // Determine AI provider using routing manager
      RouteDecision? routeDecision;
      AIProvider finalProvider;
      
      if (provider != null) {
        // Manual mode - use specified provider
        finalProvider = provider;
        routeDecision = RouteDecision(
          provider: provider,
          reasoning: 'Manual selection',
          confidence: 1.0,
          estimatedCost: provider == AIProvider.ollama ? 0.0 : 0.05,
        );
      } else {
        // Auto mode - let routing manager decide
        routeDecision = _routingManager.decideRoute(
          userMessage,
          ollamaAvailable: baseUrl != null,
          openaiAvailable: apiKey != null && apiKey.isNotEmpty,
        );
        finalProvider = routeDecision.provider;
        
        print('DEBUG: Auto routing decision: ${routeDecision.provider.displayName}');
        print('DEBUG: Reasoning: ${routeDecision.reasoning}');
        print('DEBUG: Confidence: ${(routeDecision.confidence * 100).toInt()}%');
        print('DEBUG: Estimated cost: \$${routeDecision.estimatedCost.toStringAsFixed(3)}');
      }

      // Check if usage is blocked for the selected provider
      if (_metricsService.isUsageBlocked(provider: finalProvider.name)) {
        final summary = _metricsService.getUsageSummary();
        final limits = _metricsService.limits;

        String limitMessage = 'Local usage limit exceeded (this is not an OpenAI API error).\n\n';

        if (summary.dailyLimitExceeded) {
          limitMessage += 'Daily limits: ${summary.totalTokensToday} / ${limits.dailyTokenLimit} tokens, ';
          limitMessage += '\$${summary.totalCostToday.toStringAsFixed(3)} / \$${limits.dailyCostLimit.toStringAsFixed(2)}\n';
        }
        if (summary.monthlyLimitExceeded) {
          limitMessage += 'Monthly limits: ${summary.totalTokensThisMonth} / ${limits.monthlyTokenLimit} tokens, ';
          limitMessage += '\$${summary.totalCostThisMonth.toStringAsFixed(3)} / \$${limits.monthlyCostLimit.toStringAsFixed(2)}\n';
        }

        limitMessage += '\nTo continue:\n';
        limitMessage += '• Adjust limits in Preferences → Usage Limits\n';
        limitMessage += '• Or disable limits entirely\n';
        limitMessage += '• Or use Ollama (always unlimited)';

        final errorMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: limitMessage,
          isUser: false,
          timestamp: DateTime.now(),
          provider: finalProvider,
          model: model,
        );
        addMessage(errorMsg);
        return errorMsg;
      }

      // Prepare the system message with context
      String systemMessage = '''You are an AI assistant helping with Markdown documents. You have comprehensive access to the user's indexed Markdown files with detailed document analysis including structure, topics, and relevance scoring.

When answering questions:
1. **Use the rich document context**: The context includes document structure, key topics, relevance scores, tags, and targeted excerpts
2. **Reference specific documents**: Mention document names, modification dates, and relevance scores when applicable
3. **Leverage document structure**: Use the provided headers and document organization to give comprehensive answers
4. **Cite context accurately**: When information comes from the documents, be specific about which document and section
5. **Explain relevance**: If multiple documents match, explain why each document is relevant to the query
6. **Handle missing info gracefully**: If you don't find relevant information in the documents, clearly state this and offer general knowledge if appropriate
7. **Suggest document organization**: Help with tagging, structuring, and connecting related documents
8. **Use document statistics**: Leverage word counts, modification dates, and document quality metrics in your responses

The document context includes:
- Document file names and paths
- Last modification times
- Relevance scores for the current query
- Document structure (headers and sections)
- Key topics and themes
- Tags and metadata
- Relevant excerpts (not just truncated content)
- Common themes across documents

Be conversational, thorough, and demonstrate deep understanding of the provided document context.''';

      // Prepare the conversation history
      final conversationMessages = <Map<String, String>>[];
      
      // Add system message
      conversationMessages.add({
        'role': 'system',
        'content': systemMessage,
      });

      // Add document context if available
      if (documentContext != null && documentContext.isNotEmpty) {
        conversationMessages.add({
          'role': 'system',
          'content': 'Document Context:\n$documentContext',
        });
      }

      // Add recent conversation history (last 10 messages)
      final recentMessages = _messages.length > 10 
          ? _messages.sublist(_messages.length - 10)
          : _messages;

      for (final msg in recentMessages) {
        if (msg.id != userMsg.id) { // Don't include the current user message again
          conversationMessages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }

      // Add current user message
      conversationMessages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Get response from the routed provider with token tracking
      String response;
      int inputTokens = 0;
      int outputTokens = 0;
      int totalTokens = 0;
      double cost = 0.0;
      
      switch (finalProvider) {
        case AIProvider.ollama:
          if (baseUrl == null) throw Exception('Base URL required for Ollama');
          final ollamaResponse = await OllamaService.instance.chatCompletionWithUsage(
            baseUrl: baseUrl,
            model: model,
            messages: conversationMessages,
            temperature: 0.7,
            maxTokens: 2000,
          );
          response = ollamaResponse.content;
          inputTokens = ollamaResponse.inputTokens;
          outputTokens = ollamaResponse.outputTokens;
          totalTokens = ollamaResponse.totalTokens;
          cost = 0.0; // Ollama is free
          break;
        case AIProvider.openai:
          if (apiKey == null) throw Exception('API key required for OpenAI');
          final openaiResponse = await OpenAIService.instance.chatCompletionWithUsage(
            apiKey: apiKey,
            model: model,
            messages: conversationMessages,
            baseUrl: baseUrl ?? 'https://api.openai.com/v1',
            temperature: 0.7,
            maxTokens: 2000,
          );
          response = openaiResponse.content;
          inputTokens = openaiResponse.inputTokens;
          outputTokens = openaiResponse.outputTokens;
          totalTokens = openaiResponse.totalTokens;
          cost = _calculateCost(model, inputTokens, outputTokens);
          break;
      }

      // Create and add assistant message with token information
      final assistantMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      final assistantMsg = ChatMessage(
        id: assistantMessageId,
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        context: documentContext,
        provider: finalProvider,
        model: model,
        contextResult: contextResult,
        routeDecision: routeDecision,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
        cost: cost,
      );
      addMessage(assistantMsg);

      // Record token usage in metrics service
      if (totalTokens > 0) {
        await _metricsService.recordTokenUsage(
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          cost: cost,
          provider: finalProvider.name,
          model: model,
          messageId: assistantMessageId,
        );
      }

      // Record usage analytics
      if (routeDecision != null) {
        try {
          await _analyticsService.recordUsage(
            provider: finalProvider,
            model: model,
            query: userMessage,
            complexity: _getQueryComplexity(userMessage),
            actualCost: routeDecision.estimatedCost,
            wasAutoRouted: provider == null, // Auto-routed if no provider specified
            confidence: routeDecision.confidence,
            tokenCount: contextResult?.tokenCount ?? userMessage.length ~/ 4,
          );
        } catch (e) {
          print('DEBUG: Error recording analytics: $e');
        }
      }

      return assistantMsg;
    } catch (e) {
      // Create error message
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        provider: provider ?? AIProvider.ollama,
        model: model,
      );
      addMessage(errorMsg);
      return errorMsg;
    }
  }

  /// Get a summary of the current conversation
  String getConversationSummary() {
    if (_messages.isEmpty) return 'No conversation yet.';

    final userMessages = _messages.where((msg) => msg.isUser).length;
    final assistantMessages = _messages.where((msg) => !msg.isUser).length;

    return 'Conversation: $userMessages messages from you, $assistantMessages responses. Started ${_formatTime(_messages.first.timestamp)}.';
  }

  /// Export chat history as Markdown
  String exportChatAsMarkdown() {
    if (_messages.isEmpty) return '# Chat History\n\nNo messages yet.';

    final buffer = StringBuffer();
    buffer.writeln('# Chat History');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final message in _messages) {
      final sender = message.isUser ? 'You' : 'Assistant';
      final time = _formatTime(message.timestamp);
      
      buffer.writeln('## $sender - $time');
      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();

      if (message.context != null) {
        buffer.writeln('*Context used: Document references included*');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Load chat history from JSON
  void loadChatHistory(String jsonData) {
    try {
      final List<dynamic> messagesJson = jsonDecode(jsonData);
      _messages.clear();
      for (final messageJson in messagesJson) {
        _messages.add(ChatMessage.fromJson(messageJson));
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  /// Save chat history to JSON
  String saveChatHistory() {
    final messagesJson = _messages.map((msg) => msg.toJson()).toList();
    return jsonEncode(messagesJson);
  }

  /// Check if documents are available for context
  bool get hasDocumentContext => _documentIndex.documents.isNotEmpty;

  /// Get available AI providers based on configuration
  List<Map<String, dynamic>> getAvailableProviders({
    bool? ollamaEnabled,
    bool? openaiEnabled,
    String? ollamaBaseUrl,
    String? ollamaModel,
    String? openaiApiKey,
    String? openaiModel,
  }) {
    final providers = <Map<String, dynamic>>[];
    
    if (ollamaEnabled == true && ollamaBaseUrl != null && ollamaModel != null) {
      providers.add({
        'provider': AIProvider.ollama,
        'displayName': 'Ollama ($ollamaModel)',
        'model': ollamaModel,
        'available': true,
      });
    }
    
    if (openaiEnabled == true && openaiApiKey != null && openaiApiKey.isNotEmpty && openaiModel != null) {
      providers.add({
        'provider': AIProvider.openai,
        'displayName': 'OpenAI ($openaiModel)',
        'model': openaiModel,
        'available': true,
      });
    }
    
    return providers;
  }

  /// Get statistics about indexed documents
  Map<String, dynamic> getDocumentStats() {
    final docs = _documentIndex.documents;
    final totalDocs = docs.length;
    final totalTags = docs.expand((doc) => doc.tags).toSet().length;
    final recentDocs = docs.where((doc) => 
      DateTime.now().difference(doc.lastModified).inDays < 7
    ).length;

    return {
      'totalDocuments': totalDocs,
      'uniqueTags': totalTags,
      'recentDocuments': recentDocs,
      'oldestDocument': docs.isEmpty ? null : docs.map((d) => d.lastModified).reduce((a, b) => a.isBefore(b) ? a : b),
      'newestDocument': docs.isEmpty ? null : docs.map((d) => d.lastModified).reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// Get suggested questions based on document content
  List<String> getSuggestedQuestions() {
    if (!hasDocumentContext) {
      return [
        'What can you help me with?',
        'How do I organize my markdown files?',
        'Show me markdown formatting tips',
      ];
    }

    final docs = _documentIndex.documents;
    final suggestions = <String>[];

    // Common tags
    final allTags = docs.expand((doc) => doc.tags).toList();
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }

    final commonTags = tagCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(3)
        .toList();

    for (final tag in commonTags) {
      suggestions.add('Tell me about documents tagged with "$tag"');
    }

    // File-based suggestions
    if (docs.length > 5) {
      suggestions.add('What are my most recent documents about?');
      suggestions.add('Summarize the main topics in my documents');
    }

    suggestions.addAll([
      'Help me organize these documents',
      'Find documents related to a specific topic',
      'What questions can I ask about my documents?',
    ]);

    return suggestions.take(6).toList();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  QueryComplexity _getQueryComplexity(String query) {
    final queryLower = query.toLowerCase();
    final words = queryLower.split(RegExp(r'\s+'));

    // Simple patterns: grammar, spelling, basic fixes
    final simplePatterns = [
      'fix', 'correct', 'grammar', 'spell', 'format', 'typo', 'mistake', 'capitalize'
    ];

    // Complex patterns: architecture, design, implementation
    final complexPatterns = [
      'architecture', 'design', 'implement', 'build', 'create', 'refactor',
      'best practice', 'approach', 'strategy', 'framework', 'integrate'
    ];

    if (words.length <= 5 || simplePatterns.any((p) => queryLower.contains(p))) {
      return QueryComplexity.simple;
    }

    if (words.length >= 10 || complexPatterns.any((p) => queryLower.contains(p))) {
      return QueryComplexity.complex;
    }

    return QueryComplexity.medium;
  }

  /// Calculate cost based on model and token usage
  double _calculateCost(String model, int inputTokens, int outputTokens) {
    // OpenAI GPT-5 pricing (approximate, adjust as needed)
    const inputCostPer1KTokens = {
      'gpt-5-nano': 0.0001,
      'gpt-5-mini': 0.0002,
      'gpt-5': 0.005,
      'gpt-5-chat-latest': 0.003,
    };
    
    const outputCostPer1KTokens = {
      'gpt-5-nano': 0.0003,
      'gpt-5-mini': 0.0006,
      'gpt-5': 0.015,
      'gpt-5-chat-latest': 0.009,
    };

    final inputRate = inputCostPer1KTokens[model] ?? 0.003;
    final outputRate = outputCostPer1KTokens[model] ?? 0.009;

    final inputCost = (inputTokens / 1000) * inputRate;
    final outputCost = (outputTokens / 1000) * outputRate;

    return inputCost + outputCost;
  }

  /// Get current usage summary
  UsageSummary getCurrentUsage() {
    return _metricsService.getUsageSummary();
  }

  /// Check if usage is currently blocked for a specific provider
  bool isUsageBlocked({String? provider}) {
    return _metricsService.isUsageBlocked(provider: provider);
  }
}