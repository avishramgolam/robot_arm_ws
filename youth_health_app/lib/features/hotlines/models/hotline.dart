/// A support hotline entry in the offline-cached directory.
class Hotline {
  const Hotline({
    required this.name,
    required this.description,
    required this.region,
    required this.category,
    this.phone,
    this.smsNumber,
    this.smsKeyword,
    this.website,
  });

  final String name;
  final String description;

  /// Human-readable coverage, e.g. "Global", "USA & Canada".
  final String region;

  final HotlineCategory category;

  /// E.164-ish dialable number; null if the service is text/web only.
  final String? phone;

  /// Crisis text line number + the keyword to send, if applicable.
  final String? smsNumber;
  final String? smsKeyword;

  final String? website;
}

enum HotlineCategory {
  crisis('Crisis & Suicide Support'),
  lgbtq('LGBTQ+ Support'),
  sexualHealth('Sexual Health Info'),
  violence('Abuse & Violence Support');

  const HotlineCategory(this.label);
  final String label;
}
