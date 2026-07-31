import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import 'typing_indicator.dart';

/// A single chat bubble.
///
/// - User messages: slate-blue filled, right-aligned, plain text.
/// - Assistant messages: soft surface card, left-aligned, Markdown body,
///   optional RAG "Verified" source badges underneath.
/// - While streaming with no text yet → shows the [TypingIndicator].
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final showThinking = message.isStreaming && message.text.isEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.slate : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  // Small "tail" corner on the author's side.
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: showThinking
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: TypingIndicator(),
                    )
                  : isUser
                      ? Text(
                          message.text,
                          style: const TextStyle(
                              color: Colors.white, height: 1.4),
                        )
                      // MarkdownBody renders the AI answer scannably:
                      // bold key phrases, bullet lists, headings.
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                color: AppColors.ink, height: 1.45),
                            listBullet:
                                const TextStyle(color: AppColors.slate),
                            strong: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.slateDark),
                          ),
                        ),
            ),

            // RAG citation badges, e.g. "Verified: WHO Guidelines".
            if (message.sources.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final source in message.sources)
                      _SourceChip(source: source),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final SourceBadge source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined,
              size: 14, color: AppColors.verifiedBadge),
          const SizedBox(width: 4),
          Text(
            source.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.verifiedBadge,
            ),
          ),
        ],
      ),
    );
  }
}
