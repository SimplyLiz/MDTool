import 'dart:io';
import 'package:path/path.dart' as path;

class DocumentInfo {
  final String filePath;
  final String fileName;
  final String content;
  final DateTime lastModified;
  final List<String> tags;
  final String summary;

  DocumentInfo({
    required this.filePath,
    required this.fileName,
    required this.content,
    required this.lastModified,
    this.tags = const [],
    this.summary = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'content': content,
      'lastModified': lastModified.toIso8601String(),
      'tags': tags,
      'summary': summary,
    };
  }

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      filePath: json['filePath'],
      fileName: json['fileName'],
      content: json['content'],
      lastModified: DateTime.parse(json['lastModified']),
      tags: List<String>.from(json['tags'] ?? []),
      summary: json['summary'] ?? '',
    );
  }
}

class DocumentIndexService {
  static DocumentIndexService? _instance;
  final Map<String, DocumentInfo> _documentCache = {};
  final List<String> _watchedDirectories = [];

  DocumentIndexService._();

  static DocumentIndexService get instance {
    _instance ??= DocumentIndexService._();
    return _instance!;
  }

  /// Get all indexed documents
  List<DocumentInfo> get documents => _documentCache.values.toList();

  /// Get all indexed documents as a list of maps (for UI compatibility)
  Future<List<Map<String, dynamic>>> getIndexedDocuments() async {
    return _documentCache.values.map((doc) => {
      'path': doc.filePath,
      'fileName': doc.fileName,
      'lastModified': doc.lastModified,
      'tags': doc.tags,
      'summary': doc.summary,
    }).toList();
  }

  /// Get document by file path
  DocumentInfo? getDocument(String filePath) => _documentCache[filePath];

  /// Add a document to the index
  void addDocument(DocumentInfo document) {
    _documentCache[document.filePath] = document;
  }

  /// Remove a document from the index
  void removeDocument(String filePath) {
    _documentCache.remove(filePath);
  }

  /// Index a single file
  Future<DocumentInfo?> indexFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final stats = await file.stat();
      final fileName = path.basename(filePath);

      // Extract potential tags from content (lines starting with #tags or similar)
      final tags = _extractTags(content);
      
      // Create a summary (first 200 characters of meaningful content)
      final summary = _createSummary(content);

      final documentInfo = DocumentInfo(
        filePath: filePath,
        fileName: fileName,
        content: content,
        lastModified: stats.modified,
        tags: tags,
        summary: summary,
      );

