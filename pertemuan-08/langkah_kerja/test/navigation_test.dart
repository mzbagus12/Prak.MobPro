import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_navigasi_namedroute/main.dart';
import 'package:demo_navigasi_namedroute/tujuan.dart';

void main() {
  testWidgets('named route carries data and back returns home', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Ke Halaman Tujuan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul Game'), findsOneWidget);
    expect(find.text('Genre: Action'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Home'));
    await tester.pumpAndSettle();
    expect(find.text('Ini halaman Home'), findsOneWidget);
  });
  testWidgets('invalid route data handled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Tujuan()));
    expect(tester.takeException(), isNull);
    expect(find.text('Data tidak valid'), findsOneWidget);
  });
}
