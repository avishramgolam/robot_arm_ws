import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rag_api_client.dart';
import '../models/chat_message.dart';

/// Quick-tag chips shown above the input bar. Tapping one pre-fills the
/// composer so users who don't know how to phrase things can start anyway.
const quickTags = <(String label, String prompt)>[
  ('Is this normal?', 'Is it normal that '),
  ('Consent 101', 'Can you explain what consent means and how it works?'),
  ('Puberty & Bodies', 'What changes happen during puberty?'),
  ('Contraception', 'What contraception options exist and how do they work?'),
  ('Periods', 'Can you explain how the menstrual cycle works?'),
  ('STIs', 'How do STIs spread and how can I protect myself?'),
  ('Relationships', 'How do I know if a relationship is healthy?'),
];

/// Holds the ordered chat feed and drives the streaming lifecycle.
///
/// State shape: an immutable `List<ChatMessage>`; every mutation emits a new
/// list so `ref.watch` consumers rebuild exactly once per change.
class ChatNotifier extends Notifier<List<ChatMessage>> {
  Timer? _streamTimer;
  RagApiClient? _api;
  int _idSeq = 0;

  @override
  List<ChatMessage> build() {
    ref.onDispose(() {
      _streamTimer?.cancel();
      _api?.dispose();
    });
    // Warm, non-judgmental opener. History is memory-only — closing the app
    // (or panic-exiting and killing it) leaves no trace.
    return [
      ChatMessage(
        id: _nextId(),
        role: MessageRole.assistant,
        text:
            "Hi — I'm here to answer your questions about health, bodies, and "
            'relationships. **No question is weird or embarrassing.** '
            'Everything here is anonymous — no account, no name, and nothing '
            'that can identify you is ever stored.\n\n'
            'What would you like to know?',
      ),
    ];
  }

  /// True while the assistant is thinking or streaming — used to disable the
  /// send button so requests can't overlap.
  bool get isBusy => state.any((m) => m.isStreaming);

  String _nextId() => 'msg_${_idSeq++}';

  /// Sends a user message and kicks off the assistant response.
  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isBusy) return;

    // 1. Append the user's bubble immediately.
    state = [
      ...state,
      ChatMessage(id: _nextId(), role: MessageRole.user, text: trimmed),
    ];

    // 2. Append an empty streaming assistant bubble; the ChatScreen renders
    //    the animated typing indicator while its text is still empty.
    final assistantId = _nextId();
    state = [
      ...state,
      ChatMessage(
        id: assistantId,
        role: MessageRole.assistant,
        text: '',
        isStreaming: true,
      ),
    ];

    _streamAnswer(assistantId, trimmed);
  }

  // --------------------------------------------------------------------------
  // BACKEND INTEGRATION
  //
  // When the app is built with --dart-define=RAG_API_URL=<backend url>, the
  // real HealthGuide backend streams the answer (see data/rag_api_client.dart
  // and backend/ in the repo root). Without it, the word-by-word Timer below
  // simulates the stream so the full UI stays testable offline.
  // --------------------------------------------------------------------------
  void _streamAnswer(String assistantId, String question) {
    if (RagApiClient.isConfigured) {
      unawaited(_streamFromBackend(assistantId, question));
      return;
    }
    _simulateStream(assistantId, question);
  }

  /// Real backend path: forwards SSE events into message patches.
  Future<void> _streamFromBackend(String assistantId, String question) async {
    _api ??= RagApiClient();
    try {
      await for (final event in _api!.ask(question)) {
        switch (event) {
          case RagToken(:final text):
            _patch(assistantId, (m) => m.copyWith(text: m.text + text));
          case RagMeta(:final sources, :final expertVerified):
            _patch(
              assistantId,
              (m) => m.copyWith(
                sources: [
                  if (expertVerified)
                    const SourceBadge(label: 'Reviewed by a health professional'),
                  for (final label in sources)
                    SourceBadge(label: 'Verified: $label'),
                ],
              ),
            );
          case RagDone():
            _patch(assistantId, (m) => m.copyWith(isStreaming: false));
        }
      }
    } catch (_) {
      // Network failure: keep the tone calm, never surface raw errors.
      _patch(
        assistantId,
        (m) => m.copyWith(
          isStreaming: false,
          text: m.text.isNotEmpty
              ? m.text
              : "I couldn't connect just now — please try again in a moment. "
                  'The Guides and Support tabs work fully offline.',
        ),
      );
    }
    // Safety net: ensure the streaming flag is always cleared.
    _patch(assistantId, (m) => m.copyWith(isStreaming: false));
  }

  /// Offline/demo path: simulated word-by-word stream.
  void _simulateStream(String assistantId, String question) {
    const demoAnswer =
        "That's a really good question — and a very common one.\n\n"
        'Here are the key things to know:\n\n'
        '- **Everyone develops at their own pace.** A wide range of '
        'experiences is completely healthy.\n'
        '- **Reliable information matters.** The guidance here is based on '
        'international health organisations, not opinions.\n'
        '- **If something hurts, worries you, or feels wrong**, talking to a '
        'healthcare provider is always a safe option — check the *Support* '
        'tab for free, confidential hotlines.\n\n'
        'Want me to go deeper on any part of this?';

    const sources = [
      SourceBadge(label: 'Verified: WHO Guidelines'),
      SourceBadge(label: 'Verified: UNESCO CSE 2018'),
    ];

    final words = demoAnswer.split(' ');
    var i = 0;

    // ~500ms of "thinking", then stream word-by-word every 35ms.
    _streamTimer?.cancel();
    _streamTimer = Timer(const Duration(milliseconds: 500), () {
      _streamTimer =
          Timer.periodic(const Duration(milliseconds: 35), (timer) {
        if (i >= words.length) {
          timer.cancel();
          // Final patch: mark complete and attach RAG citations.
          _patch(assistantId,
              (m) => m.copyWith(isStreaming: false, sources: sources));
          return;
        }
        final chunk = (i == 0 ? '' : ' ') + words[i++];
        _patch(assistantId, (m) => m.copyWith(text: m.text + chunk));
      });
    });
  }

  /// Replaces one message (by id) with an updated copy — the streaming
  /// primitive used above.
  void _patch(String id, ChatMessage Function(ChatMessage) update) {
    state = [
      for (final m in state)
        if (m.id == id) update(m) else m,
    ];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

/// Derived flag for the input bar / send button.
final chatBusyProvider = Provider<bool>(
  (ref) => ref.watch(chatProvider).any((m) => m.isStreaming),
);
