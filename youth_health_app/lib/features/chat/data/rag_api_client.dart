import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Streaming client for the HealthGuide backend (`backend/` in this repo).
///
/// Configure at build time — no runtime settings screen, keeping the app
/// zero-config for users:
///
///     flutter run --dart-define=RAG_API_URL=https://api.example.org
///
/// When unset, [isConfigured] is false and the chat falls back to the
/// built-in simulated stream (see chat_provider.dart).
///
/// Wire protocol: `POST /v1/ask` returns Server-Sent Events, one JSON object
/// per `data:` line:
///   {"type": "token", "text": "..."}                       — append to bubble
///   {"type": "meta", "confidence_level": ..., "sources": [...],
///    "expert_verified": bool}                              — badges
///   {"type": "done"}                                       — end of answer
sealed class RagEvent {
  const RagEvent();
}

class RagToken extends RagEvent {
  const RagToken(this.text);
  final String text;
}

class RagMeta extends RagEvent {
  const RagMeta({required this.sources, required this.expertVerified});
  final List<String> sources;
  final bool expertVerified;
}

class RagDone extends RagEvent {
  const RagDone();
}

class RagApiClient {
  RagApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const _baseUrl = String.fromEnvironment('RAG_API_URL');

  static bool get isConfigured => _baseUrl.isNotEmpty;

  final http.Client _http;

  /// Sends [question] and yields answer events as they arrive.
  Stream<RagEvent> ask(String question) async* {
    final request = http.Request('POST', Uri.parse('$_baseUrl/v1/ask'))
      ..headers['Content-Type'] = 'application/json'
      // Privacy: the only payload is the question text. No IDs, no tokens.
      ..body = jsonEncode({'question': question});

    final response = await _http.send(request);
    if (response.statusCode != 200) {
      throw http.ClientException('Backend returned ${response.statusCode}');
    }

    // Parse the SSE byte stream line by line; events are `data: {json}`.
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload =
          jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
      switch (payload['type']) {
        case 'token':
          yield RagToken(payload['text'] as String? ?? '');
        case 'meta':
          yield RagMeta(
            sources: [
              for (final s in (payload['sources'] as List? ?? const []))
                s.toString(),
            ],
            expertVerified: payload['expert_verified'] == true,
          );
        case 'done':
          yield const RagDone();
          return;
      }
    }
  }

  void dispose() => _http.close();
}
