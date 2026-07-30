/// Who authored a chat message.
enum MessageRole { user, assistant }

/// A single RAG citation attached to an AI answer, rendered as a small
/// "Verified" badge under the bubble (e.g. "Verified: WHO Guidelines").
class SourceBadge {
  const SourceBadge({required this.label, this.url});

  final String label;
  final String? url;
}

/// One message in the chat feed.
///
/// Immutable: streaming updates replace the message with `copyWith`, which
/// plays nicely with Riverpod's value-equality change detection.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.sources = const [],
    this.isStreaming = false,
  });

  final String id;
  final MessageRole role;

  /// Markdown-capable body text. While [isStreaming] is true this grows as
  /// tokens arrive from the backend.
  final String text;

  final List<SourceBadge> sources;
  final bool isStreaming;

  ChatMessage copyWith({
    String? text,
    List<SourceBadge>? sources,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      sources: sources ?? this.sources,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
