import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_crud_api/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('CRUD, validasi, pembatalan, dan respons gagal', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = FontLoader('MontserratDemo')
        ..addFont(
          File('assets/fonts/Montserrat-SemiBold.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final boundary = GlobalKey();
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE') return http.Response('{}', 200);
      final data = request.method == 'GET'
          ? {'title': 'Post contoh', 'body': 'Data dari API uji', 'userId': 1}
          : jsonDecode(request.body) as Map<String, dynamic>;
      if (data['title'] == 'Gagal') return http.Response('{}', 500);
      return http.Response(
        jsonEncode({...data, 'id': request.method == 'POST' ? 101 : 1}),
        request.method == 'POST' ? 201 : 200,
      );
    });
    addTearDown(client.close);

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MyApp(client: client, fontFamily: 'MontserratDemo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum ada post'), findsOneWidget);
    await capture(tester, boundary, '01-awal');

    await tester.tap(find.text('Baca contoh'));
    await tester.pumpAndSettle();
    expect(find.text('Post contoh'), findsOneWidget);

    await tester.tap(find.text('Tambah post'));
    await tester.pumpAndSettle();
    await capture(tester, boundary, '02-dialog-tambah');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(requests, hasLength(1));
    await tester.enterText(find.byType(TextFormField).at(0), 'Nadia Pratama');
    await tester.enterText(find.byType(TextFormField).at(1), 'Desainer produk');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nadia Pratama'), findsOneWidget);
    expect(find.text('Post berhasil ditambahkan.'), findsOneWidget);
    await capture(tester, boundary, '03-card-dan-sukses');

    await tester.tap(find.byTooltip('Opsi post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Nadia Pratama'), findsOneWidget);
    await capture(tester, boundary, '04-dialog-update');
    await tester.enterText(find.byType(TextFormField).at(1), 'Analis produk');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Analis produk'), findsOneWidget);

    await tester.tap(find.byTooltip('Opsi post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await capture(tester, boundary, '05-konfirmasi-hapus');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(3));
    expect(find.text('Analis produk'), findsOneWidget);

    await tester.tap(find.byTooltip('Opsi post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada post'), findsOneWidget);
    expect(find.text('Post berhasil dihapus.'), findsOneWidget);
    await capture(tester, boundary, '06-hapus-berhasil');

    await tester.tap(find.text('Tambah post'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Gagal');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Uji respons HTTP',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Permintaan gagal (HTTP 500).'), findsOneWidget);
    expect(find.text('Belum ada post'), findsOneWidget);
    await capture(tester, boundary, '07-gagal');

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /posts/1',
      'POST /posts',
      'PUT /posts/1',
      'DELETE /posts/1',
      'POST /posts',
    ]);
    expect(jsonDecode(requests[1].body), {
      'title': 'Nadia Pratama',
      'body': 'Desainer produk',
      'userId': 1,
    });
    expect(jsonDecode(requests[2].body)['body'], 'Analis produk');
  });
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
