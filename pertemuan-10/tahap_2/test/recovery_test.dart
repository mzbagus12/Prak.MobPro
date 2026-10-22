import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/main.dart';
import 'package:game_app/model/detailgame.dart';
import 'package:game_app/view/detail.dart';
import 'package:game_app/view/home.dart';
import 'package:game_app/viewmodel/fetchgame.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readmore/readmore.dart';

// All fixtures in this file are synthetic, not live API responses.
Map<String, dynamic> fixture({int shots = 0}) => {
  'id': 1, 'title': 'Synthetic Alpha', 'thumbnail': '', 'status': 'Live',
  'short_description': 'Synthetic summary',
  'description': List.filled(100, 'Synthetic long description.').join(' '),
  'game_url': '', 'genre': 'RPG', 'platform': 'PC', 'publisher': '',
  'developer': '', 'release_date': '', 'freetogame_profile_url': '',
  'screenshots': List.generate(shots, (i) => {'id': i, 'image': ''}),
};

void main() {
  test('list parses synthetic data and empty list', () async {
    await http.runWithClient(() async {
      expect((await fetchGames()).single.title, 'Synthetic Alpha');
    }, () => MockClient((_) async => http.Response(jsonEncode([fixture()]), 200)));
    await http.runWithClient(() async { expect(await fetchGames(), isEmpty); },
      () => MockClient((_) async => http.Response('[]', 200)));
  });
  for (final body in ['invalid-json', '{}', '[null]']) {
    test('list rejects malformed shape $body', () async {
      await http.runWithClient(() async { await expectLater(fetchGames(), throwsFormatException); },
        () => MockClient((_) async => http.Response(body, 200)));
    });
  }
  test('HTTP status and transport errors surface', () async {
    await http.runWithClient(() async { await expectLater(fetchGames(), throwsException); },
      () => MockClient((_) async => http.Response('failure', 503)));
    await http.runWithClient(() async { await expectLater(fetchGames(), throwsA(isA<http.ClientException>())); },
      () => MockClient((_) async => throw http.ClientException('Synthetic network failure')));
  });
  test('list timeout is bounded', () async {
    await http.runWithClient(() async {
      await expectLater(fetchGames(timeout: const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    }, () => MockClient((_) => Completer<http.Response>().future));
  });
  test('detail status malformed shape timeout invalid ID', () async {
    for (final body in ['null', '[]', 'invalid-json']) {
      await http.runWithClient(() async { await expectLater(fetchDataFromAPI(1), throwsException); },
        () => MockClient((_) async => http.Response(body, 200)));
    }
    await http.runWithClient(() async { await expectLater(fetchDataFromAPI(1), throwsException); },
      () => MockClient((_) async => http.Response('', 500)));
    await http.runWithClient(() async {
      await expectLater(fetchDataFromAPI(1, timeout: const Duration(milliseconds: 1)), throwsA(isA<TimeoutException>()));
    }, () => MockClient((_) => Completer<http.Response>().future));
    await expectLater(fetchDataFromAPI(0), throwsFormatException);
  });
  test('JSON optional requirements screenshots and round trip', () {
    for (final shots in [0, 1, 2]) {
      final data = DetailGame.fromJson(fixture(shots: shots));
      expect(data.minimumSystemRequirements, isNull);
      expect(data.screenshots.length, shots);
      final copy = DetailGame.fromJson(jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
      expect(copy.id, 1);
      expect(copy.screenshots.length, shots);
    }
    final json = fixture()..remove('screenshots');
    expect(DetailGame.fromJson(json).screenshots, isEmpty);
    json['minimum_system_requirements'] = <String, dynamic>{};
    expect(DetailGame.fromJson(json).minimumSystemRequirements!.os, 'Tidak tersedia');
  });
  testWidgets('one request survives rebuild and local search result empty', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Home()));
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.pumpWidget(const MaterialApp(home: Home()));
      await tester.enterText(find.byType(TextField), 'ALPHA');
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no-match');
      await tester.pumpAndSettle();
      expect(find.text('Game tidak ditemukan.'), findsOneWidget);
      expect(find.text('Synthetic Alpha'), findsNothing);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async {calls++; return http.Response(jsonEncode([fixture()]), 200);}));
  });
  for (final first in ['[]', 'invalid-json']) {
    testWidgets('Home retry after $first', (tester) async {
      var calls = 0;
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: Home()));
        await tester.pumpAndSettle();
        expect(find.text('Coba lagi'), findsOneWidget);
        await tester.tap(find.text('Coba lagi')); await tester.pumpAndSettle();
        expect(find.text('Synthetic Alpha'), findsOneWidget); expect(calls, 2);
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async => http.Response(++calls == 1 ? first : jsonEncode([fixture()]), 200)));
    });
  }
  for (final size in [const Size(360, 800), const Size(800, 600)]) {
    for (final shots in [0, 1, 2]) {
      testWidgets('detail scroll ReadMore optional shots=$shots viewport=$size no refetch', (tester) async {
        tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        var calls = 0;
        await http.runWithClient(() async {
          await tester.pumpWidget(const MaterialApp(home: Detail(gameTerpilih: 1)));
          await tester.pumpAndSettle();
          expect(find.text('Synthetic Alpha'), findsOneWidget);
          expect(find.text('Tidak tersedia'), findsOneWidget);
          expect(find.byType(Image), findsNWidgets(shots + 1));
          await tester.ensureVisible(find.byType(ReadMoreText)); await tester.pumpAndSettle();
          expect(find.byType(ReadMoreText), findsOneWidget);
          await tester.drag(find.byKey(const Key('detail-scroll')), const Offset(0, -500));
          await tester.pumpAndSettle();
          await tester.drag(find.byKey(const Key('detail-scroll')), const Offset(0, 500));
          await tester.pumpAndSettle();
          await tester.drag(find.byKey(const Key('detail-scroll')), const Offset(0, -500));
          await tester.pumpAndSettle();
          expect(calls, 1); expect(tester.takeException(), isNull);
        }, () => MockClient((request) async {calls++; expect(request.url.queryParameters['id'], '1'); return http.Response(jsonEncode(fixture(shots: shots)), 200);}));
      });
    }
  }
  testWidgets('named ID detail and back preserve Home request', (tester) async {
    var listCalls = 0; var detailCalls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MyApp()); await tester.pumpAndSettle();
      await tester.tap(find.text('Synthetic Alpha')); await tester.pumpAndSettle();
      expect(find.byType(Detail), findsOneWidget);
      expect(detailCalls, 1);
      await tester.pageBack(); await tester.pumpAndSettle();
      expect(find.byType(Home), findsOneWidget); expect(listCalls, 1);
    }, () => MockClient((request) async {
      if (request.url.path.endsWith('/games')) { listCalls++; return http.Response(jsonEncode([fixture()]), 200); }
      detailCalls++; expect(request.url.queryParameters['id'], '1'); return http.Response(jsonEncode(fixture()), 200);
    }));
  });
  testWidgets('invalid route argument does not fetch detail', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MyApp()); await tester.pumpAndSettle();
      final context = tester.element(find.byType(Home));
      unawaited(Navigator.of(context).pushNamed('/detail', arguments: 'wrong-type'));
      await tester.pumpAndSettle();
      expect(find.text('ID game tidak valid'), findsOneWidget); expect(calls, 1);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async {calls++; return http.Response('[]', 200);}));
  });
  testWidgets('detail retry recovers HTTP error', (tester) async {
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Detail(gameTerpilih: 1))); await tester.pumpAndSettle();
      expect(find.text('Gagal memuat detail game'), findsOneWidget);
      await tester.tap(find.text('Coba lagi')); await tester.pumpAndSettle();
      expect(find.text('Synthetic Alpha'), findsOneWidget); expect(calls, 2);
    }, () => MockClient((_) async => ++calls == 1 ? http.Response('', 500) : http.Response(jsonEncode(fixture()), 200)));
  });
}
