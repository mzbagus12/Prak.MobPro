import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas/main.dart';

void main() {
  testWidgets('short landscape counter caps at 33 and resets', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byIcon(Icons.fingerprint));
    for (var i = 0; i < 34; i++) {
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();
    }
    expect(find.text('33'), findsWidgets);
    expect(find.text('34'), findsNothing);
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await tester.pump();
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
