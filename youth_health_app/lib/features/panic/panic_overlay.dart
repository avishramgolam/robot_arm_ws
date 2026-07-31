import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'decoy_calculator_screen.dart';
import 'panic_provider.dart';

/// Wraps the ENTIRE app (injected via `MaterialApp.builder` in app.dart) so
/// the panic button and the decoy mask are present on every screen — including
/// pushed routes like the story viewer.
///
/// Layer order (bottom → top):
///   1. The real app (`child`)
///   2. Draggable floating panic button
///   3. Decoy calculator, only when panic mode is active
class PanicOverlay extends ConsumerStatefulWidget {
  const PanicOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PanicOverlay> createState() => _PanicOverlayState();
}

class _PanicOverlayState extends ConsumerState<PanicOverlay> {
  /// Current position of the floating button; user can drag it anywhere so it
  /// never blocks content. Null until first layout (then bottom-right).
  Offset? _buttonPos;

  static const _buttonSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final panicActive = ref.watch(panicModeProvider);

    return Directionality(
      // MaterialApp.builder runs above the Localizations widget of pushed
      // routes' context, so provide directionality for our own widgets.
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Default resting spot: bottom-right, above the nav bar.
          final pos = _buttonPos ??
              Offset(
                constraints.maxWidth - _buttonSize - 16,
                constraints.maxHeight - _buttonSize - 140,
              );

          return Stack(
            children: [
              widget.child,

              // -- Floating panic button (hidden while decoy is showing) ----
              if (!panicActive)
                Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: GestureDetector(
                    // Drag to reposition; clamp to screen bounds.
                    onPanUpdate: (d) => setState(() {
                      final next = pos + d.delta;
                      _buttonPos = Offset(
                        next.dx.clamp(0, constraints.maxWidth - _buttonSize),
                        next.dy.clamp(0, constraints.maxHeight - _buttonSize),
                      );
                    }),
                    // Single tap = instant mask. No confirmation dialog —
                    // speed is the whole point.
                    onTap: () =>
                        ref.read(panicModeProvider.notifier).state = true,
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        // Deliberately discreet: looks like a generic app
                        // utility bubble, not an alarm.
                        color: const Color(0xFF3E5C76).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calculate_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

              // -- Decoy mask ----------------------------------------------
              // Instant switch (no animation): an exit animation would reveal
              // the real screen underneath for a few frames.
              if (panicActive)
                const Positioned.fill(child: DecoyCalculatorScreen()),
            ],
          );
        },
      ),
    );
  }
}
