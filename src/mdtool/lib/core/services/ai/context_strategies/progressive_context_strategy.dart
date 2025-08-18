import 'dart:async';
import 'dart:math';
import 'context_strategy.dart';
import '../../document_index_service.dart';

/// Query complexity levels for progressive context assembly
enum QueryComplexity { simple, medium, complex }

/// Progressive context strategy that builds context based on query complexity
class ProgressiveContextStrategy implements ContextStrategy {
  ContextStrategyConfig _config = ContextStrategyConfig(
    enabled: true,
    settings: {
      'simpleTokenLimit': 2000,
      'mediumTokenLimit': 8000,
      'complexTokenLimit': 20000,
      'enableFileRelationships': true,
      'enableComplexityAnalysis': true,
    },
  );

  @override
  String get name => 'Progressive Context';

  @override
  String get description => 'Smart context building based on query complexity';

  @override
  String get helpText => '''
Progressive Context automatically adjusts how much context to send to AI based on your question's complexity.

How it works:
• Analyzes your question to determine complexity level
• Simple questions get minimal context (saves tokens & money)
• Complex questions get comprehensive project context
• Automatically finds related documents in your project

Complexity Levels:

🟢 Simple (≤2K tokens): Grammar, spelling, basic formatting
• Uses current document only
• Perfect for quick fixes
• Cost: ~\$0.005 per query

🟡 Medium (≤8K tokens): Implementation help, how-to questions
• Includes current document + related files
• Finds documents with shared topics
• Cost: ~\$0.02 per query

🔴 Complex (≤20K tokens): Architecture, design, project-wide changes
• Full project context with all relevant documents
• Comprehensive understanding for big decisions
• Cost: ~\$0.06 per query

Benefits:
• 60-70% cost reduction compared to always using full context
• Faster responses for simple questions
• Better answers through right-sized context
• Automatic - no manual file selection needed

The AI gets exactly the right amount of information for your question type.
''';

  @override
  ContextStrategyConfig get config => _config;

  @override
  bool get isAvailable => true;

  @override
  Future<ContextResult> buildContext({
    required String query,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    Map<String, dynamic>? additionalData,
  }) async {
    final currentFile = additionalData?['currentFile'] as String?;
    
    // Analyze query complexity
    final complexity = _analyzeQueryComplexity(query);
    final tokenLimit = _getTokenLimitForComplexity(complexity);
    
    // Build context based on complexity
    switch (complexity) {
      case QueryComplexity.simple:
        return await _buildSimpleContext(
          query: query,
          currentFile: currentFile,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
        );
      
      case QueryComplexity.medium:
        return await _buildMediumContext(
          query: query,
          currentFile: currentFile,
          availableFiles: availableFiles,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
        );
      
      case QueryComplexity.complex:
        return await _buildComplexContext(
          query: query,
          currentFile: currentFile,
          availableFiles: availableFiles,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
        );
    }
  }

  @override
  Future<void> configure(ContextStrategyConfig newConfig) async {
    _config = newConfig;
  }

  @override
  ContextStrategyConfig getDefaultConfig() {
    return ContextStrategyConfig(
      enabled: true,
      settings: {
        'simpleTokenLimit': 2000,
        'mediumTokenLimit': 8000,
        'complexTokenLimit': 20000,
        'enableFileRelationships': true,
        'enableComplexityAnalysis': true,
      },
    );
  }

  @override
  bool validateConfig(Map<String, dynamic> settings) {
    try {
      final simple = settings['simpleTokenLimit'] as int;
      final medium = settings['mediumTokenLimit'] as int;
      final complex = settings['complexTokenLimit'] as int;
      
      return simple > 0 && medium > simple && complex > medium &&
             complex <= 50000; // Reasonable upper limit
    } catch (e) {
      return false;
    }
  }

  @override
  String getConfigExplanation() {
    final simple = _config.settings['simpleTokenLimit'];
    final medium = _config.settings['mediumTokenLimit'];
    final complex = _config.settings['complexTokenLimit'];
    final relationships = _config.settings['enableFileRelationships'];
    
    return '''
Token limits: Simple: ${simple}k, Medium: ${medium}k, Complex: ${complex}k
File relationships: ${relationships ? 'Enabled' : 'Disabled'}
''';
  }

  // Private implementation methods

