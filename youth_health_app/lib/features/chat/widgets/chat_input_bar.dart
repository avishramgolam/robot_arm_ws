import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Rounded composer with send button and live character counter (max 300).
///
/// Stateless from the outside: the parent owns the [TextEditingController]
/// (so quick-tag chips can pre-fill it) and receives [onSend] callbacks.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  static const maxChars = 300;

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  /// False while the assistant is streaming — greys out the send button.
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the counter and send-button state track
    // the text length live.
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.controller.text.characters.length;
    final nearLimit = length > ChatInputBar.maxChars - 40;
    final canSend = widget.enabled && widget.controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                // Hard limit enforced at the input level; counter below is
                // purely informative.
                inputFormatters: [
                  LengthLimitingTextInputFormatter(ChatInputBar.maxChars),
                ],
                decoration: InputDecoration(
                  hintText: 'Ask anything — it stays anonymous',
                  hintStyle: const TextStyle(color: AppColors.inkMuted),
                  // Counter pinned inside the field, bottom-right.
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 14, top: 14),
                    child: Text(
                      '$length/${ChatInputBar.maxChars}',
                      style: TextStyle(
                        fontSize: 11,
                        color: nearLimit
                            ? AppColors.mythRose
                            : AppColors.inkMuted,
                      ),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button: filled while active, muted while streaming/empty.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: canSend ? AppColors.teal : AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: canSend ? _submit : null,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: canSend ? Colors.white : AppColors.inkMuted,
                ),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
