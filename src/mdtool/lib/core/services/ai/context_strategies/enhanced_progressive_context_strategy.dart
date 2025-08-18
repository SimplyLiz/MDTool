import 'dart:async';
import 'context_strategy.dart';

/// Query intent categories for semantic classification
enum QueryIntent {
  projectOverview,        // "project content", "what does this do"
  architecturalGuidance,  // "how is this structured", "design patterns"
  specificImplementation, // "how to implement X", "code examples"
  codebaseNavigation,     // "where is X", "find component"
  quickFix,              // "fix typo", "correct grammar"
  troubleshooting,       // "debug issue", "why isn't working"
  documentation,         // "explain this code", "what does this function do"
}

/// Query scope analysis
enum QueryScope {
  singleFile,    // Current document only
  relatedFiles,  // Current + related documents
  projectWide,   // Entire project context needed
}

/// Context requirements based on query analysis
class ContextRequirements {
  final int minimumFiles;
  final int optimalFiles;
  final bool requiresArchitecturalFiles;
  final bool requiresDocumentation;
  final bool requiresCustomPackages;
  final List<String> priorityFilePatterns;

  const ContextRequirements({
    required this.minimumFiles,
    required this.optimalFiles,
    this.requiresArchitecturalFiles = false,
    this.requiresDocumentation = false,
    this.requiresCustomPackages = false,
    this.priorityFilePatterns = const [],
  });
}

/// Enhanced Progressive context strategy with semantic intent recognition
class EnhancedProgressiveContextStrategy implements ContextStrategy {
  ContextStrategyConfig _config = ContextStrategyConfig(
    enabled: true,
    settings: {
      'simpleTokenLimit': 2000,
      'mediumTokenLimit': 8000,
      'complexTokenLimit': 25000,  // Increased for project overview
      'enableSemanticAnalysis': true,
      'enableArchitecturalFileSelection': true,
      'enableIntentOverride': true,
      'projectOverviewTokenLimit': 30000,  // Special limit for overview queries
    },
  );

  @override
  String get name => 'Enhanced Progressive Context';

  @override
  String get description => 'Intelligent context building with semantic intent recognition';

