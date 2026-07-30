import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panic_provider.dart';

/// Innocent-looking, fully *functional* calculator that masks the app when
/// panic mode is active. It must survive a glance AND a curious tap — so the
/// buttons really work.
///
/// Unlock gesture: LONG-PRESS the "Calculator" title in the top-left corner.
/// It is deliberately subtle — no visible hint, no back button.
class DecoyCalculatorScreen extends ConsumerStatefulWidget {
  const DecoyCalculatorScreen({super.key});

  @override
  ConsumerState<DecoyCalculatorScreen> createState() =>
      _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends ConsumerState<DecoyCalculatorScreen> {
  String _display = '0';
  double? _accumulator; // left operand waiting for an operator
  String? _pendingOp; //   '+', '−', '×', '÷'
  bool _startNewNumber = true;

  // ---- Calculator logic (kept simple but genuinely usable) -----------------

  void _tapDigit(String d) {
    setState(() {
      if (_startNewNumber || _display == '0') {
        _display = d == '.' ? '0.' : d;
        _startNewNumber = false;
      } else if (d != '.' || !_display.contains('.')) {
        _display += d;
      }
    });
  }

  void _tapOperator(String op) {
    setState(() {
      _applyPending();
      _pendingOp = op;
      _startNewNumber = true;
    });
  }

  void _tapEquals() {
    setState(() {
      _applyPending();
      _pendingOp = null;
      _startNewNumber = true;
    });
  }

  void _tapClear() {
    setState(() {
      _display = '0';
      _accumulator = null;
      _pendingOp = null;
      _startNewNumber = true;
    });
  }

  void _applyPending() {
    final current = double.tryParse(_display) ?? 0;
    if (_accumulator == null || _pendingOp == null) {
      _accumulator = current;
      return;
    }
    final a = _accumulator!;
    final result = switch (_pendingOp!) {
      '+' => a + current,
      '−' => a - current,
      '×' => a * current,
      '÷' => current == 0 ? double.nan : a / current,
      _ => current,
    };
    _accumulator = result;
    _display = _format(result);
  }

  String _format(double v) {
    if (v.isNaN) return 'Error';
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v.toString();
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF17181C); // generic dark calculator look
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Title row. The long-press on the title is the hidden unlock
            // gesture that flips panicModeProvider back to false.
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () =>
                    ref.read(panicModeProvider.notifier).state = false,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Calculator',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  child: Text(
                    _display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
            _keypad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _keypad() {
    const rows = [
      ['C', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    // The zero key spans two columns, like most calculators.
                    flex: key == '0' ? 2 : 1,
                    child: _CalcKey(label: key, onTap: () => _onKey(key)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _onKey(String key) {
    switch (key) {
      case 'C':
        _tapClear();
      case '=':
        _tapEquals();
      case '+' || '−' || '×' || '÷':
        _tapOperator(key);
      case '±':
        setState(() => _display = _format(-(double.tryParse(_display) ?? 0)));
      case '%':
        setState(
            () => _display = _format((double.tryParse(_display) ?? 0) / 100));
      default:
        _tapDigit(key);
    }
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  bool get _isOperator => const {'÷', '×', '−', '+', '='}.contains(label);
  bool get _isFunction => const {'C', '±', '%'}.contains(label);

  @override
  Widget build(BuildContext context) {
    final bg = _isOperator
        ? const Color(0xFFF09A36)
        : _isFunction
            ? const Color(0xFF5C5F66)
            : const Color(0xFF2E3138);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
