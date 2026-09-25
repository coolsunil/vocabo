import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo/screens/pyq_screen.dart';

void main() {
  testWidgets('PYQ quiz screen renders JCA questions without bottom overflow', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(400, 800);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: PYQScreen()));

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Choose an Exam'), findsOneWidget);
    expect(find.text('Supreme Court'), findsOneWidget);
  });
}
