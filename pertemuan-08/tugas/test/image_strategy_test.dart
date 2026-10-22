import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas/home.dart';
import 'package:tugas/tujuan.dart';

void main() {
  testWidgets('home and detail prefer native HTML image loading', (tester) async {
    final client = MockClient((_) async => http.Response(
      '{"title":"Fixture","thumbnail":"https://example.invalid/thumb.jpg",'
      '"screenshots":[{"image":"https://example.invalid/cover.jpg"}]}', 200));
    await tester.pumpWidget(MaterialApp(
      home: Home(client: client),
      routes: {Tujuan.routeName: (_) => const Tujuan()},
    ));
    await tester.pumpAndSettle();
    expect((tester.widget<Image>(find.byType(Image)).image as NetworkImage).webHtmlElementStrategy,
        WebHtmlElementStrategy.prefer);
    await tester.tap(find.text('Fixture'));
    await tester.pumpAndSettle();
    expect((tester.widget<Image>(find.byType(Image).last).image as NetworkImage).webHtmlElementStrategy,
        WebHtmlElementStrategy.prefer);
    expect(tester.takeException(), isNull);
  });
}
