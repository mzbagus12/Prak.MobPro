import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:percobaan_2/main.dart';

void main() {
  testWidgets('like and unlike restore count', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('10 likes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.text('11 likes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();
    expect(find.text('10 likes'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
