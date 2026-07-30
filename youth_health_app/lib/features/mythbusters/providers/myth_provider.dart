import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myth_card.dart';

/// Offline-bundled myth deck. Swap for a localized JSON asset in production.
final mythDeckProvider = Provider<List<MythCard>>((ref) => _deck);

const _deck = <MythCard>[
  MythCard(
    id: 'first_time',
    myth: '"You can\'t get pregnant the first time you have sex."',
    fact:
        'Pregnancy is possible **any** time sperm reaches the vagina — '
        'including the very first time. Contraception matters from day one.',
    sourceLabel: 'WHO',
  ),
  MythCard(
    id: 'pull_out',
    myth: '"Pulling out is a reliable way to avoid pregnancy."',
    fact:
        'With typical use, about **1 in 5** couples using withdrawal get '
        'pregnant within a year. Pre-ejaculate can carry sperm, and timing '
        'is hard to control.',
    sourceLabel: 'WHO Family Planning Handbook',
  ),
  MythCard(
    id: 'period_sex',
    myth: '"You can\'t get pregnant during your period."',
    fact:
        'Unlikely, but **possible** — sperm can survive up to 5 days, and '
        'shorter cycles can ovulate soon after bleeding ends.',
    sourceLabel: 'WHO',
  ),
  MythCard(
    id: 'sti_looks',
    myth: '"You can tell if someone has an STI by looking."',
    fact:
        'Most STIs have **no visible symptoms** for long periods. The only '
        'way to know is testing — which is routine, quick, and confidential.',
    sourceLabel: 'WHO',
  ),
  MythCard(
    id: 'masturbation',
    myth: '"Masturbation is harmful or causes health problems."',
    fact:
        'It\'s a **normal, harmless** part of human sexuality at any age, '
        'with no proven negative health effects.',
    sourceLabel: 'UNESCO CSE 2018',
  ),
  MythCard(
    id: 'two_condoms',
    myth: '"Two condoms protect better than one."',
    fact:
        'Doubling up creates **friction** that makes both more likely to '
        'tear. One correctly-used condom is the right approach.',
    sourceLabel: 'WHO',
  ),
];
