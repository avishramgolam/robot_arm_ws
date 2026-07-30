import 'package:flutter/material.dart';

import '../providers/chat_provider.dart';

/// Horizontal scrollable row of category chips above the input bar.
///
/// Tapping a chip pre-fills the composer via [onTagSelected] (rather than
/// auto-sending) so users can edit or complete the question first — e.g.
/// "Is it normal that …".
class QuickTagChips extends StatelessWidget {
  const QuickTagChips({super.key, required this.onTagSelected});

  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: quickTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, prompt) = quickTags[i];
          return ActionChip(
            label: Text(label),
            onPressed: () => onTagSelected(prompt),
          );
        },
      ),
    );
  }
}
