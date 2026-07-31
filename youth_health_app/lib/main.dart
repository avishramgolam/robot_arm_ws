import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope is the root of the Riverpod dependency graph.
  // All app state (chat, panic mode, guides…) lives below this widget and is
  // held in memory only — nothing is persisted to disk, by design.
  runApp(const ProviderScope(child: YouthHealthApp()));
}
