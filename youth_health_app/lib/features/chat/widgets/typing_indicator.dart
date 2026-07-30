import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Three softly pulsing dots shown inside an assistant bubble while the
/// backend is "thinking" (streaming has started but no text has arrived yet).
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by a third of the cycle; opacity follows a
            // triangle wave so the pulse feels calm, not bouncy.
            final t = (_controller.value + i / 3) % 1.0;
            final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: 0.25 + 0.75 * opacity,
                child: const CircleAvatar(
                    radius: 4, backgroundColor: AppColors.slate),
              ),
            );
          }),
        );
      },
    );
  }
}
