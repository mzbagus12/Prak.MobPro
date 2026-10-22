import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas/main.dart';
double ratio(Color a,Color b) { final x=a.computeLuminance(),y=b.computeLuminance(); return (x>y?x+0.05:y+0.05)/(x>y?y+0.05:x+0.05); }
void main() { testWidgets('approved control names preserve actions', (tester) async { final semantics=tester.ensureSemantics(); await tester.pumpWidget(const MyApp()); await tester.pump(); expect(find.bySemanticsLabel('Tambah hitungan'), findsOneWidget); expect(find.byTooltip('Reset hitungan'), findsOneWidget); await tester.tap(find.bySemanticsLabel('Tambah hitungan')); await tester.pump(); expect(find.text('1'), findsWidgets); await tester.tap(find.byTooltip('Reset hitungan')); await tester.pump(); expect(find.text('0'), findsWidgets);  semantics.dispose(); }); }
