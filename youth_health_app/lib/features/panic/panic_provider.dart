import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global panic state.
///
/// `true`  → the whole app is masked by the innocent-looking decoy screen.
/// `false` → normal app UI.
///
/// A plain [StateProvider] is enough here: the value is a single boolean and
/// every consumer (floating button, decoy overlay) only needs to read/flip it.
final panicModeProvider = StateProvider<bool>((ref) => false);