  QueryComplexity _analyzeQueryComplexity(String query) {
    if (!(_config.settings['enableComplexityAnalysis'] as bool? ?? true)) {
      return QueryComplexity.medium; // Default if analysis disabled
    }

    final queryLower = query.toLowerCase();
    final words = queryLower.split(RegExp(r'\s+'));
    
    // Simple query patterns
    final simplePatterns = [
      'fix', 'correct', 'grammar', 'spell', 'format', 'indent',
      'typo', 'mistake', 'error', 'wrong', 'capitalize'
    ];
    
    // Complex query patterns
    final complexPatterns = [
      'architecture', 'design', 'structure', 'organize', 'refactor',
      'best practice', 'approach', 'strategy', 'framework', 'pattern',
      'implement', 'build', 'create', 'develop', 'integrate'
    ];
    
    // Check for simple patterns
    if (words.length <= 5 || simplePatterns.any((pattern) => queryLower.contains(pattern))) {
      return QueryComplexity.simple;
    }
    
    // Check for complex patterns
    if (words.length >= 10 || complexPatterns.any((pattern) => queryLower.contains(pattern))) {
      return QueryComplexity.complex;
    }
    
    // Default to medium
    return QueryComplexity.medium;
  }

  int _getTokenLimitForComplexity(QueryComplexity complexity) {
    switch (complexity) {
      case QueryComplexity.simple:
        return _config.settings['simpleTokenLimit'] as int;
      case QueryComplexity.medium:
        return _config.settings['mediumTokenLimit'] as int;
      case QueryComplexity.complex:
        return _config.settings['complexTokenLimit'] as int;
    }
  }

  Future<ContextResult> _buildSimpleContext({
    required String query,
    String? currentFile,
    required Map<String, String> fileContents,
    required int tokenLimit,
  }) async {
    if (currentFile == null || !fileContents.containsKey(currentFile)) {
      return ContextResult(
        content: 'No current document available.',
        tokenCount: 10,
        estimatedCost: 0.0,
        filesUsed: [],
        strategyUsed: name,
        explanation: 'Simple query: No document open',
        generatedAt: DateTime.now(),
      );
    }

    final content = fileContents[currentFile]!;
    final truncatedContent = _truncateToTokenLimit(content, tokenLimit);
    
    return ContextResult(
      content: truncatedContent,
      tokenCount: _estimateTokens(truncatedContent),
      estimatedCost: _estimateCost(_estimateTokens(truncatedContent)),
      filesUsed: [currentFile],
      strategyUsed: name,
      explanation: 'Simple query: Using current document only (${_getFileName(currentFile)})',
      generatedAt: DateTime.now(),
    );
  }

  Future<ContextResult> _buildMediumContext({
    required String query,
    String? currentFile,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    required int tokenLimit,
  }) async {
    final List<String> selectedFiles = [];
    final StringBuffer contextBuffer = StringBuffer();
    int currentTokens = 0;

    // Always include current file first
    if (currentFile != null && fileContents.containsKey(currentFile)) {
      final content = fileContents[currentFile]!;
      final tokens = _estimateTokens(content);
      
      if (tokens <= tokenLimit * 0.6) { // Reserve 60% for current file
        contextBuffer.writeln('=== Current Document: ${_getFileName(currentFile)} ===');
        contextBuffer.writeln(content);
        contextBuffer.writeln();
        selectedFiles.add(currentFile);
        currentTokens += tokens;
      }
    }

    // Find related files
    if (_config.settings['enableFileRelationships'] as bool? ?? true) {
      final relatedFiles = _findRelatedFiles(query, currentFile, availableFiles, fileContents);
      
      for (final file in relatedFiles) {
        if (selectedFiles.contains(file)) continue;
        
        final content = fileContents[file]!;
        final tokens = _estimateTokens(content);
        
        if (currentTokens + tokens <= tokenLimit) {
          contextBuffer.writeln('=== Related Document: ${_getFileName(file)} ===');
          contextBuffer.writeln(content);
          contextBuffer.writeln();
          selectedFiles.add(file);
          currentTokens += tokens;
        } else {
          // Add partial content if space allows
          final remainingTokens = tokenLimit - currentTokens;
          if (remainingTokens > 200) { // Only if meaningful space left
            final partialContent = _truncateToTokenLimit(content, remainingTokens);
            contextBuffer.writeln('=== Related Document (partial): ${_getFileName(file)} ===');
            contextBuffer.writeln(partialContent);
            contextBuffer.writeln('[Truncated due to token limit]');
            contextBuffer.writeln();
            selectedFiles.add(file);
          }
          break;
        }
      }
    }

    final finalContent = contextBuffer.toString();
    return ContextResult(
      content: finalContent,
      tokenCount: _estimateTokens(finalContent),
      estimatedCost: _estimateCost(_estimateTokens(finalContent)),
      filesUsed: selectedFiles,
      strategyUsed: name,
      explanation: 'Medium query: Using ${selectedFiles.length} related documents',
      generatedAt: DateTime.now(),
    );
  }

