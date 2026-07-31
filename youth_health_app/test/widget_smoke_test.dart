import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youth_health_app/app.dart';

void main() {
  testWidgets('app boots to chat tab with welcome message', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YouthHealthApp()));
    await tester.pump();

    expect(find.text('Ask anything'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('panic button masks the app with the decoy calculator',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YouthHealthApp()));
    await tester.pump();

    // Tap the floating panic bubble.
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pump();

    // Real UI is masked; decoy calculator is showing.
    expect(find.text('Calculator'), findsOneWidget);

    // Long-press the title to unlock.
    await tester.longPress(find.text('Calculator'));
    await tester.pump();
    expect(find.text('Calculator'), findsNothing);
    expect(find.text('Ask anything'), findsOneWidget);
  });
}
