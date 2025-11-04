import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OpenAIResponse {
  final String content;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  OpenAIResponse({
    required this.content,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
  });
}

class OpenAIService {
  static OpenAIService? _instance;
  
  OpenAIService._();
  
  static OpenAIService get instance {
    _instance ??= OpenAIService._();
    return _instance!;
  }

  /// Chat completion using OpenAI API
  Future<String> chatCompletion({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    String baseUrl = 'https://api.openai.com/v1',
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>? ?? [];
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>? ?? {};
          return message['content'] as String? ?? '';
        }
        throw Exception('No response content from OpenAI API');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key in preferences.');
      } else if (response.statusCode == 429) {
        final data = jsonDecode(response.body);
        final error = data['error'] as Map<String, dynamic>? ?? {};
        final errorType = error['type'] as String? ?? '';
        final message = error['message'] as String? ?? 'Rate limit exceeded';

        // Distinguish between rate limits and quota issues
        if (errorType == 'insufficient_quota') {
          throw Exception(
            'OpenAI account has insufficient quota. Please check your billing and add credits at:\n'
            'https://platform.openai.com/account/billing\n\n'
            'Details: $message'
          );
        } else {
          throw Exception('OpenAI rate limit exceeded: $message');
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final error = data['error'] as Map<String, dynamic>? ?? {};
        final message = error['message'] as String? ?? 'Bad request';
        throw Exception('OpenAI API error: $message');
      } else {
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Unable to connect to OpenAI API. Please check your internet connection.');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('OpenAI API error') || e.toString().contains('Invalid API key')) {
        rethrow;
      }
      throw Exception('Error calling OpenAI API: $e');
    }
  }

  /// Generate text completion using OpenAI API
  Future<String> generateCompletion({
    required String apiKey,
    required String model,
    required String prompt,
    String baseUrl = 'https://api.openai.com/v1',
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    // Convert to chat format for newer models
    final messages = [
      {'role': 'user', 'content': prompt},
    ];

    return await chatCompletion(
      apiKey: apiKey,
      model: model,
      messages: messages,
      baseUrl: baseUrl,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// List available models (simplified for common models)
  List<String> getAvailableModels() {
    return [
      'gpt-5-nano',
      'gpt-5-mini',
      'gpt-5',
      'gpt-5-chat-latest',
    ];
  }

  /// Check if API key is valid by making a simple request
  Future<bool> validateApiKey({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/models');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get model information
  Map<String, String> getModelInfo(String model) {
    const modelInfo = {
      'gpt-5-nano': 'Ultra-low latency model optimized for instant responses',
      'gpt-5-mini': 'Cost-efficient model built for speed and efficiency',
      'gpt-5': 'Full-capability reasoning model for logic and multi-step tasks',
      'gpt-5-chat-latest': 'Non-reasoning model used in ChatGPT interface',
    };

    return {
      'name': model,
      'description': modelInfo[model] ?? 'OpenAI language model',
    };
  }

  /// Get usage information from response
  Map<String, dynamic>? extractUsageInfo(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final usage = data['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        return {
          'prompt_tokens': usage['prompt_tokens'] ?? 0,
          'completion_tokens': usage['completion_tokens'] ?? 0,
          'total_tokens': usage['total_tokens'] ?? 0,
        };
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Chat completion with detailed response including token usage
  Future<OpenAIResponse> chatCompletionWithUsage({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    String baseUrl = 'https://api.openai.com/v1',
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      print('DEBUG [OpenAIService]: Making request to: $uri');
      print('DEBUG [OpenAIService]: Model: $model');
      print('DEBUG [OpenAIService]: Messages count: ${messages.length}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      print('DEBUG [OpenAIService]: Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>? ?? [];
        final usage = data['usage'] as Map<String, dynamic>? ?? {};

        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>? ?? {};
          final content = message['content'] as String? ?? '';

          return OpenAIResponse(
            content: content,
            inputTokens: usage['prompt_tokens'] ?? 0,
            outputTokens: usage['completion_tokens'] ?? 0,
            totalTokens: usage['total_tokens'] ?? 0,
          );
        }
        throw Exception('No response content from OpenAI API');
      } else if (response.statusCode == 401) {
        print('DEBUG [OpenAIService]: 401 Unauthorized - Invalid API key');
        throw Exception('Invalid API key. Please check your OpenAI API key in preferences.');
      } else if (response.statusCode == 429) {
        print('DEBUG [OpenAIService]: 429 response from OpenAI API');
        print('DEBUG [OpenAIService]: Response body: ${response.body}');
        final data = jsonDecode(response.body);
        final error = data['error'] as Map<String, dynamic>? ?? {};
        final errorType = error['type'] as String? ?? '';
        final message = error['message'] as String? ?? 'Rate limit exceeded';

        // Distinguish between rate limits and quota issues
        if (errorType == 'insufficient_quota') {
          throw Exception(
            'OpenAI account has insufficient quota. Please check your billing and add credits at:\n'
            'https://platform.openai.com/account/billing\n\n'
            'Details: $message'
          );
        } else {
          throw Exception('OpenAI rate limit exceeded: $message');
        }
      } else if (response.statusCode == 400) {
        print('DEBUG [OpenAIService]: 400 Bad request');
        print('DEBUG [OpenAIService]: Response body: ${response.body}');
        final data = jsonDecode(response.body);
        final error = data['error'] as Map<String, dynamic>? ?? {};
        final message = error['message'] as String? ?? 'Bad request';
        throw Exception('OpenAI API error: $message');
      } else {
        print('DEBUG [OpenAIService]: Unexpected status ${response.statusCode}');
        print('DEBUG [OpenAIService]: Response body: ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Unable to connect to OpenAI API. Please check your internet connection.');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('OpenAI API error') || e.toString().contains('Invalid API key')) {
        rethrow;
      }
      throw Exception('Error calling OpenAI API: $e');
    }
  }

  /// Check if the service is reachable
  Future<bool> isServiceReachable({String baseUrl = 'https://api.openai.com/v1'}) async {
    try {
      final uri = Uri.parse('$baseUrl/models');
      final response = await http.head(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 401; // 401 means the endpoint exists but needs auth
    } catch (e) {
      return false;
    }
  }
}