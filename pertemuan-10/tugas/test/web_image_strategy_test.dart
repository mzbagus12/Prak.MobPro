import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all network images prefer native HTML rendering', () {
    final sources = Directory('lib/view').listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
    var images = 0;
    for (final file in sources) {
      final source = file.readAsStringSync();
      final count = 'Image.network('.allMatches(source).length;
      images += count;
      expect('webHtmlElementStrategy: WebHtmlElementStrategy.prefer'.allMatches(source).length, count, reason: file.path);
    }
    expect(images, greaterThan(0));
  });
}
