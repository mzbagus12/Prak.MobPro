import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/view/home.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // Synthetic fixture, not a live API response.
  final body = jsonEncode([{'id': 1, 'title': 'Synthetic Alpha', 'thumbnail': '', 'short_description': 'Synthetic summary', 'game_url': '', 'genre': 'RPG', 'platform': 'PC', 'publisher': '', 'developer': '', 'release_date': '', 'freetogame_profile_url': ''}]);
  testWidgets('baseline one request per Home mount', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home()));
      await tester.pumpAndSettle();
      expect(calls, 1);
    }, () => MockClient((_) async {calls++; return http.Response(body, 200);}));
  });
  testWidgets('baseline search filters local data', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'no-match');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsNothing);
    }, () => MockClient((_) async => http.Response(body, 200)));
  });
}
