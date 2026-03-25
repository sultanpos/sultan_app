import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/app/app.dart';

void main() {
  testWidgets('app starts without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump();
    // App renders something (splash screen)
    expect(
      find.byType(MaterialApp),
      findsOneWidget,
    ); // MaterialApp.router wraps MaterialApp
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