      print('DEBUG: Successfully indexed document: $fileName (${content.length} chars, ${tags.length} tags)');
      print('DEBUG: Summary: ${summary.substring(0, (summary.length).clamp(0, 100))}...');
      addDocument(documentInfo);
      return documentInfo;
    } catch (e) {
      print('Error indexing file $filePath: $e');
      return null;
    }
  }

  /// Index all markdown files in a directory and subdirectories
  Future<List<DocumentInfo>> indexDirectory(String directoryPath) async {
    final indexed = <DocumentInfo>[];
    
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) return indexed;

      if (!_watchedDirectories.contains(directoryPath)) {
        _watchedDirectories.add(directoryPath);
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && _isMarkdownFile(entity.path)) {
          final documentInfo = await indexFile(entity.path);
          if (documentInfo != null) {
            indexed.add(documentInfo);
          }
        }
      }
    } catch (e) {
      print('Error indexing directory $directoryPath: $e');
    }

    return indexed;
  }

  /// Search documents with enhanced semantic matching
  List<DocumentInfo> searchDocuments(String query) {
    if (query.trim().isEmpty) return documents;

    final queryLower = query.toLowerCase();
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final results = <DocumentInfo>[];

    for (final doc in documents) {
      final score = _calculateEnhancedRelevanceScore(doc, query, queryWords, queryLower);
      
      if (score > 0) {
        results.add(doc);
      }
    }
    
    // If no documents matched and we have documents available, include all documents for general queries
    bool isGeneralQuery = false;
    if (results.isEmpty && documents.isNotEmpty) {
      final generalQueryWords = ['organize', 'help', 'structure', 'manage', 'documents', 'files'];
      isGeneralQuery = queryWords.any((word) => generalQueryWords.contains(word));
      
      if (isGeneralQuery || queryWords.length <= 3) {
        print('DEBUG: General query detected, including all documents');
        results.addAll(documents);
      }
    }

    // Sort results
    if (isGeneralQuery && results.isNotEmpty) {
      // Sort by modification date (most recent first) for general queries
      results.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } else {
      // Sort by enhanced relevance score for specific queries
      results.sort((a, b) {
        final scoreA = _calculateEnhancedRelevanceScore(a, query, queryWords, queryLower);
        final scoreB = _calculateEnhancedRelevanceScore(b, query, queryWords, queryLower);
        return scoreB.compareTo(scoreA);
      });
    }

    return results;
  }
  
  /// Calculate enhanced relevance score considering semantic factors
  int _calculateEnhancedRelevanceScore(DocumentInfo doc, String originalQuery, List<String> queryWords, String queryLower) {
    int score = 0;
    final contentLower = doc.content.toLowerCase();
    final filenameLower = doc.fileName.toLowerCase();
    final summaryLower = doc.summary.toLowerCase();
    
    // 1. Exact phrase match (highest priority)
    if (contentLower.contains(queryLower)) {
      score += 100;
      // Bonus for multiple occurrences
      final occurrences = queryLower.allMatches(contentLower).length;
      score += (occurrences - 1) * 25;
    }
    
    // 2. Filename matches (very high priority)
    if (filenameLower.contains(queryLower)) {
      score += 150;
    }
    
    // 3. Individual word matches with context weighting
    for (final word in queryWords) {
      if (word.length < 3) continue; // Skip very short words
      
      // Title/filename word matches
      if (filenameLower.contains(word)) {
        score += 75;
      }
      
      // Header matches (check for words in markdown headers)
      final headers = _extractHeaders(doc.content);
      for (final header in headers) {
        if (header['text']!.toLowerCase().contains(word)) {
          final headerLevel = header['level']!.length;
          score += (7 - headerLevel) * 15; // Higher level headers get more weight
        }
      }
      
      // Summary matches
      if (summaryLower.contains(word)) {
        score += 30;
      }
      
      // Tag matches
      for (final tag in doc.tags) {
        if (tag.toLowerCase().contains(word)) {
          score += 40;
        }
      }
      
      // Content word matches with proximity bonus
      final wordMatches = word.allMatches(contentLower).length;
      score += wordMatches * 5;
      
      // Bonus for words appearing close to each other
      if (queryWords.length > 1) {
        score += _calculateProximityBonus(contentLower, queryWords) * 2;
      }
    }
    
    // 4. Semantic similarity bonuses
    score += _calculateSemanticBonus(doc, originalQuery);
    
    // 5. Document quality factors
    score += _calculateDocumentQualityScore(doc);
    
    // 6. Recency bonus (newer documents get slight preference)
    final daysSinceModified = DateTime.now().difference(doc.lastModified).inDays;
    if (daysSinceModified < 7) {
      score += 10 - daysSinceModified; // Recent documents get up to 10 bonus points
    }
    
    return score;
  }
  
  /// Calculate proximity bonus for words appearing near each other
  int _calculateProximityBonus(String content, List<String> queryWords) {
    int bonus = 0;
    final words = content.split(RegExp(r'\s+'));
    
    for (int i = 0; i < words.length - 1; i++) {
      final currentWord = words[i].toLowerCase();
      
      for (int j = 0; j < queryWords.length; j++) {
        if (currentWord.contains(queryWords[j])) {
          // Look for other query words nearby
          for (int k = i + 1; k < (i + 10).clamp(0, words.length); k++) {
            final nearbyWord = words[k].toLowerCase();
            for (int l = 0; l < queryWords.length; l++) {
              if (l != j && nearbyWord.contains(queryWords[l])) {
                final distance = k - i;
                bonus += (10 - distance) * 3; // Closer words get higher bonus
              }
            }
          }
        }
      }
    }
    
    return bonus;
  }
  
  /// Calculate semantic similarity bonus based on content analysis
  int _calculateSemanticBonus(DocumentInfo doc, String query) {
    int bonus = 0;
    
    // Extract key phrases from the document
    final docKeyPhrases = _extractKeyPhrases(doc.content);
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    
    // Check for related terms (simple approach - could be enhanced with NLP)
    for (final phrase in docKeyPhrases) {
      for (final queryWord in queryWords) {
        // Simple similarity: check if they share common substrings
        if (phrase.length > 4 && queryWord.length > 4) {
          final phraseLower = phrase.toLowerCase();
          if (phraseLower.contains(queryWord) || queryWord.contains(phraseLower)) {
            bonus += 15;
          }
          
          // Check for partial matches (common prefixes/suffixes)
          if (_hasCommonSubstring(phraseLower, queryWord, minLength: 4)) {
            bonus += 8;
          }
        }
      }
    }
    
    // Check for conceptual similarity through common markdown patterns
    if (query.toLowerCase().contains('code') && doc.content.contains('```')) {
      bonus += 20;
    }
    if (query.toLowerCase().contains('list') && RegExp(r'^\s*[-*+]\s', multiLine: true).hasMatch(doc.content)) {
      bonus += 20;
    }
    if (query.toLowerCase().contains('table') && doc.content.contains('|')) {
      bonus += 20;
    }
    if (query.toLowerCase().contains('link') && doc.content.contains('](')) {
      bonus += 15;
    }
    
    return bonus;
  }
  
  /// Calculate document quality score based on structure and content
  int _calculateDocumentQualityScore(DocumentInfo doc) {
    int score = 0;
    
    // Well-structured documents with headers get bonus points
    final headers = _extractHeaders(doc.content);
    if (headers.isNotEmpty) {
      score += (headers.length * 2).clamp(0, 20); // Up to 20 bonus points for structure
    }
    
    // Documents with tags are often better organized
    if (doc.tags.isNotEmpty) {
      score += doc.tags.length * 3;
    }
    
    // Longer, more detailed documents might be more valuable
    final wordCount = doc.content.split(RegExp(r'\s+')).length;
    if (wordCount > 500) {
      score += 10;
    } else if (wordCount > 100) {
      score += 5;
    }
    
    // Documents with good summaries are typically higher quality
    if (doc.summary.isNotEmpty && doc.summary.length > 50) {
      score += 8;
    }
    
    return score;
  }
  
  /// Check if two strings have a common substring of minimum length
  bool _hasCommonSubstring(String str1, String str2, {int minLength = 3}) {
    for (int i = 0; i <= str1.length - minLength; i++) {
      final substring = str1.substring(i, i + minLength);
      if (str2.contains(substring)) {
        return true;
      }
    }
    return false;
  }

  /// Find the most relevant documents for a query
  List<DocumentInfo> findRelevantDocuments(String query, {int limit = 5}) {
    final results = searchDocuments(query);
    return results.take(limit).toList();
  }

  /// Get context string from relevant documents with enhanced information
  String getContextForQuery(String query, {int maxDocuments = 3, int maxCharsPerDoc = 1500}) {
    print('DEBUG: getContextForQuery called with query: "$query"');
    print('DEBUG: Total documents available: ${documents.length}');
    
    final relevantDocs = findRelevantDocuments(query, limit: maxDocuments);
    print('DEBUG: Found ${relevantDocs.length} relevant documents');
    
    for (final doc in relevantDocs) {
      final score = _calculateEnhancedRelevanceScore(doc, query, query.toLowerCase().split(RegExp(r'\s+')), query.toLowerCase());
      print('DEBUG: Document ${doc.fileName} has relevance score: $score');
    }
    
    if (relevantDocs.isEmpty) {
      print('DEBUG: No relevant documents found, returning empty context message');
      return 'No relevant documents found in your markdown files.';
    }

    final context = StringBuffer();
    context.writeln('=== DOCUMENT CONTEXT ===');
    context.writeln('Found ${relevantDocs.length} relevant document(s) for your query: "$query"');
    context.writeln();

    for (int i = 0; i < relevantDocs.length; i++) {
      final doc = relevantDocs[i];
      final relevanceScore = _calculateRelevanceScore(doc, query.toLowerCase());
      
      context.writeln('📄 DOCUMENT ${i + 1}: ${doc.fileName}');
      context.writeln('📍 Location: ${doc.filePath}');
      context.writeln('🕐 Modified: ${_formatDate(doc.lastModified)}');
      context.writeln('📊 Relevance Score: $relevanceScore');
      
      if (doc.tags.isNotEmpty) {
        context.writeln('🏷️ Tags: ${doc.tags.join(', ')}');
      }
      
      if (doc.summary.isNotEmpty) {
        context.writeln('📝 Summary: ${doc.summary}');
      }
      
      // Extract document structure (headers)
      final headers = _extractHeaders(doc.content);
      if (headers.isNotEmpty) {
        context.writeln('📋 Document Structure:');
        for (final header in headers.take(5)) { // Limit to top 5 headers
          context.writeln('  ${header['level']} ${header['text']}');
        }
      }
      
      // Find query-relevant excerpts instead of just truncating
      final relevantExcerpts = _findRelevantExcerpts(doc.content, query, maxLength: maxCharsPerDoc);
      
      context.writeln('📖 Relevant Content:');
      for (final excerpt in relevantExcerpts) {
        context.writeln(excerpt);
        context.writeln('...');
      }
      
      context.writeln('═' * 50);
    }

    // Add overall context summary
    context.writeln();
    context.writeln('📊 CONTEXT SUMMARY:');
    context.writeln('• Total documents indexed: ${documents.length}');
    context.writeln('• Documents matching query: ${relevantDocs.length}');
    context.writeln('• Common themes: ${_getCommonThemes(relevantDocs)}');

    return context.toString();
  }

  /// Refresh the index for all watched directories
  Future<void> refreshIndex() async {
    final currentPaths = Set<String>.from(_documentCache.keys);
    
    // Re-index all watched directories
    for (final dir in _watchedDirectories) {
      await indexDirectory(dir);
    }

    // Remove documents that no longer exist
    for (final filePath in currentPaths) {
      if (!File(filePath).existsSync()) {
        removeDocument(filePath);
      }
    }
  }

  /// Clear all indexed documents
  void clearIndex() {
    _documentCache.clear();
    _watchedDirectories.clear();
  }

  /// Check if a file is a markdown file
  bool _isMarkdownFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.md', '.markdown', '.mdown', '.mkd', '.mkdn'].contains(extension);
  }

  /// Extract tags from markdown content
  List<String> _extractTags(String content) {
    final tags = <String>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      
      // Look for lines starting with tags:, #tags, etc.
      if (trimmed.toLowerCase().startsWith('tags:') ||
          trimmed.toLowerCase().startsWith('#tags')) {
        final tagLine = trimmed.replaceFirst(RegExp(r'^#?tags:\s*', caseSensitive: false), '');
        final lineTags = tagLine.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
        tags.addAll(lineTags);
      }
      
      // Look for hashtags in content
      final hashtagRegex = RegExp(r'#(\w+)');
      final matches = hashtagRegex.allMatches(trimmed);
      for (final match in matches) {
        final tag = match.group(1);
        if (tag != null && !tags.contains(tag)) {
          tags.add(tag);
        }
      }
    }

    return tags;
  }

  /// Create an enhanced summary from markdown content with key topics and structure
  String _createSummary(String content) {
    final summaryParts = <String>[];
    
    // Extract main headers for document structure
    final headers = _extractHeaders(content);
    final mainHeaders = headers.where((h) => h['level']!.length <= 2).take(3);
    if (mainHeaders.isNotEmpty) {
      final headerText = mainHeaders.map((h) => h['text']).join(', ');
      summaryParts.add('Topics: $headerText');
    }
    
    // Extract key phrases and topics
    final keyPhrases = _extractKeyPhrases(content);
    if (keyPhrases.isNotEmpty) {
      summaryParts.add('Key concepts: ${keyPhrases.take(5).join(', ')}');
    }
    
    // Get the first meaningful paragraph as context
    String cleaned = content
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // Remove headers
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Remove bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Remove italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Remove code
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1') // Remove links
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '') // Remove list markers
        .trim();

    final lines = cleaned.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      final firstParagraph = lines.take(2).join(' ').trim();
      if (firstParagraph.length > 50) {
        final truncated = firstParagraph.length > 150 ? '${firstParagraph.substring(0, 150)}...' : firstParagraph;
        summaryParts.add('Content: $truncated');
      }
    }
    
    // Document stats
    final wordCount = content.split(RegExp(r'\s+')).length;
    final lineCount = content.split('\n').length;
    summaryParts.add('Stats: $wordCount words, $lineCount lines');

    return summaryParts.join(' | ');
  }
  
  /// Extract key phrases from content using simple heuristics
  List<String> _extractKeyPhrases(String content) {
    final phrases = <String>[];
    
    // Extract words that are capitalized (potential proper nouns/important terms)
    final capitalizedWords = RegExp(r'\b[A-Z][a-zA-Z]+\b').allMatches(content)
        .map((match) => match.group(0)!)
        .where((word) => word.length > 3 && !_isCommonWord(word))
        .toSet()
        .toList();
    
    phrases.addAll(capitalizedWords.take(10));
    
    // Extract quoted strings (often important concepts)
    final quotedText = RegExp(r'"([^"]+)"').allMatches(content)
        .map((match) => match.group(1)!)
        .where((quote) => quote.length > 3 && quote.length < 50)
        .toList();
    
    phrases.addAll(quotedText.take(3));
    
    // Extract words that appear frequently (but not too common)
    final words = content.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 4 && !_isCommonWord(word))
        .toList();
    
    final wordCounts = <String, int>{};
    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }
    
    final frequentWords = wordCounts.entries
        .where((entry) => entry.value > 2)
        .map((entry) => entry.key)
        .take(5)
        .toList();
    
    phrases.addAll(frequentWords);
    
    return phrases.toSet().toList(); // Remove duplicates
  }
  
  /// Check if a word is common and should be filtered out
  bool _isCommonWord(String word) {
    final commonWords = {
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 
      'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his', 
      'how', 'man', 'new', 'now', 'old', 'see', 'two', 'who', 'boy', 'did',
      'its', 'let', 'put', 'say', 'she', 'too', 'use', 'this', 'that', 'with',
      'have', 'from', 'they', 'know', 'want', 'been', 'good', 'much', 'some',
      'time', 'very', 'when', 'come', 'here', 'just', 'like', 'long', 'make',
      'many', 'over', 'such', 'take', 'than', 'them', 'well', 'were', 'what'
    };
    return commonWords.contains(word.toLowerCase());
  }

  /// Calculate relevance score for search
  int _calculateRelevanceScore(DocumentInfo doc, String queryLower) {
    int score = 0;
    
    // Filename match (highest priority)
    if (doc.fileName.toLowerCase().contains(queryLower)) {
      score += 50;
    }
    
    // Tag matches
    for (final tag in doc.tags) {
      if (tag.toLowerCase().contains(queryLower)) {
        score += 20;
      }
    }
    
    // Summary matches
    if (doc.summary.toLowerCase().contains(queryLower)) {
      score += 10;
    }
    
    // Content matches (count occurrences)
    final contentLower = doc.content.toLowerCase();
    final occurrences = queryLower.split(' ').fold(0, (count, word) {
      return count + word.allMatches(contentLower).length;
    });
    score += occurrences * 2;
    
    return score;
  }
  
  /// Extract headers from markdown content
  List<Map<String, String>> _extractHeaders(String content) {
    final headers = <Map<String, String>>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.+)').firstMatch(trimmed);
        if (match != null) {
          final level = match.group(1)!;
          final text = match.group(2)!;
          headers.add({
            'level': level,
            'text': text,
          });
        }
      }
    }
    
    return headers;
  }
  
  /// Find relevant excerpts from document content based on query
  List<String> _findRelevantExcerpts(String content, String query, {int maxLength = 1500}) {
    final excerpts = <String>[];
    final queryWords = query.toLowerCase().split(' ');
    final lines = content.split('\n');
    
    // Find paragraphs or sections containing query terms
    final relevantSections = <String>[];
    String currentSection = '';
    
    for (final line in lines) {
      currentSection += line + '\n';
      
      // Check if we've hit a new section (header or blank line followed by content)
      if (line.trim().isEmpty || line.trim().startsWith('#')) {
        if (currentSection.trim().isNotEmpty) {
          final sectionLower = currentSection.toLowerCase();
          if (queryWords.any((word) => sectionLower.contains(word))) {
            relevantSections.add(currentSection.trim());
          }
        }
        currentSection = line.trim().startsWith('#') ? line + '\n' : '';
      }
    }
    
    // Add the last section if relevant
    if (currentSection.trim().isNotEmpty) {
      final sectionLower = currentSection.toLowerCase();
      if (queryWords.any((word) => sectionLower.contains(word))) {
        relevantSections.add(currentSection.trim());
      }
    }
    
    // If no specific sections found, take excerpts around query matches
    if (relevantSections.isEmpty) {
      for (final word in queryWords) {
        final index = content.toLowerCase().indexOf(word);
        if (index >= 0) {
          final start = (index - 100).clamp(0, content.length);
          final end = (index + 300).clamp(0, content.length);
          excerpts.add(content.substring(start, end));
        }
      }
    } else {
      // Use relevant sections, but truncate if too long
      int totalLength = 0;
      for (final section in relevantSections) {
        if (totalLength + section.length <= maxLength) {
          excerpts.add(section);
          totalLength += section.length;
        } else {
          final remaining = maxLength - totalLength;
          if (remaining > 100) {
            excerpts.add(section.substring(0, remaining));
          }
          break;
        }
      }
    }
    
    return excerpts.isEmpty ? [content.length > 300 ? content.substring(0, 300) : content] : excerpts;
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Get common themes from a list of documents
  String _getCommonThemes(List<DocumentInfo> docs) {
    final allTags = docs.expand((doc) => doc.tags).toList();
    final tagCounts = <String, int>{};
    
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    
    final commonTags = tagCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(5)
        .toList();
    
    if (commonTags.isEmpty) {
      return 'No common themes identified';
    }
    
    return commonTags.join(', ');
  }
}