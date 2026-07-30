import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/chat_screen.dart';
import '../features/guides/topic_guides_screen.dart';
import '../features/hotlines/hotlines_screen.dart';
import '../features/mythbusters/mythbusters_screen.dart';

/// Index of the currently selected bottom-nav tab.
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Root scaffold: bottom navigation between the four core modules.
///
/// The panic button/decoy are NOT here — they live in [PanicOverlay] above
/// MaterialApp's navigator so they also cover pushed routes.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      // IndexedStack keeps each tab's state alive (chat scroll position,
      // half-typed messages…) when switching tabs.
      body: IndexedStack(
        index: index,
        children: const [
          ChatScreen(),
          TopicGuidesScreen(),
          MythBustersScreen(),
          HotlinesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(navIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Ask',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Guides',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt),
            label: 'Myths',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
