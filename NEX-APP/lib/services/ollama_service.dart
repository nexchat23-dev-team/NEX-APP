import 'dart:convert';
import 'dart:io';

class OllamaService {
  OllamaService({String? baseUrl, String? model})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'OLLAMA_BASE_URL',
              defaultValue: 'http://127.0.0.1:11434',
            ),
        _defaultModel = model ??
            const String.fromEnvironment(
              'OLLAMA_MODEL',
              defaultValue: 'minimax-m3:cloud',
            );

  final String _baseUrl;
  final String _defaultModel;

  Map<String, dynamic> buildRequestBody(String prompt, {String? model}) {
    return {
      'model': model ?? _defaultModel,
      'stream': false,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
  }

  String extractMessageContent(String body) {
    final decoded = jsonDecode(body);
    final content = decoded['message']?['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    throw Exception('Ollama response did not contain message content.');
  }

  Future<String> chat(String prompt, {String? model}) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    final payload = jsonEncode(buildRequestBody(prompt, model: model));
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(payload);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return extractMessageContent(body);
      }

      throw Exception('Ollama request failed (${response.statusCode}): $body');
    } on SocketException catch (e) {
      throw Exception(
        'Unable to connect to Ollama at $_baseUrl. Make sure Ollama is running. $e',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to reach Ollama: $e');
    } finally {
      client.close(force: true);
    }
  }
}