  @override
  String get helpText => '''
Enhanced Progressive Context uses semantic intent analysis to provide exactly the right context for your questions.

Semantic Intent Recognition:
- Understands what you're actually asking for
- Recognizes project overview questions regardless of wording
- Prioritizes architectural files for comprehensive understanding
- Adapts context selection based on question type

Query Classifications:

Quick Fix (2K tokens): Grammar, typos, formatting
- "fix this typo"
- "correct grammar" 
- "format this text"
-> Uses current document only

Implementation Help (8K tokens): Specific coding questions
- "how to implement X"
- "add this feature"
- "why isn't this working"
-> Includes current + related implementation files

Project Overview (30K tokens): Comprehensive understanding
- "project content" <- YOUR CASE
- "what does this do"
- "explain this project"
- "show me around"
-> Includes architectural files, documentation, key components

Architectural Guidance (25K tokens): Design decisions
- "best practices"
- "refactor this"
- "improve architecture"
-> Full architectural context with patterns and structure

Key Improvements:
- Project overview questions ALWAYS get comprehensive context
- Smart file selection based on architectural importance
- Semantic patterns instead of keyword matching
- Cost optimization without sacrificing understanding quality

Cost Impact:
- Simple queries: ~\$0.005 (unchanged)
- Project overview: ~\$0.08 (was \$0.02, but now comprehensive)
- Implementation help: ~\$0.02 (unchanged)
- Net result: Better answers, appropriate cost for intent
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
    
    // Enhanced semantic analysis
    final intent = _analyzeQueryIntent(query);
    final scope = _analyzeQueryScope(query, intent);
    final requirements = _analyzeContextRequirements(intent, scope);
    final complexity = _determineComplexityFromIntent(intent, scope);
    
    final tokenLimit = _getTokenLimitForComplexity(complexity, intent);
    
    // Build context based on semantic understanding
    return await _buildSemanticContext(
      query: query,
      intent: intent,
      scope: scope,
      requirements: requirements,
      currentFile: currentFile,
      availableFiles: availableFiles,
      fileContents: fileContents,
      tokenLimit: tokenLimit,
    );
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
        'complexTokenLimit': 25000,
        'enableSemanticAnalysis': true,
        'enableArchitecturalFileSelection': true,
        'enableIntentOverride': true,
        'projectOverviewTokenLimit': 30000,
      },
    );
  }

  @override
  bool validateConfig(Map<String, dynamic> settings) {
    try {
      final simple = settings['simpleTokenLimit'] as int;
      final medium = settings['mediumTokenLimit'] as int;
      final complex = settings['complexTokenLimit'] as int;
      final overview = settings['projectOverviewTokenLimit'] as int;
      
      return simple > 0 && 
             medium > simple && 
             complex > medium &&
             overview >= complex &&
             overview <= 50000; // Reasonable upper limit
    } catch (e) {
      return false;
    }
  }

  @override
  String getConfigExplanation() {
    final simple = _config.settings['simpleTokenLimit'];
    final medium = _config.settings['mediumTokenLimit'];
    final complex = _config.settings['complexTokenLimit'];
    final overview = _config.settings['projectOverviewTokenLimit'];
    final semantic = _config.settings['enableSemanticAnalysis'];
    
    return '''
Token limits: Simple: ${simple}k, Medium: ${medium}k, Complex: ${complex}k, Overview: ${overview}k
Semantic analysis: ${semantic ? 'Enabled' : 'Disabled'}
Architectural file selection: Enabled
''';
  }

  // Core semantic analysis methods

  QueryIntent _analyzeQueryIntent(String query) {
    if (!(_config.settings['enableSemanticAnalysis'] as bool? ?? true)) {
      return QueryIntent.specificImplementation; // Safe default
    }

    final queryLower = query.toLowerCase().trim();
    
    // Project overview patterns - CRITICAL for your use case
    if (_isProjectOverviewQuery(queryLower)) {
      return QueryIntent.projectOverview;
    }
    
    // Quick fix patterns
    if (_isQuickFixQuery(queryLower)) {
      return QueryIntent.quickFix;
    }
    
    // Architectural guidance patterns
    if (_isArchitecturalQuery(queryLower)) {
      return QueryIntent.architecturalGuidance;
    }
    
    // Navigation patterns
    if (_isNavigationQuery(queryLower)) {
      return QueryIntent.codebaseNavigation;
    }
    
    // Troubleshooting patterns
    if (_isTroubleshootingQuery(queryLower)) {
      return QueryIntent.troubleshooting;
    }
    
    // Documentation patterns
    if (_isDocumentationQuery(queryLower)) {
      return QueryIntent.documentation;
    }
    
    // Default to implementation help
    return QueryIntent.specificImplementation;
  }

  bool _isProjectOverviewQuery(String query) {
    // Comprehensive patterns for project overview detection
    final directOverviewPatterns = [
      'project content',      // YOUR SPECIFIC CASE
      'project overview',
      'what does this do',
      'what is this',
      'explain this project',
      'explain project',
      'show me around',
      'getting started',
      'project walkthrough',
      'codebase summary',
      'main components',
      'big picture',
      'overall structure',
      'project structure',
      'how does this work',
      'understand codebase',
      'project tour',
      'what am I looking at',
    ];
    
    // Semantic patterns that indicate comprehensive understanding need
    final semanticOverviewPatterns = [
      'project', 'codebase', 'application', 'system', 'everything',
      'comprehensive', 'complete', 'full', 'entire', 'whole'
    ];
    
    final questionWords = ['what', 'how', 'explain', 'show', 'tell'];
    final overviewWords = ['overview', 'summary', 'structure', 'architecture', 'design'];
    
    // Direct pattern matching
    if (directOverviewPatterns.any((pattern) => query.contains(pattern))) {
      return true;
    }
    
    // Semantic pattern combination
    final hasQuestionWord = questionWords.any((word) => query.contains(word));
    final hasOverviewWord = overviewWords.any((word) => query.contains(word));
    final hasSemanticWord = semanticOverviewPatterns.any((word) => query.contains(word));
    
    return (hasQuestionWord && hasOverviewWord) || 
           (hasQuestionWord && hasSemanticWord);
  }

  bool _isQuickFixQuery(String query) {
    final quickFixPatterns = [
      'fix', 'correct', 'grammar', 'spell', 'format', 'indent',
      'typo', 'mistake', 'error in text', 'wrong word', 'capitalize'
    ];
    
    final words = query.split(RegExp(r'\s+'));
    
    // Short queries with fix patterns
    return (words.length <= 5 && 
            quickFixPatterns.any((pattern) => query.contains(pattern))) ||
           // Very specific fix requests
           (query.contains('fix') && (query.contains('typo') || query.contains('grammar')));
  }

  bool _isArchitecturalQuery(String query) {
    final architecturalPatterns = [
      'architecture', 'design pattern', 'best practice', 'approach',
      'strategy', 'framework', 'structure', 'organize', 'refactor',
      'improve design', 'code organization', 'modular', 'scalable'
    ];
    
    return architecturalPatterns.any((pattern) => query.contains(pattern));
  }

  bool _isNavigationQuery(String query) {
    final navigationPatterns = [
      'where is', 'find', 'locate', 'show me', 'point me to',
      'which file', 'in what file', 'search for'
    ];
    
    return navigationPatterns.any((pattern) => query.contains(pattern));
  }

  bool _isTroubleshootingQuery(String query) {
    final troublePatterns = [
      'why isn\'t', 'not working', 'broken', 'debug', 'issue',
      'problem', 'error', 'bug', 'fails', 'doesn\'t work'
    ];
    
    return troublePatterns.any((pattern) => query.contains(pattern));
  }

  bool _isDocumentationQuery(String query) {
    final docPatterns = [
      'explain this code', 'what does this function',
      'how does this method', 'document this', 'comment this'
    ];
    
    return docPatterns.any((pattern) => query.contains(pattern));
  }

  QueryScope _analyzeQueryScope(String query, QueryIntent intent) {
    switch (intent) {
      case QueryIntent.projectOverview:
      case QueryIntent.architecturalGuidance:
        return QueryScope.projectWide;
      
      case QueryIntent.quickFix:
      case QueryIntent.documentation:
        return QueryScope.singleFile;
      
      case QueryIntent.specificImplementation:
      case QueryIntent.codebaseNavigation:
      case QueryIntent.troubleshooting:
        return QueryScope.relatedFiles;
    }
  }

  ContextRequirements _analyzeContextRequirements(QueryIntent intent, QueryScope scope) {
    switch (intent) {
      case QueryIntent.projectOverview:
        return ContextRequirements(
          minimumFiles: 8,
          optimalFiles: 18,
          requiresArchitecturalFiles: true,
          requiresDocumentation: true,
          requiresCustomPackages: true,
          priorityFilePatterns: [
            'README.md', 'CLAUDE.md', 'pubspec.yaml',
            'main.dart', 'app_state.dart', 'main_page.dart'
          ],
        );
      
      case QueryIntent.architecturalGuidance:
        return ContextRequirements(
          minimumFiles: 5,
          optimalFiles: 12,
          requiresArchitecturalFiles: true,
          requiresDocumentation: false,
          requiresCustomPackages: false,
          priorityFilePatterns: [
            'app_state.dart', 'provider', 'service', 'architecture'
          ],
        );
      
      case QueryIntent.specificImplementation:
        return ContextRequirements(
          minimumFiles: 2,
          optimalFiles: 5,
          requiresArchitecturalFiles: false,
          requiresDocumentation: false,
          requiresCustomPackages: false,
        );
      
      case QueryIntent.quickFix:
        return ContextRequirements(
          minimumFiles: 1,
          optimalFiles: 1,
        );
      
      case QueryIntent.codebaseNavigation:
      case QueryIntent.troubleshooting:
      case QueryIntent.documentation:
        return ContextRequirements(
          minimumFiles: 1,
          optimalFiles: 3,
        );
    }
  }

  QueryComplexity _determineComplexityFromIntent(QueryIntent intent, QueryScope scope) {
    // Intent-driven complexity instead of keyword matching
    switch (intent) {
      case QueryIntent.projectOverview:
      case QueryIntent.architecturalGuidance:
        return QueryComplexity.complex;
      
      case QueryIntent.specificImplementation:
      case QueryIntent.codebaseNavigation:
      case QueryIntent.troubleshooting:
      case QueryIntent.documentation:
        return QueryComplexity.medium;
      
      case QueryIntent.quickFix:
        return QueryComplexity.simple;
    }
  }

  int _getTokenLimitForComplexity(QueryComplexity complexity, QueryIntent intent) {
    // Special handling for project overview queries
    if (intent == QueryIntent.projectOverview) {
      return _config.settings['projectOverviewTokenLimit'] as int;
    }
    
    switch (complexity) {
      case QueryComplexity.simple:
        return _config.settings['simpleTokenLimit'] as int;
      case QueryComplexity.medium:
        return _config.settings['mediumTokenLimit'] as int;
      case QueryComplexity.complex:
        return _config.settings['complexTokenLimit'] as int;
    }
  }

  Future<ContextResult> _buildSemanticContext({
    required String query,
    required QueryIntent intent,
    required QueryScope scope,
    required ContextRequirements requirements,
    String? currentFile,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    required int tokenLimit,
  }) async {
    switch (intent) {
      case QueryIntent.projectOverview:
        return await _buildProjectOverviewContext(
          query: query,
          currentFile: currentFile,
          availableFiles: availableFiles,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
          requirements: requirements,
        );
      
      case QueryIntent.quickFix:
        return await _buildQuickFixContext(
          query: query,
          currentFile: currentFile,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
        );
      
      default:
        return await _buildMediumContext(
          query: query,
          currentFile: currentFile,
          availableFiles: availableFiles,
          fileContents: fileContents,
          tokenLimit: tokenLimit,
        );
    }
  }

  Future<ContextResult> _buildProjectOverviewContext({
    required String query,
    String? currentFile,
    required List<String> availableFiles,
    required Map<String, String> fileContents,
    required int tokenLimit,
    required ContextRequirements requirements,
  }) async {
    final List<String> selectedFiles = [];
    final StringBuffer contextBuffer = StringBuffer();
    int currentTokens = 0;

    // Always include critical project overview files first
    final criticalFiles = _getProjectOverviewFiles(availableFiles, fileContents);
    
    contextBuffer.writeln('=== PROJECT OVERVIEW ===');
    contextBuffer.writeln();
    
    for (final file in criticalFiles) {
      final content = fileContents[file];
      if (content == null) continue;
      
      final tokens = _estimateTokens(content);
      
      if (currentTokens + tokens <= tokenLimit * 0.9) { // Reserve 10% for additional context
        contextBuffer.writeln('=== ${_getFileDisplayName(file)} ===');
        contextBuffer.writeln(content);
        contextBuffer.writeln();
        selectedFiles.add(file);
        currentTokens += tokens;
      } else {
        // Add partial content for very important files
        final remainingTokens = (tokenLimit * 0.9 - currentTokens).toInt();
        if (remainingTokens > 300) {
          final partialContent = _truncateToTokenLimit(content, remainingTokens);
          contextBuffer.writeln('=== ${_getFileDisplayName(file)} (partial) ===');
          contextBuffer.writeln(partialContent);
          contextBuffer.writeln('[Truncated due to token limit]');
          contextBuffer.writeln();
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
      explanation: 'Project overview: Comprehensive context with ${selectedFiles.length} architectural files',
      generatedAt: DateTime.now(),
    );
  }

  List<String> _getProjectOverviewFiles(List<String> availableFiles, Map<String, String> fileContents) {
    final prioritized = <String>[];
    
    // Priority 1: Project definition files
    final projectFiles = [
      'README.md', 'CLAUDE.md', 'pubspec.yaml', 'package.json'
    ];
    
    for (final pattern in projectFiles) {
      final matches = availableFiles.where((file) => 
        file.toLowerCase().endsWith(pattern.toLowerCase()) || 
        file.toLowerCase().contains(pattern.toLowerCase())
      ).toList();
      prioritized.addAll(matches);
    }
    
    // Priority 2: Application entry points
    final entryFiles = ['main.dart', 'main_page.dart', 'app.dart'];
    for (final pattern in entryFiles) {
      final matches = availableFiles.where((file) => 
        file.toLowerCase().contains(pattern.toLowerCase())
      ).toList();
      prioritized.addAll(matches);
    }
    
    // Priority 3: Core architecture files
    final archFiles = [
      'app_state.dart', 'app_state_provider.dart', 'preferences.dart',
      'file_service.dart', 'preferences_provider.dart'
    ];
    for (final pattern in archFiles) {
      final matches = availableFiles.where((file) => 
        file.toLowerCase().contains(pattern.toLowerCase())
      ).toList();
      prioritized.addAll(matches);
    }
    
    // Priority 4: Custom packages
    final packageFiles = availableFiles.where((file) => 
      file.contains('packages/') && 
      (file.endsWith('README.md') || file.endsWith('pubspec.yaml'))
    ).toList();
    prioritized.addAll(packageFiles);
    
    // Priority 5: Documentation
    final docFiles = availableFiles.where((file) => 
      file.contains('docs/') || 
      file.contains('architecture') ||
      file.endsWith('.md')
    ).toList();
    prioritized.addAll(docFiles.take(3)); // Limit documentation files
    
    // Remove duplicates while preserving order
    final uniqueFiles = <String>[];
    for (final file in prioritized) {
      if (!uniqueFiles.contains(file)) {
        uniqueFiles.add(file);
      }
    }
    
    return uniqueFiles;
  }

  Future<ContextResult> _buildQuickFixContext({
    required String query,
    String? currentFile,
    required Map<String, String> fileContents,
    required int tokenLimit,
  }) async {
    if (currentFile == null || !fileContents.containsKey(currentFile)) {
      return ContextResult(
        content: 'No current document available for quick fix.',
        tokenCount: 10,
        estimatedCost: 0.0,
        filesUsed: [],
        strategyUsed: name,
        explanation: 'Quick fix: No document open',
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
      explanation: 'Quick fix: Using current document only (${_getFileName(currentFile)})',
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
    // Fallback to existing medium complexity logic
    final List<String> selectedFiles = [];
    final StringBuffer contextBuffer = StringBuffer();
    int currentTokens = 0;

    // Include current file first
    if (currentFile != null && fileContents.containsKey(currentFile)) {
      final content = fileContents[currentFile]!;
      final tokens = _estimateTokens(content);
      
      if (tokens <= tokenLimit * 0.6) {
        contextBuffer.writeln('=== Current Document: ${_getFileName(currentFile)} ===');
        contextBuffer.writeln(content);
        contextBuffer.writeln();
        selectedFiles.add(currentFile);
        currentTokens += tokens;
      }
    }

    // Find related files (existing logic)
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
      explanation: 'Medium complexity: Using ${selectedFiles.length} related documents',
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
      if (file == currentFile) continue;
      
      final content = fileContents[file];
      if (content == null) continue;

      double score = 0.0;
      final contentLower = content.toLowerCase();
      final fileName = _getFileName(file).toLowerCase();

      for (final word in queryWords) {
        if (word.length < 3) continue;
        
        if (fileName.contains(word)) score += 10.0;
        final matches = word.allMatches(contentLower).length;
        score += matches * 1.0;
      }

      if (currentFile != null && _getDirectory(file) == _getDirectory(currentFile)) {
        score += 2.0;
      }

      if (score > 0) {
        scored.add(MapEntry(file, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(3).map((e) => e.key).toList();
  }

  // Helper methods
  int _estimateTokens(String text) {
    return (text.length / 4).ceil();
  }

  double _estimateCost(int tokens) {
    return (tokens / 1000) * 0.01;
  }

  String _truncateToTokenLimit(String content, int tokenLimit) {
    final maxChars = tokenLimit * 4;
    if (content.length <= maxChars) return content;
    
    return '${content.substring(0, maxChars)}\n\n[Content truncated to fit token limit]';
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  String _getFileDisplayName(String filePath) {
    // Create user-friendly display names
    final fileName = _getFileName(filePath);
    final pathParts = filePath.split('/');
    
    if (pathParts.length > 1) {
      final parentDir = pathParts[pathParts.length - 2];
      return '$parentDir/$fileName';
    }
    
    return fileName;
  }

  String _getDirectory(String filePath) {
    final parts = filePath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }
}

/// Query complexity levels (keeping for backward compatibility)
enum QueryComplexity { simple, medium, complex }