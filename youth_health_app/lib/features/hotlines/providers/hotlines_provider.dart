import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hotline.dart';

/// Offline-cached hotline directory.
///
/// Bundled with the app (no network needed in a crisis). In production,
/// refresh this from a signed remote manifest when online, but ALWAYS keep
/// the last-good copy on device.
///
/// NOTE: numbers below are well-known public services; verify each entry
/// against the operator's official site before every release.
final hotlinesProvider = Provider<List<Hotline>>((ref) => _hotlines);

/// Directory grouped by category, preserving category declaration order —
/// the shape the screen actually renders.
final hotlinesByCategoryProvider =
    Provider<Map<HotlineCategory, List<Hotline>>>((ref) {
  final all = ref.watch(hotlinesProvider);
  return {
    for (final category in HotlineCategory.values)
      if (all.any((h) => h.category == category))
        category: all.where((h) => h.category == category).toList(),
  };
});

const _hotlines = <Hotline>[
  // ---- Crisis ----
  Hotline(
    name: '988 Suicide & Crisis Lifeline',
    description: 'Free, confidential support 24/7. Call or text 988.',
    region: 'USA',
    category: HotlineCategory.crisis,
    phone: '988',
    website: 'https://988lifeline.org',
  ),
  Hotline(
    name: 'Crisis Text Line',
    description: 'Text with a trained crisis counselor, free, 24/7.',
    region: 'USA · Canada · UK · Ireland',
    category: HotlineCategory.crisis,
    smsNumber: '741741',
    smsKeyword: 'HOME',
    website: 'https://www.crisistextline.org',
  ),
  Hotline(
    name: 'Find a Helpline (IASP)',
    description:
        'Directory of verified crisis lines in 130+ countries — use this to '
        'find local support anywhere in the world.',
    region: 'Global',
    category: HotlineCategory.crisis,
    website: 'https://findahelpline.com',
  ),

  // ---- LGBTQ+ ----
  Hotline(
    name: 'The Trevor Project',
    description:
        'Crisis support for LGBTQ+ young people, 24/7 — call, text, or chat.',
    region: 'USA',
    category: HotlineCategory.lgbtq,
    phone: '1-866-488-7386',
    smsNumber: '678678',
    smsKeyword: 'START',
    website: 'https://www.thetrevorproject.org',
  ),
  Hotline(
    name: 'Switchboard LGBT+',
    description: 'Listening and information service run by LGBT+ volunteers.',
    region: 'UK',
    category: HotlineCategory.lgbtq,
    phone: '0800 0119 100',
    website: 'https://switchboard.lgbt',
  ),

  // ---- Sexual health ----
  Hotline(
    name: 'Planned Parenthood',
    description:
        'Sexual and reproductive health info, appointments, and chat.',
    region: 'USA',
    category: HotlineCategory.sexualHealth,
    phone: '1-800-230-7526',
    website: 'https://www.plannedparenthood.org',
  ),
  Hotline(
    name: 'IPPF Member Associations',
    description:
        'Find youth-friendly sexual health services in 140+ countries via '
        'the International Planned Parenthood Federation.',
    region: 'Global',
    category: HotlineCategory.sexualHealth,
    website: 'https://www.ippf.org',
  ),

  // ---- Abuse & violence ----
  Hotline(
    name: 'Childhelp National Child Abuse Hotline',
    description: 'Support for young people experiencing abuse, 24/7.',
    region: 'USA & Canada',
    category: HotlineCategory.violence,
    phone: '1-800-422-4453',
    website: 'https://www.childhelphotline.org',
  ),
  Hotline(
    name: 'RAINN National Sexual Assault Hotline',
    description: 'Confidential support after sexual assault, 24/7.',
    region: 'USA',
    category: HotlineCategory.violence,
    phone: '1-800-656-4673',
    website: 'https://www.rainn.org',
  ),
];
