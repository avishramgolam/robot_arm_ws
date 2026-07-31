import 'package:flutter/material.dart';

/// Lightweight, dependency-free Tinder-style card stack.
///
/// Built by hand instead of pulling in `flutter_card_swiper` — the behavior
/// we need (drag, fling threshold, spring-back, peek of next cards) is ~150
/// lines, and owning it avoids third-party version churn.
///
/// Generic over the item type; the parent supplies [cardBuilder] and gets a
/// callback when the top card is dismissed.
class SwipeCardStack<T> extends StatefulWidget {
  const SwipeCardStack({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.onSwiped,
    required this.topIndex,
  });

  final List<T> items;

  /// Index of the current top card into [items]; owned by the parent so it
  /// can also drive a progress label / restart button.
  final int topIndex;

  final Widget Function(BuildContext context, T item, bool isTop) cardBuilder;

  /// Called after the fling-out animation completes.
  final void Function(T item) onSwiped;

  @override
  State<SwipeCardStack<T>> createState() => _SwipeCardStackState<T>();
}

class _SwipeCardStackState<T> extends State<SwipeCardStack<T>>
    with SingleTickerProviderStateMixin {
  /// Current drag offset of the top card, in logical pixels.
  Offset _drag = Offset.zero;

  /// Animates either a spring-back to center or a fling off-screen.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Offset>? _animation;
  bool _flingingOut = false;

  static const _dismissThreshold = 110.0; // px of horizontal drag to dismiss

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _drag = _animation?.value ?? Offset.zero);
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _flingingOut) {
        // Fling finished → commit the dismissal and reset for the next card.
        final item = widget.items[widget.topIndex];
        _flingingOut = false;
        _drag = Offset.zero;
        widget.onSwiped(item);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    final flungByVelocity = details.velocity.pixelsPerSecond.dx.abs() > 800;
    final past = _drag.dx.abs() > _dismissThreshold;

    if (past || flungByVelocity) {
      // Continue in the current direction until fully off-screen.
      final direction = _drag.dx.isNegative ? -1 : 1;
      final target = Offset(direction * size.width * 1.3, _drag.dy * 2);
      _flingingOut = true;
      _animate(target, Curves.easeIn);
    } else {
      // Not far enough → spring back to center.
      _animate(Offset.zero, Curves.easeOutBack);
    }
  }

  void _animate(Offset target, Curve curve) {
    _animation = Tween(begin: _drag, end: target)
        .animate(CurvedAnimation(parent: _controller, curve: curve));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.items.length - widget.topIndex;
    if (remaining <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Rotation proportional to horizontal drag gives the "tinder tilt".
        final angle = _drag.dx / size.width * 0.35;
        // Show at most 2 cards peeking behind the top one.
        final visible = remaining.clamp(0, 3);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Painted back-to-front: deepest peek card first, top card last.
            for (var depth = visible - 1; depth >= 0; depth--)
              if (depth == 0)
                // ---- Top, draggable card ----
                Transform.translate(
                  offset: _drag,
                  child: Transform.rotate(
                    angle: angle,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        if (_controller.isAnimating) return;
                        setState(() => _drag += d.delta);
                      },
                      onPanEnd: (d) => _onPanEnd(d, size),
                      child: widget.cardBuilder(
                        context,
                        widget.items[widget.topIndex],
                        true,
                      ),
                    ),
                  ),
                )
              else
                // ---- Peek cards: slightly scaled down and pushed down ----
                Transform.translate(
                  offset: Offset(0, depth * 14),
                  child: Transform.scale(
                    scale: 1 - depth * 0.04,
                    child: IgnorePointer(
                      child: widget.cardBuilder(
                        context,
                        widget.items[widget.topIndex + depth],
                        false,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
