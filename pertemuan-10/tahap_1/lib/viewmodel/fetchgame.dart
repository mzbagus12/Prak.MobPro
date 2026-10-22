import 'dart:convert';

import 'package:game_app/model/game.dart';
import 'package:http/http.dart' as http;

Future<List<Game>> fetchGames({Duration timeout = const Duration(seconds: 15)}) async {
  final response = await http.get(
    Uri.parse('https://www.freetogame.com/api/games'),
  ).timeout(timeout);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    if (jsonData is! List) throw const FormatException('Daftar game tidak valid');
    return jsonData.map((item) {
      if (item is! Map<String, dynamic>) throw const FormatException('Game tidak valid');
      return Game.fromJson(item);
    }).toList();
  } else {
    throw Exception('Gagal mengambil data game');
  }
}