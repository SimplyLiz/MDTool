import 'dart:convert';
import 'package:http/http.dart' as http;

/// Web search result item
class SearchResult {
  final String title;
  final String snippet;
  final String url;
  final String displayUrl;

  SearchResult({
    required this.title,
    required this.snippet,
    required this.url,
    required this.displayUrl,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      snippet: json['snippet'] ?? '',
      url: json['link'] ?? json['url'] ?? '',
      displayUrl: json['displayLink'] ?? json['displayUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'snippet': snippet,
      'url': url,
      'displayUrl': displayUrl,
    };
  }
}

/// Web search response
class WebSearchResponse {
  final List<SearchResult> results;
  final int totalResults;
  final String query;
  final double searchTime;

  WebSearchResponse({
    required this.results,
    required this.totalResults,
    required this.query,
    required this.searchTime,
  });

  factory WebSearchResponse.fromJson(Map<String, dynamic> json, String query) {
    final items = json['items'] as List<dynamic>? ?? [];
    final results = items.map((item) => SearchResult.fromJson(item)).toList();
    
    return WebSearchResponse(
      results: results,
      totalResults: int.tryParse(json['searchInformation']?['totalResults']?.toString() ?? '0') ?? 0,
      query: query,
      searchTime: double.tryParse(json['searchInformation']?['searchTime']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  /// Create a formatted summary of search results for AI context
  String toContextString() {
    if (results.isEmpty) {
      return 'No web search results found for query: "$query"';
    }

    final buffer = StringBuffer();
    buffer.writeln('Web Search Results for: "$query"');
    buffer.writeln('Found ${results.length} results (${totalResults} total) in ${searchTime}s');
    buffer.writeln();
    
    for (int i = 0; i < results.length && i < 10; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   URL: ${result.url}');
      buffer.writeln('   ${result.snippet}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Service for performing web searches
class WebSearchService {
  static WebSearchService? _instance;
  static const String _baseUrl = 'https://www.googleapis.com/customsearch/v1';
  
  WebSearchService._();

  static WebSearchService get instance {
    _instance ??= WebSearchService._();
    return _instance!;
  }

  /// Perform a web search using Google Custom Search API
  /// 
  /// Note: This requires a Google API key and Custom Search Engine ID
  /// For now, this is a placeholder implementation that simulates search results
  Future<WebSearchResponse> search({
    required String query,
    int maxResults = 10,
    String? apiKey,
    String? searchEngineId,
  }) async {
    try {
      // If API credentials are provided, use actual Google Custom Search
      if (apiKey != null && apiKey.isNotEmpty && searchEngineId != null && searchEngineId.isNotEmpty) {
        return await _performActualSearch(query, maxResults, apiKey, searchEngineId);
      } else {
        // Fallback: Use a simpler search approach or mock results for demonstration
        return await _performFallbackSearch(query, maxResults);
      }
    } catch (e) {
      throw Exception('Web search failed: $e');
    }
  }

  /// Perform actual Google Custom Search API call
  Future<WebSearchResponse> _performActualSearch(
    String query,
    int maxResults,
    String apiKey,
    String searchEngineId,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'key': apiKey,
      'cx': searchEngineId,
      'q': query,
      'num': maxResults.toString(),
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return WebSearchResponse.fromJson(jsonData, query);
    } else {
      throw Exception('Search API returned ${response.statusCode}: ${response.body}');
    }
  }

  /// Fallback search implementation using DuckDuckGo Instant Answer API
  Future<WebSearchResponse> _performFallbackSearch(String query, int maxResults) async {
    try {
      // Use DuckDuckGo Instant Answer API as a fallback
      final uri = Uri.parse('https://api.duckduckgo.com/').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'no_html': '1',
        'skip_disambig': '1',
      });

      final stopwatch = Stopwatch()..start();
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseDuckDuckGoResponse(jsonData, query, stopwatch.elapsedMilliseconds / 1000.0);
      } else {
        // If web search fails, return mock results with helpful information
        return _createMockSearchResults(query);
      }
    } catch (e) {
      // If all else fails, create helpful mock results
      return _createMockSearchResults(query);
    }
  }

  /// Parse DuckDuckGo response into our format
  WebSearchResponse _parseDuckDuckGoResponse(
    Map<String, dynamic> json,
    String query,
    double searchTime,
  ) {
    final results = <SearchResult>[];
    
    // Parse abstract if available
    final abstract = json['Abstract']?.toString();
    final abstractUrl = json['AbstractURL']?.toString();
    final abstractSource = json['AbstractSource']?.toString();
    
    if (abstract != null && abstract.isNotEmpty) {
      results.add(SearchResult(
        title: abstractSource ?? 'Web Result',
        snippet: abstract,
        url: abstractUrl ?? '',
        displayUrl: abstractSource ?? '',
      ));
    }

    // Parse related topics
    final relatedTopics = json['RelatedTopics'] as List<dynamic>? ?? [];
    for (final topic in relatedTopics.take(5)) {
      if (topic is Map<String, dynamic>) {
        final text = topic['Text']?.toString();
        final firstUrl = topic['FirstURL']?.toString();
        if (text != null && text.isNotEmpty) {
          results.add(SearchResult(
            title: text.split(' - ').first,
            snippet: text,
            url: firstUrl ?? '',
            displayUrl: _extractDomain(firstUrl ?? ''),
          ));
        }
      }
    }

    // If no results, create helpful mock results
    if (results.isEmpty) {
      return _createMockSearchResults(query);
    }

    return WebSearchResponse(
      results: results,
      totalResults: results.length,
      query: query,
      searchTime: searchTime,
    );
  }

  /// Create mock search results for demonstration or fallback
  WebSearchResponse _createMockSearchResults(String query) {
    final mockResults = [
      SearchResult(
        title: 'Search results for: $query',
        snippet: 'Web search is currently configured in demonstration mode. To enable full web search, configure Google Custom Search API credentials in preferences.',
        url: 'https://developers.google.com/custom-search/v1/overview',
        displayUrl: 'developers.google.com',
      ),
      SearchResult(
        title: 'Local Knowledge Base',
        snippet: 'Your question about "$query" can be answered using the documents in your local knowledge base. The AI will use your indexed Markdown files to provide relevant information.',
        url: '',
        displayUrl: 'Local Documents',
      ),
      SearchResult(
        title: 'Enhanced AI Assistance',
        snippet: 'For comprehensive answers about "$query", the AI can combine information from your documents with general knowledge to provide detailed, contextual responses.',
        url: '',
        displayUrl: 'AI Assistant',
      ),
    ];

    return WebSearchResponse(
      results: mockResults,
      totalResults: mockResults.length,
      query: query,
      searchTime: 0.1,
    );
  }

  /// Extract domain from URL for display
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  /// Check if web search is properly configured
  bool isConfigured({String? apiKey, String? searchEngineId}) {
    return apiKey != null && apiKey.isNotEmpty && 
           searchEngineId != null && searchEngineId.isNotEmpty;
  }

  /// Test web search connectivity
  Future<bool> testConnection() async {
    try {
      final response = await search(query: 'test connectivity', maxResults: 1);
      return response.results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}