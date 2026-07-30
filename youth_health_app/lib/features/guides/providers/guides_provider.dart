import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/topic_guide.dart';

/// Static, offline-bundled guide catalogue.
///
/// In production this becomes a repository that loads localized JSON bundled
/// with the app (still offline-first) — the provider interface stays the same,
/// so no UI changes are needed when that swap happens.
final topicGuidesProvider = Provider<List<TopicGuide>>((ref) => _guides);

const _guides = <TopicGuide>[
  TopicGuide(
    id: 'condoms',
    title: 'How to Use Condoms',
    subtitle: 'Step-by-step, no awkwardness',
    icon: Icons.health_and_safety_outlined,
    accent: AppColors.teal,
    sourceLabel: 'Based on WHO & UNFPA guidance',
    cards: [
      StoryCard(
        title: 'Why condoms?',
        icon: Icons.shield_outlined,
        body:
            'Condoms are the only method that protects against **both** '
            'pregnancy and most STIs. Used correctly every time, external '
            'condoms are about 98% effective.',
      ),
      StoryCard(
        title: 'Step 1 — Check it',
        icon: Icons.fact_check_outlined,
        body:
            'Check the expiry date and that the wrapper has an air bubble '
            'when gently squeezed. Open with fingers — never teeth or '
            'scissors.',
      ),
      StoryCard(
        title: 'Step 2 — Right way round',
        icon: Icons.rotate_right,
        body:
            'The rim should roll **outward**, like a little hat. If you start '
            'the wrong way round, throw it away and use a new one.',
      ),
      StoryCard(
        title: 'Step 3 — Pinch & roll',
        icon: Icons.touch_app_outlined,
        body:
            'Pinch the tip to leave space (no air bubble), then roll it all '
            'the way down before any contact.',
      ),
      StoryCard(
        title: 'Step 4 — Afterwards',
        icon: Icons.delete_outline,
        body:
            'Hold the base while withdrawing, tie it off, and bin it — never '
            'flush. One condom, one use.',
        footnote: 'Slipped or broke? Emergency contraception works best '
            'within 72h — see the Support tab for local services.',
      ),
    ],
  ),
  TopicGuide(
    id: 'menstrual_cycle',
    title: 'The Menstrual Cycle',
    subtitle: 'What actually happens each month',
    icon: Icons.calendar_month_outlined,
    accent: AppColors.lavender,
    sourceLabel: 'Based on WHO adolescent health guidance',
    cards: [
      StoryCard(
        title: 'The big picture',
        icon: Icons.loop,
        body:
            'A cycle runs from the first day of one period to the first day '
            'of the next — **21 to 35 days is all normal**, especially in the '
            'first years.',
      ),
      StoryCard(
        title: 'Days 1–5 · Period',
        icon: Icons.water_drop_outlined,
        body:
            'The uterus sheds its lining. Bleeding for 2–7 days is typical. '
            'Cramps are common; heat and regular pain relief help.',
      ),
      StoryCard(
        title: 'Around day 14 · Ovulation',
        icon: Icons.egg_outlined,
        body:
            'An egg is released. This is the most fertile window — but sperm '
            'can survive up to 5 days, so pregnancy is possible from sex '
            '**before** ovulation too.',
      ),
      StoryCard(
        title: 'When to check in',
        icon: Icons.favorite_border,
        body:
            'Very heavy bleeding, pain that stops daily life, or periods that '
            'suddenly stop are worth discussing with a health provider.',
        footnote: 'Irregular cycles are very common in the first 2 years '
            'after periods start.',
      ),
    ],
  ),
  TopicGuide(
    id: 'pregnancy_basics',
    title: 'Understanding Pregnancy',
    subtitle: 'How it happens — and how it doesn\'t',
    icon: Icons.pregnant_woman_outlined,
    accent: AppColors.slate,
    sourceLabel: 'Based on WHO & UNESCO CSE guidance',
    cards: [
      StoryCard(
        title: 'The basics',
        icon: Icons.science_outlined,
        body:
            'Pregnancy can happen when sperm meets an egg. That requires '
            'sperm entering the vagina — from intercourse, or ejaculate very '
            'close to the vaginal opening.',
      ),
      StoryCard(
        title: 'What CAN cause it',
        icon: Icons.check_circle_outline,
        body:
            'Any vaginal sex without contraception — **including the first '
            'time**, during a period, or when "pulling out". Pre-ejaculate '
            'can contain sperm.',
      ),
      StoryCard(
        title: 'What can\'t',
        icon: Icons.cancel_outlined,
        body:
            'Kissing, hugging, masturbation, oral sex, toilet seats, or '
            'swimming pools cannot cause pregnancy.',
      ),
      StoryCard(
        title: 'If you\'re worried',
        icon: Icons.support_agent,
        body:
            'Emergency contraception is most effective within 72 hours. '
            'A missed period is the most common early sign — home tests are '
            'reliable from the first missed day.',
        footnote: 'Free, confidential help is listed in the Support tab.',
      ),
    ],
  ),
  TopicGuide(
    id: 'consent',
    title: 'Consent, Clearly',
    subtitle: 'What it is, what it isn\'t',
    icon: Icons.handshake_outlined,
    accent: AppColors.teal,
    sourceLabel: 'Based on UNESCO CSE 2018 guidance',
    cards: [
      StoryCard(
        title: 'Consent is…',
        icon: Icons.check_circle_outline,
        body:
            'A **freely given, enthusiastic yes** — every time, for every '
            'act. It can be taken back at any moment, even mid-way.',
      ),
      StoryCard(
        title: 'Consent is NOT…',
        icon: Icons.do_not_disturb_alt_outlined,
        body:
            'Silence, freezing, being pressured, being asleep or drunk, or '
            'having said yes before. "Maybe" and "I guess" are not yes.',
      ),
      StoryCard(
        title: 'It goes both ways',
        icon: Icons.sync_alt,
        body:
            'Checking in ("is this okay?") isn\'t awkward — it\'s attractive '
            'and respectful. You\'re always allowed to change your mind too.',
        footnote:
            'If something happened without your consent, it was not your '
            'fault. Support lines are in the Support tab.',
      ),
    ],
  ),
];
