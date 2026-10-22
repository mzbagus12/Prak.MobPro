import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('search filters synthetic game list', (tester) async {
    final fixture = jsonEncode([
      {
        'id': 1,
        'title': 'Synthetic Alpha',
        'thumbnail': '',
        'short_description': 'Synthetic summary',
        'game_url': '',
        'genre': 'RPG',
        'platform': 'PC',
        'publisher': '',
        'developer': '',
        'release_date': '',
        'freetogame_profile_url': '',
      },
    ]);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no-match');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsNothing);
      expect(find.text('Game tidak ditemukan.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response(fixture, 200)));
  });
}
