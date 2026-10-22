import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas/tujuan.dart';
import 'package:tugas/home.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:async';
import 'dart:convert';

// Synthetic fixture, not a live API response.
final fixture = jsonEncode({'title': 'Fixture Game', 'screenshots': []});

void main() {
  testWidgets('loading then empty screenshots and named route back', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      MaterialApp(
        home: Home(client: MockClient((_) => response.future)),
        routes: {Tujuan.routeName: (_) => const Tujuan()},
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(http.Response(fixture, 200));
    await tester.pumpAndSettle();
    expect(find.text('Fixture Game'), findsOneWidget);
    await tester.tap(find.text('Fixture Game'));
    await tester.pumpAndSettle();
    expect(find.text('Kembali ke game'), findsOneWidget);
    await tester.tap(find.text('Kembali ke game'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture Game'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final body in ['{}', '[]', 'not json']) {
    testWidgets('invalid payload $body recovers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Home(client: MockClient((_) async => http.Response(body, 200))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat game'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('HTTP error retries successfully', (tester) async {
    var calls = 0;
    final client = MockClient(
      (_) async =>
          ++calls == 1 ? http.Response('', 503) : http.Response(fixture, 200),
    );
    await tester.pumpWidget(MaterialApp(home: Home(client: client)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Fixture Game'), findsOneWidget);
  });
  testWidgets('timeout and disposed completion safe', (tester) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      MaterialApp(
        home: Home(
          client: MockClient((_) => response.future),
          requestTimeout: const Duration(milliseconds: 20),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 21));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat game'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    response.complete(http.Response(fixture, 200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('completion after disposal safe', (tester) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      MaterialApp(home: Home(client: MockClient((_) => response.future))),
    );
    await tester.pumpWidget(const SizedBox());
    response.complete(http.Response(fixture, 200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('invalid detail arguments show recovery', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Tujuan()));
    expect(tester.takeException(), isNull);
    expect(find.text('Data game tidak valid'), findsOneWidget);
  });
}
