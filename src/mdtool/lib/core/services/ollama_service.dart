import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OllamaResponse {
  final String content;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  OllamaResponse({
    required this.content,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
  });
}

class OllamaService {
  static OllamaService? _instance;
  OllamaService._();

  static OllamaService get instance {
    _instance ??= OllamaService._();
    return _instance!;
  }

  Future<String> chatCompletion({
    required String baseUrl,
    required String model,
    required List<dynamic> messages, // accepts ChatMessage or Map<String,String>
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    // helper to normalize messages into the shape Ollama expects
    List<Map<String, String>> _normalizeMessages(List<dynamic> msgs) {
      return msgs.map<Map<String, String>>((m) {
        if (m is Map) {
          final role = (m['role'] ?? '').toString();
          final content = (m['content'] ?? '').toString();
          return {'role': role, 'content': content};
        }
        // If you used a ChatMessage class
        try {
          final role = (m as dynamic).role?.toString() ?? 'user';
          final content = (m as dynamic).content?.toString() ?? '';
          return {'role': role, 'content': content};
        } catch (_) {
          return {'role': 'user', 'content': m.toString()};
        }
      }).toList();
    }

    final uri = Uri.parse('${_canonicalizeBaseUrl(baseUrl)}/api/chat');
    final body = {
      'model': model,
      'messages': _normalizeMessages(messages),
      'stream': false,
      'options': {'temperature': temperature, 'num_predict': maxTokens},
    };

    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // Prefer message.content, fallback to top-level content
        final msg = data['message'] as Map<String, dynamic>?;
        final content = (msg?['content'] ?? data['content']) as String?;
        if (content != null) return content;
        throw Exception('Empty response from /api/chat');
      }
      throw Exception('Failed with status ${resp.statusCode}: ${resp.body}');
    } on SocketException {
      throw Exception('Unable to connect to Ollama at ${_canonicalizeBaseUrl(baseUrl)}');
    } catch (e) {
      throw Exception('chatCompletion error: $e');
    }
  }

  // NEW: normalize base URL and avoid IPv6 localhost issues on macOS
  String _canonicalizeBaseUrl(String baseUrl) {
    var url = baseUrl.trim();
    if (url.isEmpty) url = 'http://127.0.0.1:11434';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // Prefer IPv4 to dodge ::1 vs 127.0.0.1 pitfalls
    url = url.replaceFirst('://localhost', '://127.0.0.1');
    // Strip trailing slashes
    url = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return url;
  }

  /// Generate text completion using Ollama API
  Future<String> generateCompletion({required String baseUrl, required String model, required String prompt, double temperature = 0.7, int maxTokens = 1000}) async {
    try {
      final uri = Uri.parse('${_canonicalizeBaseUrl(baseUrl)}/api/generate');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
              'options': {'temperature': temperature, 'num_predict': maxTokens},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String? ?? '';
      } else {
        throw Exception('Failed to generate completion: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Unable to connect to Ollama. Make sure it is running and reachable at ${_canonicalizeBaseUrl(baseUrl)}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception('Error generating completion: $e');
    }
  }

  /// Simple connectivity/version test
  Future<String> getServerVersion({required String baseUrl}) async {
    try {
      final uri = Uri.parse('${_canonicalizeBaseUrl(baseUrl)}/api/version');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['version'] as String? ?? 'Unknown';
      } else {
        throw Exception('Failed to get server version: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Unable to connect to Ollama at ${_canonicalizeBaseUrl(baseUrl)}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception('Error getting server version: $e');
    }
  }

  Future<List<String>> listModels({required String baseUrl}) async {
    final uri = Uri.parse('${_canonicalizeBaseUrl(baseUrl)}/api/tags');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw Exception('Failed to list models: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final models = (data['models'] as List<dynamic>? ?? []).map((m) => (m as Map)['name'] as String).toList();

    return models;
  }

  /// Check if Ollama is running at the given base URL (quick version for setup screen)
  Future<bool> isRunning({
    String baseUrl = 'http://127.0.0.1:11434',
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final uri = Uri.parse('${_canonicalizeBaseUrl(baseUrl)}/api/version');
      final response = await http.get(uri).timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Test connection and get detailed information
  Future<ConnectionTestResult> testConnection({
    String baseUrl = 'http://127.0.0.1:11434',
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final canonicalUrl = _canonicalizeBaseUrl(baseUrl);
      
      // Test version endpoint
      final versionUri = Uri.parse('$canonicalUrl/api/version');
      final versionResponse = await http.get(versionUri).timeout(timeout);
      
      if (versionResponse.statusCode != 200) {
        return ConnectionTestResult(
          isConnected: false,
          error: 'Failed to connect: HTTP ${versionResponse.statusCode}',
        );
      }

      final versionData = jsonDecode(versionResponse.body);
      final version = versionData['version'] as String?;

      // Get models list
      List<String> models = [];
      try {
        models = await listModels(baseUrl: canonicalUrl);
      } catch (e) {
        // Models list is optional, don't fail the connection test for this
      }
      
      return ConnectionTestResult(
        isConnected: true,
        version: version,
        modelCount: models.length,
        models: models,
        url: canonicalUrl,
      );
    } catch (e) {
      return ConnectionTestResult(
        isConnected: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Chat completion with estimated token usage
  Future<OllamaResponse> chatCompletionWithUsage({
    required String baseUrl,
    required String model,
    required List<dynamic> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    final content = await chatCompletion(
      baseUrl: baseUrl,
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    // Estimate token counts (rough approximation: ~4 chars per token)
    final inputContent = messages.map((m) {
      if (m is Map) return m['content']?.toString() ?? '';
      return m.toString();
    }).join(' ');
    
    final estimatedInputTokens = (inputContent.length / 4).round();
    final estimatedOutputTokens = (content.length / 4).round();

    return OllamaResponse(
      content: content,
      inputTokens: estimatedInputTokens,
      outputTokens: estimatedOutputTokens,
      totalTokens: estimatedInputTokens + estimatedOutputTokens,
    );
  }
}

class ConnectionTestResult {
  final bool isConnected;
  final String? version;
  final int modelCount;
  final List<String> models;
  final String? error;
  final String? url;

  ConnectionTestResult({
    required this.isConnected,
    this.version,
    this.modelCount = 0,
    this.models = const [],
    this.error,
    this.url,
  });
}
