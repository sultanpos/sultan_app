import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sultan/core/widgets/responsive_page.dart';

void main() {
  Widget buildApp(double width) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: const ResponsivePage(
        mobile: Text('Mobile'),
        desktop: Text('Desktop'),
      ),
    ),
  );

  group('ResponsivePage', () {
    testWidgets('shows mobile widget when width is below breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp(600));

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows desktop widget when width is above breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp(1200));

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
    });

    testWidgets('shows mobile widget at exactly the breakpoint (900px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp(900));

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('isDesktop returns false below breakpoint', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = ResponsivePage.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isFalse);
    });
  });
}
