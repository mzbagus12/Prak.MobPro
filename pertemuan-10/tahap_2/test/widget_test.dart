import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/model/detailgame.dart';

void main() {
  test('detail model round-trips JSON with optional fields missing', () {
    final input = <String, dynamic>{
      'id': 475,
      'title': 'Synthetic Game',
      'thumbnail': '',
      'status': 'Live',
      'short_description': 'Synthetic summary',
      'description': 'Synthetic details',
      'game_url': '',
      'genre': 'RPG',
      'platform': 'PC',
      'publisher': 'Synthetic',
      'developer': 'Synthetic',
      'release_date': '2026-01-01',
      'freetogame_profile_url': '',
    };

    final detail = DetailGame.fromJson(input);
    expect(detail.id, 475);
    expect(detail.title, 'Synthetic Game');
    expect(detail.minimumSystemRequirements, isNull);
    expect(detail.screenshots, isEmpty);

    final roundTrip = DetailGame.fromJson(
      jsonDecode(jsonEncode(detail.toJson())) as Map<String, dynamic>,
    );
    expect(roundTrip.shortDescription, 'Synthetic summary');
    expect(roundTrip.screenshots, isEmpty);
  });
}
