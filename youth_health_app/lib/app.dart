import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/panic/panic_overlay.dart';
import 'shell/main_shell.dart';

class YouthHealthApp extends StatelessWidget {
  const YouthHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compass', // neutral, non-descriptive app name by design
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // `builder` wraps EVERY route in the app with the panic overlay, so the
      // quick-exit button and decoy mask work even inside pushed screens
      // (story viewer, etc.), not just the bottom-nav tabs.
      builder: (context, child) =>
          PanicOverlay(child: child ?? const SizedBox.shrink()),
      home: const MainShell(),
    );
  }
}
