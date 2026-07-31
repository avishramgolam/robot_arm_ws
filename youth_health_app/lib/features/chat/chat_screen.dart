import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../panic/panic_provider.dart';
import 'providers/chat_provider.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/quick_tag_chips.dart';

/// The AI Q&A tab.
///
/// Layout, top → bottom:
///   AppBar (title + explicit panic switch)
///   Chat feed (reversed ListView — newest at the bottom, auto-follows)
///   Quick-tag chips
///   Input bar (300-char limit + counter)
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever a message is added or a streaming token arrives.
    final messages = ref.watch(chatProvider);
    final busy = ref.watch(chatBusyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask anything'),
        actions: [
          // Explicit panic switch in the top bar, in addition to the global
          // floating button — one tap masks the app with the decoy screen.
          IconButton(
            tooltip: 'Quick exit',
            icon: const Icon(Icons.visibility_off_outlined),
            onPressed: () => ref.read(panicModeProvider.notifier).state = true,
          ),
        ],
      ),
      body: Column(
        children: [
          // Small always-visible reassurance line — core to the app's trust
          // contract, so it lives in the UI rather than a buried settings page.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.lavenderTint,
            // Honest disclosure: questions are reviewed anonymously by health
            // professionals to improve answers — never tied to a person.
            child: const Text(
              'Anonymous — no account, no name · Questions may be reviewed '
              'anonymously by health professionals · Not medical care',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.slateDark),
            ),
          ),

          // ---- Chat feed ----
          Expanded(
            child: ListView.builder(
              // reverse:true pins the view to the newest message, so the list
              // auto-follows streaming output with no scroll-controller math.
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                // Reversed list ⇒ index 0 is the LAST message.
                final message = messages[messages.length - 1 - i];
                return MessageBubble(
                    key: ValueKey(message.id), message: message);
              },
            ),
          ),

          // ---- Quick-tag chips ----
          QuickTagChips(
            onTagSelected: (prompt) {
              // Pre-fill the composer and put the cursor at the end so the
              // user can finish the sentence (e.g. "Is it normal that …").
              _composer.text = prompt;
              _composer.selection =
                  TextSelection.collapsed(offset: prompt.length);
            },
          ),

          // ---- Input bar ----
          ChatInputBar(
            controller: _composer,
            enabled: !busy,
            // Delegates to the notifier, which appends the user bubble and
            // starts the assistant's streaming response.
            onSend: (text) => ref.read(chatProvider.notifier).send(text),
          ),
        ],
      ),
    );
  }
}
