import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/view/home.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
void main() { testWidgets('search hint alpha-composited contrast at least 4.5', (tester) async {
 await http.runWithClient(() async {
 await tester.pumpWidget(const MaterialApp(home: Home())); await tester.pumpAndSettle();
 final d=tester.widget<TextField>(find.byType(TextField)).decoration!;
 final fg=Color.alphaBlend(d.hintStyle!.color!,d.fillColor!);
 final a=fg.computeLuminance(), b=d.fillColor!.computeLuminance();
 expect((b+0.05)/(a+0.05),greaterThanOrEqualTo(4.5));
 },()=>MockClient((_) async=>http.Response('[]',200)));
}); }
