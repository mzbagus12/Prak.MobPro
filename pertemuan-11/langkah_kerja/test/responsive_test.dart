import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:tasbih_getx/main.dart';

void main() {
  tearDown(Get.reset);

  for (final size in [
    const Size(360, 480),
    const Size(640, 360),
    const Size(800, 600),
  ]) {
    testWidgets('fingerprint and reset at $size', (tester) async {
      tester.view.physicalSize = size;
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
      expect(find.text('33'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      await tester.tap(find.byIcon(Icons.refresh_outlined));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
