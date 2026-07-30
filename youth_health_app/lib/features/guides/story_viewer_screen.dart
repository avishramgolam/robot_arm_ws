import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_theme.dart';
import 'models/topic_guide.dart';

/// Instagram/Snapchat-style story viewer for a [TopicGuide].
///
/// Interactions:
///   - Tap RIGHT third of the screen → next card (last card: close)
///   - Tap LEFT third → previous card
///   - Horizontal swipe (PageView) also works
///   - Segmented progress bar at the top tracks position
///   - X button closes at any time
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key, required this.guide});

  final TopicGuide guide;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int target) {
    // Past the last card → close the viewer; before the first → ignore.
    if (target >= widget.guide.cards.length) {
      Navigator.of(context).pop();
      return;
    }
    if (target < 0) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.guide.cards;
    final accent = widget.guide.accent;

    return Scaffold(
      backgroundColor: AppColors.slateDark,
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Swipeable cards ----
            // Tap zones sit on TOP of the PageView; horizontal swipes still
            // reach the PageView because taps and drags are disambiguated by
            // the gesture arena.
            PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _StoryCardView(
                card: cards[i],
                accent: accent,
                // Provenance footer only on the final card.
                sourceLabel:
                    i == cards.length - 1 ? widget.guide.sourceLabel : null,
              ),
            ),

            // ---- Left/right tap zones for story-style navigation ----
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _goTo(_index - 1),
                    ),
                  ),
                  const Spacer(), // middle third: no tap action (text select)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _goTo(_index + 1),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Top chrome: progress segments + title + close ----
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < cards.length; i++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                // Filled up to and including current card.
                                color: i <= _index
                                    ? Colors.white
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Icon(widget.guide.icon,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.guide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One full-screen story card: icon, title, scannable Markdown body,
/// optional footnote and provenance label.
class _StoryCardView extends StatelessWidget {
  const _StoryCardView({
    required this.card,
    required this.accent,
    this.sourceLabel,
  });

  final StoryCard card;
  final Color accent;
  final String? sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 88, 24, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.icon != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(card.icon, size: 34, color: accent),
              ),
            const SizedBox(height: 20),
            Text(card.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            // Markdown lets content authors bold the key phrase per card.
            MarkdownBody(
              data: card.body,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    fontSize: 16.5, height: 1.55, color: AppColors.ink),
                strong: TextStyle(fontWeight: FontWeight.w700, color: accent),
              ),
            ),
            const Spacer(),
            if (card.footnote != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lavenderTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  card.footnote!,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.slateDark),
                ),
              ),
            if (sourceLabel != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 15, color: AppColors.verifiedBadge),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sourceLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.verifiedBadge,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
