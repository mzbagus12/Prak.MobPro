import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/view/home.dart';
import 'package:game_app/viewmodel/fetchgame.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Synthetic fixtures only; not live API responses.
void main() {
  final fixture = jsonEncode([{'id':1,'title':'Synthetic Alpha','thumbnail':'','short_description':'Synthetic summary','game_url':'','genre':'RPG','platform':'PC','publisher':'','developer':'','release_date':'','freetogame_profile_url':''}]);
  test('fetch rejects HTTP and malformed JSON/list shape', () async {
    for (final reply in [http.Response('', 503), http.Response('bad-json', 200), http.Response('{}', 200), http.Response('[null]', 200)]) {
      await http.runWithClient(() async { await expectLater(fetchGames(), throwsException); }, () => MockClient((_) async => reply));
    }
  });
  testWidgets('cached request, local search, empty result, retry', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home())); await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget); expect(calls, 1);
      await tester.enterText(find.byType(TextField), 'alpha'); await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget); expect(calls, 1);
      await tester.enterText(find.byType(TextField), 'no-match'); await tester.pumpAndSettle();
      expect(find.text('Game tidak ditemukan.'), findsOneWidget); expect(calls, 1);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async {calls++; return http.Response(fixture, 200);}));
  });
  testWidgets('card opens actionable local summary', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home())); await tester.pumpAndSettle();
      await tester.tap(find.text('Synthetic Alpha')); await tester.pumpAndSettle();
      expect(find.text('Synthetic summary'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    }, () => MockClient((_) async => http.Response(fixture, 200)));
  });
  testWidgets('empty data has explicit retry', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home())); await tester.pumpAndSettle();
      expect(find.text('Tidak ada data game.'), findsOneWidget);
      await tester.tap(find.text('Coba lagi')); await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget); expect(calls, 2);
    }, () => MockClient((_) async => http.Response(++calls == 1 ? '[]' : fixture, 200)));
  });
}
