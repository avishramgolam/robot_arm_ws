import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'models/topic_guide.dart';
import 'providers/guides_provider.dart';
import 'story_viewer_screen.dart';

/// Hub feed: a 2-column grid of bite-sized visual guides.
/// Tapping a tile pushes the full-screen [StoryViewerScreen].
class TopicGuidesScreen extends ConsumerWidget {
  const TopicGuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(topicGuidesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guides')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemCount: guides.length,
        itemBuilder: (context, i) => _GuideTile(guide: guides[i]),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide});

  final TopicGuide guide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Full-screen dialog transition feels like "entering" a story.
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => StoryViewerScreen(guide: guide),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent icon puck
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: guide.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(guide.icon, color: guide.accent, size: 26),
              ),
              const Spacer(),
              Text(guide.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                guide.subtitle,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 8),
              Text(
                '${guide.cards.length} cards',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: guide.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
