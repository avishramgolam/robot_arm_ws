import 'package:flutter/material.dart';

/// One swipeable card inside a story-style guide.
class StoryCard {
  const StoryCard({
    required this.title,
    required this.body,
    this.icon,
    this.footnote,
  });

  final String title;

  /// Short, scannable body text (2–4 sentences max per card by content rule).
  final String body;

  final IconData? icon;

  /// Optional small print, e.g. effectiveness stats or "see a provider if…".
  final String? footnote;
}

/// A bite-sized visual guide shown in the hub grid.
class TopicGuide {
  const TopicGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cards,
    required this.sourceLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Pastel accent used for the hub tile and the story background.
  final Color accent;

  final List<StoryCard> cards;

  /// RAG-style provenance shown on the last card ("Based on WHO guidance").
  final String sourceLabel;
}
