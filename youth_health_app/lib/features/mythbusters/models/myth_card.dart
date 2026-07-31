/// One myth-vs-fact flashcard.
class MythCard {
  const MythCard({
    required this.id,
    required this.myth,
    required this.fact,
    required this.sourceLabel,
  });

  final String id;

  /// The misconception, phrased the way people actually say it.
  final String myth;

  /// The evidence-based correction (Markdown-capable).
  final String fact;

  /// Provenance shown on the fact side, e.g. "WHO".
  final String sourceLabel;
}
