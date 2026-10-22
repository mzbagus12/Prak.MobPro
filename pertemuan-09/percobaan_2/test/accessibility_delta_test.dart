import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:percobaan_2/main.dart';
double ratio(Color a,Color b) { final x=a.computeLuminance(),y=b.computeLuminance(); return (x>y?x+0.05:y+0.05)/(x>y?y+0.05:x+0.05); }
void main() { testWidgets('approved control names preserve actions', (tester) async { final semantics=tester.ensureSemantics(); await tester.pumpWidget(const MyApp()); await tester.pump(); expect(find.byTooltip('Sukai'), findsOneWidget); await tester.tap(find.byTooltip('Sukai')); await tester.pump(); expect(find.byTooltip('Batal sukai'), findsOneWidget); expect(find.text('11 likes'), findsOneWidget);  semantics.dispose(); }); }
