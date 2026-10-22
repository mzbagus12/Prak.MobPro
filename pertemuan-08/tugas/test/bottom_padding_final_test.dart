import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail reserves bottom space inside scroll content', () {
    expect(File('lib/tujuan.dart').readAsStringSync(), contains('padding: const EdgeInsets.only(bottom: 12)'));
  });
}
