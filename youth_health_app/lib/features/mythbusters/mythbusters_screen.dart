import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'models/myth_card.dart';
import 'providers/myth_provider.dart';
import 'widgets/swipe_card_stack.dart';

/// UI state for the deck: which card is on top, and which cards have been
/// flipped from Myth → Fact.
class _MythDeckState {
  const _MythDeckState({this.topIndex = 0, this.revealed = const {}});

  final int topIndex;
  final Set<String> revealed; // card ids currently showing the Fact side

  _MythDeckState copyWith({int? topIndex, Set<String>? revealed}) =>
      _MythDeckState(
        topIndex: topIndex ?? this.topIndex,
        revealed: revealed ?? this.revealed,
      );
}

class _MythDeckNotifier extends Notifier<_MythDeckState> {
  @override
  _MythDeckState build() => const _MythDeckState();

  /// Tap → flip the card to its Fact side (or back).
  void toggleReveal(String id) {
    final next = {...state.revealed};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(revealed: next);
  }

  /// Swipe → advance to the next card.
  void advance() => state = state.copyWith(topIndex: state.topIndex + 1);

  /// Deck finished → start over.
  void restart() => state = const _MythDeckState();
}

final _mythDeckStateProvider =
    NotifierProvider<_MythDeckNotifier, _MythDeckState>(_MythDeckNotifier.new);

/// Swipeable flashcard deck: each card shows a MYTH; tap to flip and reveal
/// the FACT; swipe left/right to move on to the next card.
class MythBustersScreen extends ConsumerWidget {
  const MythBustersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(mythDeckProvider);
    final deckState = ref.watch(_mythDeckStateProvider);
    final notifier = ref.read(_mythDeckStateProvider.notifier);
    final finished = deckState.topIndex >= deck.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MythBusters'),
        actions: [
          if (!finished)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${deckState.topIndex + 1} / ${deck.length}',
                  style: const TextStyle(
                      color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: finished
            ? _DeckFinished(onRestart: notifier.restart)
            : Column(
                children: [
                  const Text(
                    'Tap a card to reveal the fact · swipe to skip',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SwipeCardStack<MythCard>(
                      items: deck,
                      topIndex: deckState.topIndex,
                      // Any swipe direction just advances; there is no
                      // right/wrong judgment in this deck by design.
                      onSwiped: (_) => notifier.advance(),
                      cardBuilder: (context, card, isTop) => _MythCardView(
                        card: card,
                        revealed: deckState.revealed.contains(card.id),
                        // Only the top card is tappable/flippable.
                        onTap: isTop
                            ? () => notifier.toggleReveal(card.id)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A single flashcard with a 3D flip between the Myth face and the Fact face.
class _MythCardView extends StatelessWidget {
  const _MythCardView({
    required this.card,
    required this.revealed,
    required this.onTap,
  });

  final MythCard card;
  final bool revealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // AnimatedSwitcher with a rotation transition approximates a card flip
      // without a custom matrix animation.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) => RotationYTransition(
          turns: animation,
          child: child,
        ),
        child: revealed
            ? _CardFace(
                key: const ValueKey('fact'),
                color: AppColors.factTeal,
                tag: 'FACT',
                icon: Icons.verified_outlined,
                body: card.fact,
                footer: 'Source: ${card.sourceLabel}',
                hint: 'Tap to see the myth again',
              )
            : _CardFace(
                key: const ValueKey('myth'),
                color: AppColors.mythRose,
                tag: 'MYTH',
                icon: Icons.help_outline,
                body: card.myth,
                hint: 'Tap to reveal the fact',
              ),
      ),
    );
  }
}

/// Horizontal (Y-axis) flip used by the AnimatedSwitcher above.
class RotationYTransition extends AnimatedWidget {
  const RotationYTransition({
    super.key,
    required Animation<double> turns,
    required this.child,
  }) : super(listenable: turns);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    // 0 → edge-on (π/2), 1 → face-on (0): incoming face "opens up".
    final angle = (1 - t) * 1.5708;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateY(angle),
      child: child,
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.color,
    required this.tag,
    required this.icon,
    required this.body,
    required this.hint,
    this.footer,
  });

  final Color color;
  final String tag;
  final IconData icon;
  final String body;
  final String hint;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MYTH / FACT pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  tag,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          MarkdownBody(
            data: body,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 20,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              strong: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const Spacer(),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 14, color: AppColors.verifiedBadge),
                  const SizedBox(width: 5),
                  Text(
                    footer!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.verifiedBadge,
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: Text(
              hint,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// End-of-deck state with a restart button.
class _DeckFinished extends StatelessWidget {
  const _DeckFinished({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_outlined,
              size: 56, color: AppColors.teal),
          const SizedBox(height: 16),
          Text('Deck complete',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Nice — you just busted every myth in this deck.',
            style: TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay),
            label: const Text('Go again'),
          ),
        ],
      ),
    );
  }
}