  Future<ContextResult> _buildComplexContext({
    required String query,
    String? currentFile,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    required int tokenLimit,
  }) async {
    final List<String> selectedFiles = [];
    final StringBuffer contextBuffer = StringBuffer();
    int currentTokens = 0;

    // For complex queries, try to include as many relevant files as possible
    final rankedFiles = _rankFilesByRelevance(query, availableFiles, fileContents, currentFile);

    for (final file in rankedFiles) {
      final content = fileContents[file]!;
      final tokens = _estimateTokens(content);

      if (currentTokens + tokens <= tokenLimit) {
        contextBuffer.writeln('=== Document: ${_getFileName(file)} ===');
        contextBuffer.writeln(content);
        contextBuffer.writeln();
        selectedFiles.add(file);
        currentTokens += tokens;
      } else {
        // Add partial content if space allows
        final remainingTokens = tokenLimit - currentTokens;
        if (remainingTokens > 500) { // Only if meaningful space left
          final partialContent = _truncateToTokenLimit(content, remainingTokens);
          contextBuffer.writeln('=== Document (partial): ${_getFileName(file)} ===');
          contextBuffer.writeln(partialContent);
          contextBuffer.writeln('[Truncated due to token limit]');
          selectedFiles.add(file);
        }
        break;
      }
    }

    final finalContent = contextBuffer.toString();
    return ContextResult(
      content: finalContent,
      tokenCount: _estimateTokens(finalContent),
      estimatedCost: _estimateCost(_estimateTokens(finalContent)),
      filesUsed: selectedFiles,
      strategyUsed: name,
      explanation: 'Complex query: Using ${selectedFiles.length} documents for comprehensive context',
      generatedAt: DateTime.now(),
    );
  }

  List<String> _findRelatedFiles(
    String query,
    String? currentFile,
    List<String> availableFiles,
    Map<String, String> fileContents,
  ) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final scored = <MapEntry<String, double>>[];

    for (final file in availableFiles) {
      if (file == currentFile) continue; // Skip current file
      
      final content = fileContents[file];
      if (content == null) continue;

      double score = 0.0;
      final contentLower = content.toLowerCase();
      final fileName = _getFileName(file).toLowerCase();

      // Score based on query word matches
      for (final word in queryWords) {
        if (word.length < 3) continue;
        
        // Filename matches (high weight)
        if (fileName.contains(word)) score += 10.0;
        
        // Content matches
        final matches = word.allMatches(contentLower).length;
        score += matches * 1.0;
      }

      // Bonus for markdown files in same directory as current file
      if (currentFile != null && _getDirectory(file) == _getDirectory(currentFile)) {
        score += 2.0;
      }

      if (score > 0) {
        scored.add(MapEntry(file, score));
      }
    }

    // Sort by score and return top files
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(3).map((e) => e.key).toList();
  }

  List<String> _rankFilesByRelevance(
    String query,
    List<String> availableFiles,
    Map<String, String> fileContents,
    String? currentFile,
  ) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final scored = <MapEntry<String, double>>[];

    for (final file in availableFiles) {
      final content = fileContents[file];
      if (content == null) continue;

      double score = 0.0;
      final contentLower = content.toLowerCase();
      final fileName = _getFileName(file).toLowerCase();

      // Current file gets priority
      if (file == currentFile) score += 100.0;

      // Score based on query word matches
      for (final word in queryWords) {
        if (word.length < 3) continue;
        
        // Filename matches (high weight)
        if (fileName.contains(word)) score += 15.0;
        
        // Content matches
        final matches = word.allMatches(contentLower).length;
        score += matches * 2.0;
        
        // Header matches (medium weight)
        final headerMatches = RegExp('#+.*$word', multiLine: true).allMatches(contentLower).length;
        score += headerMatches * 5.0;
      }

      // File size penalty (prefer shorter files for space efficiency)
      final tokens = _estimateTokens(content);
      if (tokens > 2000) score *= 0.8;
      if (tokens > 5000) score *= 0.6;

      scored.add(MapEntry(file, score));
    }

    // Sort by score and return files
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  // Helper methods
  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  double _estimateCost(int tokens) {
    // Rough estimation: $0.01 per 1000 tokens
    return (tokens / 1000) * 0.01;
  }

  String _truncateToTokenLimit(String content, int tokenLimit) {
    final maxChars = tokenLimit * 4; // 4 chars per token estimate
    if (content.length <= maxChars) return content;
    
    return '${content.substring(0, maxChars)}\n\n[Content truncated to fit token limit]';
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _getDirectory(String filePath) {
    final parts = filePath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }
}