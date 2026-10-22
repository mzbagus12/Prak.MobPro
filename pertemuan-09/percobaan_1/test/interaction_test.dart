import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:percobaan_1/main.dart';

void main() {
  testWidgets('counter supports negative and increment', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Kurang'));
    await tester.pump();
    expect(find.text('-1'), findsOneWidget);
    await tester.tap(find.text('Tambah'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });
}
