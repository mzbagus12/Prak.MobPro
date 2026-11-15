import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokasi_flutter/main.dart';

void main() {
  testWidgets(
    'menampilkan awal, loading, hasil, dan kegagalan saat mencoba lagi',
    (tester) async {
      tester.view.physicalSize = const Size(390, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() async {
        final font = FontLoader('Poppins')
          ..addFont(
            File('assets/fonts/Poppins-Regular.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        await font.load();
      });

      final first = Completer<LocationResult>();
      final second = Completer<LocationResult>();
      var attempts = 0;
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MyApp(
            textTheme: ThemeData(fontFamily: 'Poppins').textTheme,
            loadLocation: () => (++attempts == 1 ? first : second).future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byType(ElevatedButton);

      expect(
        find.text('Tekan tombol untuk menampilkan lokasi.'),
        findsOneWidget,
      );
      await capture(tester, boundary, '01-awal');

      await tester.tap(button);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, boundary, '02-memuat');

      first.complete((
        latitude: -7.950900,
        longitude: 112.607500,
        kecamatan: 'Lowokwaru',
        kota: 'Kota Malang',
      ));
      await tester.pumpAndSettle();
      expect(find.text('Kelurahan/Kecamatan: Lowokwaru'), findsOneWidget);
      expect(find.text('Kota: Kota Malang'), findsOneWidget);
      expect(find.text('Latitude: -7.950900'), findsOneWidget);
      await capture(tester, boundary, '03-berhasil');

      await tester.tap(button);
      await tester.pump();
      expect(find.text('Kota: Kota Malang'), findsNothing);
      second.completeError(
        const LocationFailure(
          'Layanan lokasi tidak aktif. Aktifkan GPS, lalu coba lagi.',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Layanan lokasi tidak aktif. Aktifkan GPS, lalu coba lagi.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      await capture(tester, boundary, '04-error');
    },
  );
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  const directory = String.fromEnvironment('SCREENSHOT_DIR');
  if (directory.isEmpty) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await File('$directory/$name.png').writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}
